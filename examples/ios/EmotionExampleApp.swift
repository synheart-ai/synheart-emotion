import Foundation
import SynheartEmotion

/// Command-line demo of the Synheart Emotion SDK for iOS/macOS
///
/// This example demonstrates:
/// - Initializing the emotion engine
/// - Simulating biosignal data for different emotional states
/// - Processing and displaying emotion inference results
/// - Buffer statistics and logging

// MARK: - Scenario Definition

struct Scenario {
    let name: String
    let hrMean: Double
    let hrVariability: Double
}

// MARK: - Helper Functions

func generateRrIntervals(hr: Double, variability: Double) -> [Double] {
    let meanRr = 60000.0 / hr  // Convert HR to mean RR interval in ms
    let count = Int.random(in: 30...50)
    return (0..<count).map { _ in
        meanRr + Double.random(in: -variability...variability)
    }
}

func printSeparator() {
    print("\n" + String(repeating: "─", count: 60) + "\n")
}

// MARK: - Main Demo

print("╔════════════════════════════════════════════════════════════╗")
print("║          Synheart Emotion SDK - iOS/macOS Demo           ║")
print("╚════════════════════════════════════════════════════════════╝")

// Initialize the emotion engine
print("\n[1] Initializing emotion engine...")

let config = EmotionConfig(
    window: 60.0,        // 60 second window
    step: 5.0,           // 5 second step
    minRrCount: 30,      // Minimum 30 RR intervals
    hrBaseline: 70.0     // Baseline heart rate
)

do {
    let engine = try EmotionEngine.fromPretrained(
        config: config,
        onLog: { level, message, _ in
            let emoji: String
            switch level {
            case "error": emoji = "❌"
            case "warn": emoji = "⚠️"
            case "info": emoji = "ℹ️"
            case "debug": emoji = "🔍"
            default: emoji = "📝"
            }
            print("  \(emoji) [\(level)] \(message)")
        }
    )

    print("✓ Engine initialized successfully")

    printSeparator()

    // Define emotional state scenarios
    let scenarios = [
        Scenario(name: "Calm", hrMean: 60.0, hrVariability: 8.0),
        Scenario(name: "Amused", hrMean: 75.0, hrVariability: 12.0),
        Scenario(name: "Stressed", hrMean: 90.0, hrVariability: 15.0)
    ]

    print("[2] Starting biosignal simulation...\n")

    // Simulate data pushes for each scenario
    for scenario in scenarios {
        print("🎭 Simulating \(scenario.name) state...")
        print("   HR: \(Int(scenario.hrMean)) bpm (±\(Int(scenario.hrVariability)))\n")

        // Push 20 data points for this scenario (roughly 60 seconds of data)
        for i in 1...20 {
            // Generate synthetic biosignal data
            let hr = scenario.hrMean + Double.random(in: -5.0...5.0)
            let rrIntervals = generateRrIntervals(hr: hr, variability: scenario.hrVariability)

            // Push data to engine
            engine.push(
                hr: hr,
                rrIntervalsMs: rrIntervals,
                timestamp: Date()
            )

            // Consume ready results
            let results = engine.consumeReady()
            if !results.isEmpty {
                let result = results[0]

                // Display emotion with emoji
                let emoji: String
                switch result.emotion {
                case "Amused": emoji = "😊"
                case "Calm": emoji = "😌"
                case "Stressed": emoji = "😰"
                default: emoji = "🤔"
                }

                print("   📊 Result \(i):")
                print("      \(emoji) Emotion: \(result.emotion)")
                print("      🎯 Confidence: \(Int(result.confidence * 100))%")

                // Show all probabilities
                let probs = result.probabilities.sorted { $0.value > $1.value }
                print("      📈 Probabilities:")
                for (label, prob) in probs {
                    let percent = Int(prob * 100)
                    let bar = String(repeating: "█", count: percent / 5)
                    print("         \(label): \(bar) \(percent)%")
                }
                print()
            }

            // Simulate time between data points
            Thread.sleep(forTimeInterval: 0.1)
        }

        // Get buffer statistics
        let stats = engine.getBufferStats()
        print("   📦 Buffer Stats:")
        if let count = stats["count"] as? Int {
            print("      Samples: \(count)")
        }
        if let durationMs = stats["duration_ms"] as? Double {
            print("      Duration: \(Int(durationMs))ms")
        }
        if let rrCount = stats["rr_count"] as? Int {
            print("      RR Intervals: \(rrCount)")
        }

        printSeparator()

        // Clear buffer before next scenario
        engine.clear()
        print("🧹 Buffer cleared for next scenario\n")
    }

    print("✅ Demo completed successfully!")

} catch EmotionError.modelIncompatible(let expectedFeats, let actualFeats) {
    print("❌ Model incompatible: expected \(expectedFeats) features, got \(actualFeats)")
    exit(1)
} catch EmotionError.badInput(let reason) {
    print("❌ Bad input: \(reason)")
    exit(1)
} catch EmotionError.featureExtractionFailed(let reason) {
    print("❌ Feature extraction failed: \(reason)")
    exit(1)
} catch {
    print("❌ Unexpected error: \(error)")
    exit(1)
}

print("\n╔════════════════════════════════════════════════════════════╗")
print("║                    Thank you for trying!                   ║")
print("╚════════════════════════════════════════════════════════════╝\n")
