# Synheart Emotion - Android SDK

[![Android API 21+](https://img.shields.io/badge/API-21%2B-brightgreen.svg)](https://android-arsenal.com/api?level=21)
[![Kotlin](https://img.shields.io/badge/Kotlin-1.8%2B-blue.svg)](https://kotlinlang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

On-device emotion inference from biosignals (heart rate and RR intervals) for Android applications.

## Status

✅ **Build Status**: All modules compile successfully
✅ **API Parity**: Matches Flutter/iOS/Python implementations
✅ **Thread-Safe**: Uses ConcurrentLinkedQueue for concurrent operations

## Features

- **Privacy-first**: All processing happens on-device
- **Real-time**: <5ms inference latency
- **Three emotion states**: Amused, Calm, Stressed
- **Sliding window**: 60s window with 5s step (configurable)
- **Kotlin-first**: Idiomatic Kotlin API with coroutine support

## Installation

Add the library to your Android project:

### Gradle

```kotlin
dependencies {
    implementation("ai.synheart:emotion:0.1.0")
}
```

Or include as a local module in your Android project.

### Verify Installation

Add this to your Activity or test:

```kotlin
import com.synheart.emotion.*

// Quick verification
val config = EmotionConfig()
val engine = EmotionEngine.fromPretrained(config)
println("✓ SDK initialized successfully")
```

## Quick Start

```kotlin
import com.synheart.emotion.*

// Create engine with default configuration
val config = EmotionConfig()
val engine = EmotionEngine.fromPretrained(config)

// Push data from wearable
engine.push(
    hr = 72.0,
    rrIntervalsMs = listOf(850.0, 820.0, 830.0, /* ... */),
    timestamp = Date()
)

// Get inference result when ready
val results = engine.consumeReady()
for (result in results) {
    println("Emotion: ${result.emotion}")
    println("Confidence: ${result.confidence}")
    println("Probabilities: ${result.probabilities}")
}
```

## Advanced Usage

### Custom Configuration

```kotlin
val config = EmotionConfig(
    windowMs = 60000L,        // 60 second window
    stepMs = 5000L,           // 5 second step
    minRrCount = 30,          // Minimum RR intervals
    hrBaseline = 65.0         // Personal HR baseline
)
```

### Logging

```kotlin
val engine = EmotionEngine.fromPretrained(
    config = config,
    onLog = { level, message, context ->
        when (level) {
            "error" -> Log.e("EmotionEngine", message)
            "warn" -> Log.w("EmotionEngine", message)
            "info" -> Log.i("EmotionEngine", message)
            "debug" -> Log.d("EmotionEngine", message)
        }
    }
)
```

### Buffer Statistics

```kotlin
val stats = engine.getBufferStats()
println("Buffer count: ${stats["count"]}")
println("Duration: ${stats["duration_ms"]}ms")
println("HR range: ${stats["hr_range"]}")
println("RR count: ${stats["rr_count"]}")
```

### Clear Buffer

```kotlin
engine.clear()
```

## API Reference

### EmotionConfig

Configuration for the emotion inference engine.

- `modelId: String` - Model identifier (default: "svm_linear_wrist_sdnn_v1_0")
- `windowMs: Long` - Rolling window size in milliseconds (default: 60000)
- `stepMs: Long` - Emission cadence in milliseconds (default: 5000)
- `minRrCount: Int` - Minimum RR intervals required (default: 30)
- `returnAllProbas: Boolean` - Return all label probabilities (default: true)
- `hrBaseline: Double?` - Optional HR baseline for personalization
- `priors: Map<String, Double>?` - Optional label priors for calibration

### EmotionEngine

Main emotion inference engine.

**Methods:**

- `push(hr, rrIntervalsMs, timestamp, motion)` - Push new data point
- `consumeReady(): List<EmotionResult>` - Consume ready results
- `getBufferStats(): Map<String, Any>` - Get buffer statistics
- `clear()` - Clear all buffered data

**Companion:**

- `fromPretrained(config, model?, onLog?)` - Create engine from pretrained model

### EmotionResult

Result of emotion inference.

- `timestamp: Date` - Timestamp when inference was performed
- `emotion: String` - Predicted emotion label (top-1)
- `confidence: Double` - Confidence score (0.0 to 1.0)
- `probabilities: Map<String, Double>` - All label probabilities
- `features: Map<String, Double>` - Extracted features
- `model: Map<String, Any>` - Model metadata

### EmotionError

Sealed class representing errors:

- `EmotionError.TooFewRR(minExpected, actual)` - Too few RR intervals
- `EmotionError.BadInput(reason)` - Invalid input data
- `EmotionError.ModelIncompatible(expectedFeats, actualFeats)` - Model incompatible
- `EmotionError.FeatureExtractionFailed(reason)` - Feature extraction failed

## Requirements

- Android API 21+ (Android 5.0 Lollipop)
- Kotlin 1.8+

## Privacy & Security

**IMPORTANT**: This library uses demo placeholder model weights that are NOT trained on real biosignal data. For production use, you must provide your own trained model weights.

All processing happens on-device. No data is sent to external servers.

## License

See LICENSE file for details.
