package com.synheart.emotion

/**
 * Errors that can occur during emotion inference.
 */
sealed class EmotionError(message: String, val context: Map<String, Any>? = null) : Exception(message) {

    /**
     * Too few RR intervals for stable inference.
     */
    class TooFewRR(minExpected: Int, actual: Int) : EmotionError(
        "Too few RR intervals: expected at least $minExpected, got $actual",
        mapOf("minExpected" to minExpected, "actual" to actual)
    )

    /**
     * Invalid input data.
     */
    class BadInput(reason: String) : EmotionError("Bad input: $reason")

    /**
     * Model incompatible with feature dimensions.
     */
    class ModelIncompatible(expectedFeats: Int, actualFeats: Int) : EmotionError(
        "Model incompatible: expected $expectedFeats features, got $actualFeats",
        mapOf("expectedFeats" to expectedFeats, "actualFeats" to actualFeats)
    )

    /**
     * Feature extraction failed.
     */
    class FeatureExtractionFailed(reason: String) : EmotionError("Feature extraction failed: $reason")
}
