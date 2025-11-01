package com.synheart.emotion.example

import android.os.Bundle
import android.util.Log
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.synheart.emotion.*
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.util.Date
import kotlin.random.Random

/**
 * Example Android app demonstrating the Synheart Emotion SDK.
 *
 * This app simulates biosignal data and displays real-time emotion inference results.
 */
class MainActivity : AppCompatActivity() {

    private lateinit var statusTextView: TextView
    private lateinit var emotionTextView: TextView
    private lateinit var confidenceTextView: TextView
    private lateinit var detailsTextView: TextView
    private lateinit var logsTextView: TextView

    private lateinit var engine: EmotionEngine
    private var isRunning = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // Initialize views
        statusTextView = findViewById(R.id.statusText)
        emotionTextView = findViewById(R.id.emotionText)
        confidenceTextView = findViewById(R.id.confidenceText)
        detailsTextView = findViewById(R.id.detailsText)
        logsTextView = findViewById(R.id.logsText)

        // Initialize the emotion engine
        initializeEngine()

        // Start simulating data
        startSimulation()
    }

    private fun initializeEngine() {
        try {
            val config = EmotionConfig(
                windowMs = 60000L,  // 60 second window
                stepMs = 5000L,     // 5 second step
                minRrCount = 30,    // Minimum 30 RR intervals
                hrBaseline = 70.0   // Baseline heart rate
            )

            engine = EmotionEngine.fromPretrained(
                config = config,
                onLog = { level, message, context ->
                    runOnUiThread {
                        appendLog("[$level] $message")
                    }
                }
            )

            statusTextView.text = "✓ SDK Initialized"
            appendLog("[info] Emotion engine initialized successfully")
        } catch (e: Exception) {
            statusTextView.text = "✗ Initialization Failed"
            appendLog("[error] Failed to initialize: ${e.message}")
        }
    }

    private fun startSimulation() {
        if (isRunning) return
        isRunning = true

        lifecycleScope.launch {
            appendLog("[info] Starting biosignal simulation...")

            // Simulate different emotional states
            val scenarios = listOf(
                Scenario("Calm", 60.0, 8.0),
                Scenario("Amused", 75.0, 12.0),
                Scenario("Stressed", 90.0, 15.0)
            )

            var currentScenario = scenarios[0]
            var pushCount = 0

            while (isRunning) {
                // Change scenario every 20 pushes (roughly 60 seconds)
                if (pushCount % 20 == 0) {
                    currentScenario = scenarios.random()
                    appendLog("[info] Simulating ${currentScenario.name} state...")
                }

                // Generate synthetic biosignal data
                val hr = currentScenario.hrMean + Random.nextDouble(-5.0, 5.0)
                val rrIntervals = generateRrIntervals(hr, currentScenario.hrVariability)

                // Push data to engine
                engine.push(
                    hr = hr,
                    rrIntervalsMs = rrIntervals,
                    timestamp = Date()
                )

                // Consume ready results
                val results = engine.consumeReady()
                if (results.isNotEmpty()) {
                    displayResults(results[0])
                }

                // Update buffer stats
                val stats = engine.getBufferStats()
                updateBufferStats(stats)

                pushCount++
                delay(3000) // Push data every 3 seconds
            }
        }
    }

    private fun generateRrIntervals(hr: Double, variability: Double): List<Double> {
        val meanRr = 60000.0 / hr  // Convert HR to mean RR interval in ms
        val count = Random.nextInt(30, 50)
        return List(count) {
            meanRr + Random.nextDouble(-variability, variability)
        }
    }

    private fun displayResults(result: EmotionResult) {
        runOnUiThread {
            // Display emotion with emoji
            val emoji = when (result.emotion) {
                "Amused" -> "😊"
                "Calm" -> "😌"
                "Stressed" -> "😰"
                else -> "🤔"
            }
            emotionTextView.text = "$emoji ${result.emotion}"

            // Display confidence
            val confidencePercent = (result.confidence * 100).toInt()
            confidenceTextView.text = "Confidence: $confidencePercent%"

            // Display probabilities
            val probsText = result.probabilities.entries
                .sortedByDescending { it.value }
                .joinToString("\n") { (label, prob) ->
                    val percent = (prob * 100).toInt()
                    "$label: $percent%"
                }
            detailsTextView.text = "Probabilities:\n$probsText"

            appendLog("[result] Emotion: ${result.emotion} ($confidencePercent%)")
        }
    }

    private fun updateBufferStats(stats: Map<String, Any>) {
        val count = stats["count"] ?: 0
        val durationMs = stats["duration_ms"] ?: 0
        statusTextView.text = "Buffer: $count samples, ${durationMs}ms"
    }

    private fun appendLog(message: String) {
        val currentLogs = logsTextView.text.toString()
        val lines = currentLogs.split("\n").toMutableList()

        // Keep only last 10 lines
        if (lines.size > 10) {
            lines.removeAt(0)
        }

        lines.add(message)
        logsTextView.text = lines.joinToString("\n")
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        engine.clear()
    }

    private data class Scenario(
        val name: String,
        val hrMean: Double,
        val hrVariability: Double
    )
}
