import Foundation

/// Data point for ring buffer
private struct DataPoint {
    let timestamp: Date
    let hr: Double
    let rrIntervalsMs: [Double]
    let motion: [String: Double]?
}

/// Main emotion inference engine.
///
/// Processes biosignal data using a sliding window approach and produces
/// emotion predictions at configurable intervals.
public class EmotionEngine {
    /// Expected number of core HRV features (hr_mean, sdnn, rmssd)
    public static let expectedFeatureCount = 3

    /// Engine configuration
    public let config: EmotionConfig

    /// Linear SVM model for inference
    private let model: LinearSvmModel

    /// Ring buffer for sliding window
    private var buffer: [DataPoint] = []

    /// Last emission timestamp
    private var lastEmission: Date?

    /// Logging callback
    public var onLog: ((String, String, [String: Any]?) -> Void)?

    /// Thread-safe queue for buffer operations
    private let queue = DispatchQueue(label: "com.synheart.emotion.engine", attributes: .concurrent)

    /// Private initializer
    private init(
        config: EmotionConfig,
        model: LinearSvmModel,
        onLog: ((String, String, [String: Any]?) -> Void)? = nil
    ) {
        self.config = config
        self.model = model
        self.onLog = onLog
    }

    /// Create engine from pretrained model
    public static func fromPretrained(
        config: EmotionConfig,
        model: LinearSvmModel? = nil,
        onLog: ((String, String, [String: Any]?) -> Void)? = nil
    ) throws -> EmotionEngine {
        let svmModel = model ?? LinearSvmModel.createDefault()

        // Validate model compatibility
        let hasRequiredFeatures = svmModel.featureNames.count == expectedFeatureCount &&
                                 svmModel.featureNames.contains("hr_mean") &&
                                 svmModel.featureNames.contains("sdnn") &&
                                 svmModel.featureNames.contains("rmssd")

        guard hasRequiredFeatures else {
            throw EmotionError.modelIncompatible(
                expectedFeats: expectedFeatureCount,
                actualFeats: svmModel.featureNames.count
            )
        }

        return EmotionEngine(
            config: config,
            model: svmModel,
            onLog: onLog
        )
    }

    /// Push new data point into the engine
    public func push(
        hr: Double,
        rrIntervalsMs: [Double],
        timestamp: Date,
        motion: [String: Double]? = nil
    ) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            do {
                // Validate input using physiological constants
                if hr < FeatureExtractor.minValidHr || hr > FeatureExtractor.maxValidHr {
                    self.log(
                        level: "warn",
                        message: "Invalid HR value: \(hr) (valid range: \(FeatureExtractor.minValidHr)-\(FeatureExtractor.maxValidHr) BPM)"
                    )
                    return
                }

                if rrIntervalsMs.isEmpty {
                    self.log(level: "warn", message: "Empty RR intervals")
                    return
                }

                // Add to ring buffer
                let dataPoint = DataPoint(
                    timestamp: timestamp,
                    hr: hr,
                    rrIntervalsMs: rrIntervalsMs,
                    motion: motion
                )

                self.buffer.append(dataPoint)

                // Remove old data points outside window
                self.trimBuffer()

                self.log(level: "debug", message: "Pushed data point: HR=\(hr), RR count=\(rrIntervalsMs.count)")

            } catch {
                self.log(level: "error", message: "Error pushing data point: \(error)")
            }
        }
    }

    /// Consume ready results (throttled by step interval)
    public func consumeReady() -> [EmotionResult] {
        var results: [EmotionResult] = []

        queue.sync {
            do {
                // Check if enough time has passed since last emission
                let now = Date()
                if let last = lastEmission, now.timeIntervalSince(last) < config.step {
                    return // Not ready yet
                }

                // Check if we have enough data
                guard buffer.count >= 2 else {
                    return // Not enough data
                }

                // Extract features from current window
                guard let features = extractWindowFeatures() else {
                    return // Feature extraction failed
                }

                // Run inference
                let probabilities = try model.predict(features)

                // Create result
                let result = EmotionResult.fromInference(
                    timestamp: now,
                    probabilities: probabilities,
                    features: features,
                    model: model.getMetadata()
                )

                results.append(result)
                lastEmission = now

                log(level: "info", message: "Emitted result: \(result.emotion) (\(String(format: "%.1f", result.confidence * 100))%)")

            } catch {
                log(level: "error", message: "Error during inference: \(error)")
            }
        }

        return results
    }

    /// Extract features from current window
    private func extractWindowFeatures() -> [String: Double]? {
        guard !buffer.isEmpty else { return nil }

        // Collect all HR values and RR intervals in window
        var hrValues: [Double] = []
        var allRrIntervals: [Double] = []
        var motionAggregate: [String: Double] = [:]

        for point in buffer {
            hrValues.append(point.hr)
            allRrIntervals.append(contentsOf: point.rrIntervalsMs)

            // Aggregate motion data
            if let motion = point.motion {
                for (key, value) in motion {
                    motionAggregate[key] = (motionAggregate[key] ?? 0.0) + value
                }
            }
        }

        // Check minimum RR count
        guard allRrIntervals.count >= config.minRrCount else {
            log(level: "warn", message: "Too few RR intervals: \(allRrIntervals.count) < \(config.minRrCount)")
            return nil
        }

        // Extract features
        var features = FeatureExtractor.extractFeatures(
            hrValues: hrValues,
            rrIntervalsMs: allRrIntervals,
            motion: motionAggregate.isEmpty ? nil : motionAggregate
        )

        // Apply personalization if configured
        if let baseline = config.hrBaseline {
            features["hr_mean"] = features["hr_mean"]! - baseline
        }

        return features
    }

    /// Trim buffer to keep only data within window
    private func trimBuffer() {
        guard !buffer.isEmpty else { return }

        let cutoffTime = Date(timeIntervalSinceNow: -config.window)

        // Remove expired data points
        buffer.removeAll { $0.timestamp < cutoffTime }
    }

    /// Get current buffer statistics
    public func getBufferStats() -> [String: Any] {
        return queue.sync {
            guard !buffer.isEmpty else {
                return [
                    "count": 0,
                    "duration_ms": 0,
                    "hr_range": [0.0, 0.0],
                    "rr_count": 0
                ]
            }

            let hrValues = buffer.map { $0.hr }
            let rrCount = buffer.reduce(0) { $0 + $1.rrIntervalsMs.count }
            let duration = buffer.last!.timestamp.timeIntervalSince(buffer.first!.timestamp) * 1000

            return [
                "count": buffer.count,
                "duration_ms": Int(duration),
                "hr_range": [hrValues.min() ?? 0.0, hrValues.max() ?? 0.0],
                "rr_count": rrCount
            ]
        }
    }

    /// Clear all buffered data
    public func clear() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.buffer.removeAll()
            self.lastEmission = nil
            self.log(level: "info", message: "Buffer cleared")
        }
    }

    /// Log message with optional context
    private func log(level: String, message: String, context: [String: Any]? = nil) {
        onLog?(level, message, context)
    }
}
