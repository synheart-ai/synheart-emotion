# Synheart Emotion - Android Example

This is a native Android example app demonstrating the Synheart Emotion SDK for Android.

## Features

- **Real-time emotion inference** from simulated biosignal data
- **Visual display** of current emotion with emoji
- **Confidence scores** and probability distributions
- **Live logs** showing SDK activity
- **Buffer statistics** display

## Requirements

- Android Studio Arctic Fox or later
- Android SDK 21+ (Android 5.0+)
- Kotlin 1.8+
- Gradle 7.0+

## Setup

1. Open the project in Android Studio:
   ```bash
   cd examples/android
   ```

2. Sync Gradle:
   - Android Studio should automatically prompt you to sync
   - Or click `File` → `Sync Project with Gradle Files`

3. Build and run:
   - Click the "Run" button in Android Studio
   - Or use the command line:
     ```bash
     ./gradlew assembleDebug
     ./gradlew installDebug
     ```

## Project Structure

```
examples/android/
├── build.gradle                 # App-level build configuration
├── settings.gradle             # Project settings (includes SDK module)
├── gradle.properties           # Gradle properties
└── src/
    └── main/
        ├── AndroidManifest.xml # App manifest
        ├── java/com/synheart/emotion/example/
        │   └── MainActivity.kt # Main activity with SDK demo
        └── res/
            ├── layout/
            │   └── activity_main.xml  # UI layout
            ├── values/
            │   ├── strings.xml  # String resources
            │   ├── themes.xml   # App themes
            │   └── colors.xml   # Color resources
            └── mipmap/          # App icons
```

## How It Works

The app demonstrates the Synheart Emotion SDK by:

1. **Initializing** the emotion engine with custom configuration
2. **Simulating** biosignal data (heart rate and RR intervals)
3. **Pushing** data to the engine every 3 seconds
4. **Consuming** emotion inference results when ready
5. **Displaying** results in a user-friendly interface

### Code Highlights

**Engine Initialization:**
```kotlin
val config = EmotionConfig(
    windowMs = 60000L,  // 60 second window
    stepMs = 5000L,     // 5 second step
    minRrCount = 30,    // Minimum 30 RR intervals
    hrBaseline = 70.0   // Baseline heart rate
)

engine = EmotionEngine.fromPretrained(
    config = config,
    onLog = { level, message, context ->
        // Handle logs
    }
)
```

**Pushing Data:**
```kotlin
engine.push(
    hr = 72.0,
    rrIntervalsMs = listOf(850.0, 820.0, 830.0, ...),
    timestamp = Date()
)
```

**Consuming Results:**
```kotlin
val results = engine.consumeReady()
if (results.isNotEmpty()) {
    val result = results[0]
    println("Emotion: ${result.emotion}")
    println("Confidence: ${result.confidence}")
    println("Probabilities: ${result.probabilities}")
}
```

## Simulation

The app simulates three emotional states with different biosignal characteristics:

- **Calm**: HR ~60 bpm, low variability
- **Amused**: HR ~75 bpm, medium variability
- **Stressed**: HR ~90 bpm, high variability

The simulation automatically cycles through these states to demonstrate the SDK's capabilities.

## Integration with Your App

To integrate the SDK into your own Android app:

1. Add the dependency to your `build.gradle`:
   ```kotlin
   dependencies {
       implementation("ai.synheart:emotion:0.1.0")
   }
   ```

2. Initialize the engine in your Activity or ViewModel:
   ```kotlin
   val engine = EmotionEngine.fromPretrained(EmotionConfig())
   ```

3. Push real biosignal data from your sensor/wearable:
   ```kotlin
   engine.push(hr = heartRate, rrIntervalsMs = rrIntervals, timestamp = Date())
   ```

4. Consume and display results:
   ```kotlin
   val results = engine.consumeReady()
   results.forEach { result ->
       // Update UI with result.emotion, result.confidence, etc.
   }
   ```

## Troubleshooting

### Build Issues

If you encounter build issues:

1. Make sure you're using Android Studio Arctic Fox or later
2. Sync Gradle files: `File` → `Sync Project with Gradle Files`
3. Clean and rebuild: `Build` → `Clean Project`, then `Build` → `Rebuild Project`

### SDK Module Not Found

If Gradle can't find the SDK module:

1. Check that `settings.gradle` correctly references the SDK:
   ```gradle
   include ':sdks:android'
   project(':sdks:android').projectDir = new File(rootProject.projectDir, '../../sdks/android')
   ```

2. Verify that the SDK exists at `../../sdks/android/` relative to this example directory

## License

MIT License - See LICENSE file for details.

## Support

For issues and questions:
- GitHub Issues: https://github.com/synheart-ai/synheart-emotion/issues
- Documentation: https://github.com/synheart-ai/synheart-emotion
