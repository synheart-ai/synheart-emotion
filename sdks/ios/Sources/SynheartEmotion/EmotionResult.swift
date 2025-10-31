import Foundation

/// Result of emotion inference containing probabilities and metadata.
public struct EmotionResult {
    /// Timestamp when inference was performed
    public let timestamp: Date

    /// Predicted emotion label (top-1)
    public let emotion: String

    /// Confidence score (top-1 probability)
    public let confidence: Double

    /// All label probabilities
    public let probabilities: [String: Double]

    /// Extracted features used for inference
    public let features: [String: Double]

    /// Model metadata
    public let model: [String: Any]

    /// Initialize emotion result
    public init(
        timestamp: Date,
        emotion: String,
        confidence: Double,
        probabilities: [String: Double],
        features: [String: Double],
        model: [String: Any]
    ) {
        self.timestamp = timestamp
        self.emotion = emotion
        self.confidence = confidence
        self.probabilities = probabilities
        self.features = features
        self.model = model
    }

    /// Create EmotionResult from raw inference data
    public static func fromInference(
        timestamp: Date,
        probabilities: [String: Double],
        features: [String: Double],
        model: [String: Any]
    ) -> EmotionResult {
        // Find top-1 emotion
        let (topEmotion, topConfidence) = probabilities.max { $0.value < $1.value }
            .map { ($0.key, $0.value) } ?? ("", 0.0)

        return EmotionResult(
            timestamp: timestamp,
            emotion: topEmotion,
            confidence: topConfidence,
            probabilities: probabilities,
            features: features,
            model: model
        )
    }
}

extension EmotionResult: CustomStringConvertible {
    public var description: String {
        let confidencePercent = String(format: "%.1f", confidence * 100)
        let featureNames = features.keys.joined(separator: ", ")
        return "EmotionResult(\(emotion): \(confidencePercent)%, features: \(featureNames))"
    }
}

extension EmotionResult: Equatable {
    public static func == (lhs: EmotionResult, rhs: EmotionResult) -> Bool {
        return lhs.timestamp == rhs.timestamp &&
               lhs.emotion == rhs.emotion &&
               lhs.confidence == rhs.confidence &&
               lhs.probabilities == rhs.probabilities &&
               lhs.features == rhs.features
    }
}
