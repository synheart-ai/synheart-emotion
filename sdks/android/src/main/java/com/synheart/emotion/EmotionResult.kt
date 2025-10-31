package com.synheart.emotion

import java.util.Date

/**
 * Result of emotion inference containing probabilities and metadata.
 *
 * @property timestamp Timestamp when inference was performed
 * @property emotion Predicted emotion label (top-1)
 * @property confidence Confidence score (top-1 probability)
 * @property probabilities All label probabilities
 * @property features Extracted features used for inference
 * @property model Model metadata
 */
data class EmotionResult(
    val timestamp: Date,
    val emotion: String,
    val confidence: Double,
    val probabilities: Map<String, Double>,
    val features: Map<String, Double>,
    val model: Map<String, Any>
) {
    companion object {
        /**
         * Create EmotionResult from raw inference data.
         */
        fun fromInference(
            timestamp: Date,
            probabilities: Map<String, Double>,
            features: Map<String, Double>,
            model: Map<String, Any>
        ): EmotionResult {
            // Find top-1 emotion
            val (topEmotion, topConfidence) = probabilities.maxByOrNull { it.value }
                ?.let { it.key to it.value }
                ?: ("" to 0.0)

            return EmotionResult(
                timestamp = timestamp,
                emotion = topEmotion,
                confidence = topConfidence,
                probabilities = probabilities,
                features = features,
                model = model
            )
        }
    }

    override fun toString(): String {
        val confidencePercent = (confidence * 100).let { "%.1f".format(it) }
        val featureNames = features.keys.joinToString(", ")
        return "EmotionResult($emotion: $confidencePercent%, features: $featureNames)"
    }
}
