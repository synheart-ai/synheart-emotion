package com.synheart.emotion

import kotlin.math.pow
import kotlin.math.sqrt
import kotlin.math.abs

/**
 * Feature extraction utilities for emotion inference.
 *
 * Provides methods for extracting heart rate variability (HRV) metrics
 * from biosignal data, including HR mean, SDNN, and RMSSD.
 */
object FeatureExtractor {
    /** Minimum valid RR interval in milliseconds (300ms = 200 BPM). */
    const val MIN_VALID_RR_MS = 300.0

    /** Maximum valid RR interval in milliseconds (2000ms = 30 BPM). */
    const val MAX_VALID_RR_MS = 2000.0

    /**
     * Maximum allowed jump between successive RR intervals in milliseconds.
     *
     * This threshold helps detect and remove artifacts from RR interval data.
     * A jump > 250ms between consecutive intervals likely indicates noise.
     */
    const val MAX_RR_JUMP_MS = 250.0

    /** Minimum heart rate value considered valid (in BPM). */
    const val MIN_VALID_HR = 30.0

    /** Maximum heart rate value considered valid (in BPM). */
    const val MAX_VALID_HR = 300.0

    /**
     * Extract HR mean from a list of HR values.
     *
     * Returns 0.0 if the input list is empty.
     */
    fun extractHrMean(hrValues: List<Double>): Double {
        if (hrValues.isEmpty()) return 0.0
        return hrValues.sum() / hrValues.size
    }

    /**
     * Extract SDNN (standard deviation of NN intervals) from RR intervals.
     */
    fun extractSdnn(rrIntervalsMs: List<Double>): Double {
        if (rrIntervalsMs.size < 2) return 0.0

        // Clean RR intervals (remove outliers)
        val cleaned = cleanRrIntervals(rrIntervalsMs)
        if (cleaned.size < 2) return 0.0

        // Calculate standard deviation (sample std, N-1 denominator)
        val mean = cleaned.sum() / cleaned.size
        val variance = cleaned.sumOf { (it - mean).pow(2) } / (cleaned.size - 1)
        return sqrt(variance)
    }

    /**
     * Extract RMSSD (root mean square of successive differences) from RR intervals.
     */
    fun extractRmssd(rrIntervalsMs: List<Double>): Double {
        if (rrIntervalsMs.size < 2) return 0.0

        // Clean RR intervals
        val cleaned = cleanRrIntervals(rrIntervalsMs)
        if (cleaned.size < 2) return 0.0

        // Calculate successive differences
        var sumSquaredDiffs = 0.0
        for (i in 1 until cleaned.size) {
            val diff = cleaned[i] - cleaned[i - 1]
            sumSquaredDiffs += diff * diff
        }

        // Root mean square
        return sqrt(sumSquaredDiffs / (cleaned.size - 1))
    }

    /**
     * Extract all features for emotion inference.
     */
    fun extractFeatures(
        hrValues: List<Double>,
        rrIntervalsMs: List<Double>,
        motion: Map<String, Double>? = null
    ): Map<String, Double> {
        val features = mutableMapOf(
            "hr_mean" to extractHrMean(hrValues),
            "sdnn" to extractSdnn(rrIntervalsMs),
            "rmssd" to extractRmssd(rrIntervalsMs)
        )

        // Add motion features if provided
        motion?.let { features.putAll(it) }

        return features
    }

    /**
     * Clean RR intervals by removing physiologically invalid values and artifacts.
     *
     * Removes:
     * - RR intervals outside valid range ([MIN_VALID_RR_MS] to [MAX_VALID_RR_MS])
     * - Large jumps between successive intervals (> [MAX_RR_JUMP_MS])
     *
     * Returns filtered list of clean RR intervals.
     */
    fun cleanRrIntervals(rrIntervalsMs: List<Double>): List<Double> {
        if (rrIntervalsMs.isEmpty()) return emptyList()

        val cleaned = mutableListOf<Double>()
        var prevValue: Double? = null

        for (rr in rrIntervalsMs) {
            // Skip outliers outside physiological range
            if (rr < MIN_VALID_RR_MS || rr > MAX_VALID_RR_MS) continue

            // Skip large jumps that likely indicate artifacts
            prevValue?.let { prev ->
                if (abs(rr - prev) > MAX_RR_JUMP_MS) return@let
            }

            cleaned.add(rr)
            prevValue = rr
        }

        return cleaned
    }

    /**
     * Validate feature vector for model compatibility.
     */
    fun validateFeatures(features: Map<String, Double>, requiredFeatures: List<String>): Boolean {
        for (feature in requiredFeatures) {
            val value = features[feature] ?: return false
            if (value.isNaN() || value.isInfinite()) return false
        }
        return true
    }

    /**
     * Normalize features using training statistics.
     */
    fun normalizeFeatures(
        features: Map<String, Double>,
        mu: Map<String, Double>,
        sigma: Map<String, Double>
    ): Map<String, Double> {
        val normalized = mutableMapOf<String, Double>()

        for ((featureName, value) in features) {
            if (featureName in mu && featureName in sigma) {
                val mean = mu[featureName]!!
                val std = sigma[featureName]!!

                // Avoid division by zero
                normalized[featureName] = if (std > 0) {
                    (value - mean) / std
                } else {
                    0.0
                }
            } else {
                // Keep original value if no normalization params
                normalized[featureName] = value
            }
        }

        return normalized
    }
}
