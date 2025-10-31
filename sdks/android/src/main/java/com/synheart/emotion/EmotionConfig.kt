package com.synheart.emotion

/**
 * Configuration for the emotion inference engine.
 *
 * @property modelId Model identifier (default: svm_linear_wrist_sdnn_v1_0)
 * @property windowMs Rolling window size for feature calculation in milliseconds (default: 60000ms = 60s)
 * @property stepMs Emission cadence for results in milliseconds (default: 5000ms = 5s)
 * @property minRrCount Minimum RR intervals required for inference (default: 30)
 * @property returnAllProbas Whether to return all label probabilities (default: true)
 * @property hrBaseline Optional HR baseline for personalization
 * @property priors Optional label priors for calibration
 */
data class EmotionConfig(
    val modelId: String = "svm_linear_wrist_sdnn_v1_0",
    val windowMs: Long = 60000L,
    val stepMs: Long = 5000L,
    val minRrCount: Int = 30,
    val returnAllProbas: Boolean = true,
    val hrBaseline: Double? = null,
    val priors: Map<String, Double>? = null
) {
    override fun toString(): String {
        return "EmotionConfig(modelId=$modelId, window=${windowMs / 1000}s, " +
               "step=${stepMs / 1000}s, minRrCount=$minRrCount)"
    }
}
