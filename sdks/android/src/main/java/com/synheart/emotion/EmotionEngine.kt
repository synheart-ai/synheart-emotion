package com.synheart.emotion

import java.util.*
import java.util.concurrent.ConcurrentLinkedQueue

/**
 * Data point for ring buffer.
 */
private data class DataPoint(
    val timestamp: Date,
    val hr: Double,
    val rrIntervalsMs: List<Double>,
    val motion: Map<String, Double>? = null
)

/**
 * Main emotion inference engine.
 *
 * Processes biosignal data using a sliding window approach and produces
 * emotion predictions at configurable intervals.
 *
 * @property config Engine configuration
 * @property model Linear SVM model for inference
 * @property onLog Optional logging callback
 */
class EmotionEngine private constructor(
    val config: EmotionConfig,
    private val model: LinearSvmModel,
    private val onLog: ((level: String, message: String, context: Map<String, Any>?) -> Unit)? = null
) {
    /** Ring buffer for sliding window */
    private val buffer = ConcurrentLinkedQueue<DataPoint>()

    /** Last emission timestamp */
    private var lastEmission: Date? = null

    /**
     * Push new data point into the engine.
     *
     * @param hr Heart rate in BPM
     * @param rrIntervalsMs RR intervals in milliseconds
     * @param timestamp Timestamp of the data point
     * @param motion Optional motion data
     */
    fun push(
        hr: Double,
        rrIntervalsMs: List<Double>,
        timestamp: Date,
        motion: Map<String, Double>? = null
    ) {
        try {
            // Validate input using physiological constants
            if (hr < FeatureExtractor.MIN_VALID_HR || hr > FeatureExtractor.MAX_VALID_HR) {
                log(
                    "warn",
                    "Invalid HR value: $hr (valid range: ${FeatureExtractor.MIN_VALID_HR}-${FeatureExtractor.MAX_VALID_HR} BPM)"
                )
                return
            }

            if (rrIntervalsMs.isEmpty()) {
                log("warn", "Empty RR intervals")
                return
            }

            // Add to ring buffer
            val dataPoint = DataPoint(
                timestamp = timestamp,
                hr = hr,
                rrIntervalsMs = rrIntervalsMs.toList(),
                motion = motion
            )

            buffer.add(dataPoint)

            // Remove old data points outside window
            trimBuffer()

            log("debug", "Pushed data point: HR=$hr, RR count=${rrIntervalsMs.size}")

        } catch (e: Exception) {
            log("error", "Error pushing data point: ${e.message}")
        }
    }

    /**
     * Consume ready results (throttled by step interval).
     *
     * @return List of emotion results (empty if not ready)
     */
    fun consumeReady(): List<EmotionResult> {
        val results = mutableListOf<EmotionResult>()

        try {
            // Check if enough time has passed since last emission
            val now = Date()
            lastEmission?.let { last ->
                if (now.time - last.time < config.stepMs) {
                    return results // Not ready yet
                }
            }

            // Check if we have enough data
            if (buffer.size < 2) {
                return results // Not enough data
            }

            // Extract features from current window
            val features = extractWindowFeatures() ?: return results

            // Run inference
            val probabilities = model.predict(features)

            // Create result
            val result = EmotionResult.fromInference(
                timestamp = now,
                probabilities = probabilities,
                features = features,
                model = model.getMetadata()
            )

            results.add(result)
            lastEmission = now

            log("info", "Emitted result: ${result.emotion} (${"%.1f".format(result.confidence * 100)}%)")

        } catch (e: Exception) {
            log("error", "Error during inference: ${e.message}")
        }

        return results
    }

    /**
     * Extract features from current window.
     */
    private fun extractWindowFeatures(): Map<String, Double>? {
        if (buffer.isEmpty()) return null

        // Collect all HR values and RR intervals in window
        val hrValues = mutableListOf<Double>()
        val allRrIntervals = mutableListOf<Double>()
        val motionAggregate = mutableMapOf<String, Double>()

        for (point in buffer) {
            hrValues.add(point.hr)
            allRrIntervals.addAll(point.rrIntervalsMs)

            // Aggregate motion data
            point.motion?.forEach { (key, value) ->
                motionAggregate[key] = (motionAggregate[key] ?: 0.0) + value
            }
        }

        // Check minimum RR count
        if (allRrIntervals.size < config.minRrCount) {
            log("warn", "Too few RR intervals: ${allRrIntervals.size} < ${config.minRrCount}")
            return null
        }

        // Extract features
        val features = FeatureExtractor.extractFeatures(
            hrValues = hrValues,
            rrIntervalsMs = allRrIntervals,
            motion = motionAggregate.takeIf { it.isNotEmpty() }
        ).toMutableMap()

        // Apply personalization if configured
        config.hrBaseline?.let { baseline ->
            features["hr_mean"] = features["hr_mean"]!! - baseline
        }

        return features
    }

    /**
     * Trim buffer to keep only data within window.
     */
    private fun trimBuffer() {
        if (buffer.isEmpty()) return

        val cutoffTime = Date(System.currentTimeMillis() - config.windowMs)

        // Remove expired data points
        while (buffer.isNotEmpty() && buffer.peek()?.timestamp?.before(cutoffTime) == true) {
            buffer.poll()
        }
    }

    /**
     * Get current buffer statistics.
     */
    fun getBufferStats(): Map<String, Any> {
        if (buffer.isEmpty()) {
            return mapOf(
                "count" to 0,
                "duration_ms" to 0L,
                "hr_range" to listOf(0.0, 0.0),
                "rr_count" to 0
            )
        }

        val hrValues = buffer.map { it.hr }
        val rrCount = buffer.sumOf { it.rrIntervalsMs.size }
        val duration = buffer.last().timestamp.time - buffer.first().timestamp.time

        return mapOf(
            "count" to buffer.size,
            "duration_ms" to duration,
            "hr_range" to listOf(hrValues.minOrNull() ?: 0.0, hrValues.maxOrNull() ?: 0.0),
            "rr_count" to rrCount
        )
    }

    /**
     * Clear all buffered data.
     */
    fun clear() {
        buffer.clear()
        lastEmission = null
        log("info", "Buffer cleared")
    }

    /**
     * Log message with optional context.
     */
    private fun log(level: String, message: String, context: Map<String, Any>? = null) {
        onLog?.invoke(level, message, context)
    }

    companion object {
        /** Expected number of core HRV features (hr_mean, sdnn, rmssd). */
        const val EXPECTED_FEATURE_COUNT = 3

        /**
         * Create engine from pretrained model.
         *
         * @param config Engine configuration
         * @param model Optional custom model (defaults to WESAD model)
         * @param onLog Optional logging callback
         */
        fun fromPretrained(
            config: EmotionConfig,
            model: LinearSvmModel? = null,
            onLog: ((level: String, message: String, context: Map<String, Any>?) -> Unit)? = null
        ): EmotionEngine {
            val svmModel = model ?: LinearSvmModel.createDefault()

            // Validate model compatibility
            if (svmModel.featureNames.size != EXPECTED_FEATURE_COUNT ||
                !svmModel.featureNames.contains("hr_mean") ||
                !svmModel.featureNames.contains("sdnn") ||
                !svmModel.featureNames.contains("rmssd")
            ) {
                throw EmotionError.ModelIncompatible(
                    expectedFeats = EXPECTED_FEATURE_COUNT,
                    actualFeats = svmModel.featureNames.size
                )
            }

            return EmotionEngine(
                config = config,
                model = svmModel,
                onLog = onLog
            )
        }
    }
}
