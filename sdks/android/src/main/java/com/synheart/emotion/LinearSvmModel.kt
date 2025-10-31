package com.synheart.emotion

import kotlin.math.exp
import kotlin.math.max

/**
 * Linear SVM model with weights embedded in code.
 *
 * This is the original embedded model format that stores weights
 * directly in code. For loading models from assets, use
 * [JsonLinearModel] instead.
 *
 * @property modelId Model identifier
 * @property version Model version
 * @property labels Supported emotion labels
 * @property featureNames Feature names in order
 * @property weights SVM weights matrix (C x F where C=classes, F=features)
 * @property biases SVM bias vector (C classes)
 * @property mu Feature normalization means
 * @property sigma Feature normalization standard deviations
 */
data class LinearSvmModel(
    val modelId: String,
    val version: String,
    val labels: List<String>,
    val featureNames: List<String>,
    val weights: List<List<Double>>,
    val biases: List<Double>,
    val mu: Map<String, Double>,
    val sigma: Map<String, Double>
) {
    init {
        // Validate dimensions
        require(weights.size == labels.size) {
            "Weights length (${weights.size}) must match labels length (${labels.size})"
        }
        require(biases.size == labels.size) {
            "Biases length (${biases.size}) must match labels length (${labels.size})"
        }
        if (weights.isNotEmpty()) {
            require(weights[0].size == featureNames.size) {
                "Weight feature dimension (${weights[0].size}) must match feature names length (${featureNames.size})"
            }
        }
    }

    /**
     * Predict emotion probabilities from features.
     */
    fun predict(features: Map<String, Double>): Map<String, Double> {
        // Validate input features
        if (!FeatureExtractor.validateFeatures(features, featureNames)) {
            throw EmotionError.BadInput("Invalid features: missing required features or NaN values")
        }

        // Normalize features
        val normalizedFeatures = FeatureExtractor.normalizeFeatures(features, mu, sigma)

        // Extract feature vector in correct order
        val featureVector = featureNames.map { featureName ->
            normalizedFeatures[featureName]
                ?: throw EmotionError.BadInput("Missing required feature: $featureName")
        }

        // Calculate SVM margins: W·x + b
        val margins = labels.indices.map { i ->
            var margin = biases[i]
            for (j in featureVector.indices) {
                margin += weights[i][j] * featureVector[j]
            }
            margin
        }

        // Apply softmax to get probabilities
        return softmax(margins)
    }

    /**
     * Apply softmax function to convert margins to probabilities.
     */
    private fun softmax(margins: List<Double>): Map<String, Double> {
        // Find maximum margin for numerical stability
        val maxMargin = margins.maxOrNull() ?: 0.0

        // Calculate exponentials
        val exponentials = margins.map { exp(it - maxMargin) }
        val sumExp = exponentials.sum()

        // Calculate probabilities
        return labels.indices.associate { i ->
            labels[i] to (exponentials[i] / sumExp)
        }
    }

    /**
     * Get model metadata.
     */
    fun getMetadata(): Map<String, Any> {
        return mapOf(
            "id" to modelId,
            "version" to version,
            "type" to "embedded",
            "labels" to labels,
            "feature_names" to featureNames,
            "num_classes" to labels.size,
            "num_features" to featureNames.size
        )
    }

    /**
     * Validate model integrity.
     */
    fun validate(): Boolean {
        return try {
            // Check dimensions
            if (weights.size != labels.size) return false
            if (biases.size != labels.size) return false
            if (weights.isNotEmpty() && weights[0].size != featureNames.size) return false

            // Check for NaN or infinite values
            for (weightRow in weights) {
                for (weight in weightRow) {
                    if (weight.isNaN() || weight.isInfinite()) return false
                }
            }

            for (bias in biases) {
                if (bias.isNaN() || bias.isInfinite()) return false
            }

            true
        } catch (e: Exception) {
            false
        }
    }

    companion object {
        /**
         * Create the default WESAD-trained emotion model.
         *
         * **⚠️ WARNING: This model uses placeholder weights for demonstration purposes only.**
         *
         * The weights in this model are NOT trained on real biosignal data and should
         * NOT be used in production or clinical settings.
         */
        fun createDefault(): LinearSvmModel {
            return LinearSvmModel(
                modelId = "wesad_emotion_v1_0",
                version = "1.0",
                labels = listOf("Amused", "Calm", "Stressed"),
                featureNames = listOf("hr_mean", "sdnn", "rmssd"),
                weights = listOf(
                    listOf(0.12, 0.5, 0.3),    // Amused: higher HR, higher HRV
                    listOf(-0.21, -0.4, -0.3), // Calm: lower HR, lower HRV
                    listOf(0.02, 0.2, 0.1)     // Stressed: slightly higher HR, moderate HRV
                ),
                biases = listOf(-0.2, 0.3, 0.1),
                mu = mapOf(
                    "hr_mean" to 72.5,
                    "sdnn" to 45.3,
                    "rmssd" to 32.1
                ),
                sigma = mapOf(
                    "hr_mean" to 12.0,
                    "sdnn" to 18.7,
                    "rmssd" to 12.4
                )
            )
        }
    }
}
