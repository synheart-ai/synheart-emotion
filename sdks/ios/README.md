# Synheart Emotion - iOS SDK

[![iOS 13.0+](https://img.shields.io/badge/iOS-13.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

On-device emotion inference from biosignals (heart rate and RR intervals) for iOS, macOS, watchOS, and tvOS applications.

## Status

✅ **Build Status**: Compiles successfully with Swift 5.9+
✅ **API Parity**: Matches Flutter/Android/Python implementations
✅ **Thread-Safe**: Uses DispatchQueue with concurrent reads and barrier writes
✅ **Multi-Platform**: iOS 13+, macOS 10.15+, watchOS 6+, tvOS 13+

## Features

- **Privacy-first**: All processing happens on-device
- **Real-time**: <5ms inference latency
- **Three emotion states**: Amused, Calm, Stressed
- **Sliding window**: 60s window with 5s step (configurable)
- **Swift-first**: Idiomatic Swift API with thread-safe operations
- **Multi-platform**: iOS 13+, macOS 10.15+, watchOS 6+, tvOS 13+

## Installation

### Swift Package Manager

Add the package to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/synheart/synheart-emotion.git", from: "0.1.0")
]
```

Or add it in Xcode:
1. File → Add Packages
2. Enter the repository URL
3. Select version 0.1.0 or later

### Verify Installation

```bash
# Build the package
swift build

# Run in your code
import SynheartEmotion

let config = EmotionConfig()
let engine = try EmotionEngine.fromPretrained(config: config)
print("✓ SDK initialized successfully")
```

## Quick Start

```swift
import SynheartEmotion

// Create engine with default configuration
let config = EmotionConfig()
let engine = try EmotionEngine.fromPretrained(config: config)

// Push data from wearable
engine.push(
    hr: 72.0,
    rrIntervalsMs: [850.0, 820.0, 830.0, /* ... */],
    timestamp: Date()
)

// Get inference result when ready
let results = engine.consumeReady()
for result in results {
    print("Emotion: \(result.emotion)")
    print("Confidence: \(result.confidence)")
    print("Probabilities: \(result.probabilities)")
}
```

## Advanced Usage

### Custom Configuration

```swift
let config = EmotionConfig(
    window: 60.0,         // 60 second window
    step: 5.0,            // 5 second step
    minRrCount: 30,       // Minimum RR intervals
    hrBaseline: 65.0      // Personal HR baseline
)
```

### Logging

```swift
let engine = try EmotionEngine.fromPretrained(
    config: config,
    onLog: { level, message, context in
        switch level {
        case "error":
            print("❌ \(message)")
        case "warn":
            print("⚠️ \(message)")
        case "info":
            print("ℹ️ \(message)")
        case "debug":
            print("🔍 \(message)")
        default:
            print(message)
        }
    }
)
```

### Buffer Statistics

```swift
let stats = engine.getBufferStats()
print("Buffer count: \(stats["count"] ?? 0)")
print("Duration: \(stats["duration_ms"] ?? 0)ms")
print("HR range: \(stats["hr_range"] ?? [])")
print("RR count: \(stats["rr_count"] ?? 0)")
```

### Clear Buffer

```swift
engine.clear()
```

### Error Handling

```swift
do {
    let engine = try EmotionEngine.fromPretrained(config: config)
    // Use engine...
} catch EmotionError.modelIncompatible(let expectedFeats, let actualFeats) {
    print("Model incompatible: expected \(expectedFeats), got \(actualFeats)")
} catch EmotionError.badInput(let reason) {
    print("Bad input: \(reason)")
} catch {
    print("Error: \(error)")
}
```

## HealthKit Integration

Example integration with HealthKit for heart rate data:

```swift
import HealthKit
import SynheartEmotion

class HealthKitEmotionMonitor {
    private let healthStore = HKHealthStore()
    private let engine: EmotionEngine

    init() throws {
        let config = EmotionConfig()
        self.engine = try EmotionEngine.fromPretrained(config: config)
    }

    func startMonitoring() {
        // Request authorization
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let heartRateVariabilityType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!

        healthStore.requestAuthorization(toShare: nil, read: [heartRateType, heartRateVariabilityType]) { success, error in
            guard success else { return }
            self.observeHeartRate()
        }
    }

    private func observeHeartRate() {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] query, completionHandler, error in
            self?.fetchLatestHeartRate()
            completionHandler()
        }

        healthStore.execute(query)
    }

    private func fetchLatestHeartRate() {
        // Fetch and process heart rate samples
        // Convert to RR intervals and push to engine
        // ... implementation details ...
    }
}
```

## API Reference

### EmotionConfig

Configuration for the emotion inference engine.

```swift
public struct EmotionConfig {
    let modelId: String               // Model identifier
    let window: TimeInterval          // Rolling window size (default: 60s)
    let step: TimeInterval            // Emission cadence (default: 5s)
    let minRrCount: Int              // Minimum RR intervals (default: 30)
    let returnAllProbas: Bool        // Return all probabilities (default: true)
    let hrBaseline: Double?          // Optional HR baseline
    let priors: [String: Double]?    // Optional label priors
}
```

### EmotionEngine

Main emotion inference engine.

**Methods:**

- `push(hr:rrIntervalsMs:timestamp:motion:)` - Push new data point
- `consumeReady() -> [EmotionResult]` - Consume ready results
- `getBufferStats() -> [String: Any]` - Get buffer statistics
- `clear()` - Clear all buffered data

**Static Methods:**

- `fromPretrained(config:model:onLog:)` - Create engine from pretrained model

### EmotionResult

Result of emotion inference.

```swift
public struct EmotionResult {
    let timestamp: Date              // Timestamp of inference
    let emotion: String              // Predicted emotion (top-1)
    let confidence: Double           // Confidence score (0.0-1.0)
    let probabilities: [String: Double]  // All label probabilities
    let features: [String: Double]   // Extracted features
    let model: [String: Any]         // Model metadata
}
```

### EmotionError

Error types:

```swift
public enum EmotionError: Error {
    case tooFewRR(minExpected: Int, actual: Int)
    case badInput(reason: String)
    case modelIncompatible(expectedFeats: Int, actualFeats: Int)
    case featureExtractionFailed(reason: String)
}
```

## Requirements

- iOS 13.0+ / macOS 10.15+ / watchOS 6.0+ / tvOS 13.0+
- Swift 5.9+
- Xcode 15.0+

## Privacy & Security

**IMPORTANT**: This library uses demo placeholder model weights that are NOT trained on real biosignal data. For production use, you must provide your own trained model weights.

All processing happens on-device. No data is sent to external servers.

## License

See LICENSE file for details.
