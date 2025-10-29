# Synheart Emotion

**On-device emotion inference from biosignals (HR/RR) for Flutter applications**

[![pub package](https://img.shields.io/pub/v/synheart_emotion.svg)](https://pub.dev/packages/synheart_emotion)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🚀 Features

- **📱 Cross-Platform**: Works on iOS and Android
- **🔄 Real-Time Inference**: Live emotion detection from heart rate and RR intervals
- **🧠 On-Device Processing**: All computations happen locally for privacy
- **📊 Unified Output**: Consistent emotion labels with confidence scores
- **🔒 Privacy-First**: No raw biometric data leaves your device
- **⚡ High Performance**: < 5ms inference latency on mid-range devices

## 📦 Installation

Add `synheart_emotion` to your `pubspec.yaml`:

```yaml
dependencies:
  synheart_emotion: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## 🎯 Quick Start

### Basic Usage

```dart
import 'package:synheart_emotion/synheart_emotion.dart';

void main() async {
  // Initialize the emotion engine
  final engine = EmotionEngine.fromPretrained(
    const EmotionConfig(
      window: Duration(seconds: 60),
      step: Duration(seconds: 5),
    ),
  );

  // Push biometric data
  engine.push(
    hr: 72.0,
    rrIntervalsMs: [823, 810, 798, 815, 820],
    timestamp: DateTime.now().toUtc(),
  );

  // Get emotion results
  final results = engine.consumeReady();
  for (final result in results) {
    print('Emotion: ${result.emotion} (${(result.confidence * 100).toStringAsFixed(1)}%)');
  }
}
```

### Real-Time Streaming

```dart
// Stream emotion results
final emotionStream = EmotionStream.emotionStream(
  engine,
  tickStream, // Your biometric data stream
);

await for (final result in emotionStream) {
  print('Current emotion: ${result.emotion}');
  print('Probabilities: ${result.probabilities}');
}
```

### Integration with synheart-wear

**synheart_emotion** works independently but integrates seamlessly with [synheart-wear](https://github.com/synheart-ai/synheart-wear) for real wearable data.



First, add both to your `pubspec.yaml`:

```yaml
dependencies:
  synheart_wear: ^0.1.0    # For wearable data
  synheart_emotion: ^0.1.0  # For emotion inference
```

Then integrate in your app:

```dart
import 'package:synheart_wear/synheart_wear.dart';
import 'package:synheart_emotion/synheart_emotion.dart';

// Initialize both SDKs
final wear = SynheartWear();
final emotionEngine = EmotionEngine.fromPretrained(
  const EmotionConfig(window: Duration(seconds: 60)),
);

await wear.initialize();

// Stream wearable data to emotion engine
wear.streamHR(interval: Duration(seconds: 1)).listen((metrics) {
  emotionEngine.push(
    hr: metrics.getMetric(MetricType.hr),
    rrIntervalsMs: metrics.getMetric(MetricType.rrIntervals),
    timestamp: DateTime.now().toUtc(),
  );
  
  // Get emotion results
  final emotions = emotionEngine.consumeReady();
  for (final emotion in emotions) {
    // Use emotion data in your app
    updateUI(emotion);
  }
});
```

See `example/lib/integration_example.dart` for complete integration examples.

## 📊 Supported Emotions

The library currently supports three emotion categories:

- **😊 Amused**: Positive, engaged emotional state
- **😌 Calm**: Relaxed, peaceful emotional state  
- **😰 Stressed**: Anxious, tense emotional state

## 🔧 API Reference

### EmotionEngine

The main class for emotion inference:

```dart
class EmotionEngine {
  // Create engine with pretrained model
  factory EmotionEngine.fromPretrained(
    EmotionConfig config, {
    LinearSvmModel? model,
    void Function(String level, String message, {Map<String, Object?>? context})? onLog,
  });

  // Push new biometric data
  void push({
    required double hr,
    required List<double> rrIntervalsMs,
    required DateTime timestamp,
    Map<String, double>? motion,
  });

  // Get ready emotion results
  List<EmotionResult> consumeReady();

  // Get buffer statistics
  Map<String, dynamic> getBufferStats();

  // Clear all buffered data
  void clear();
}
```

### EmotionConfig

Configuration for the emotion engine:

```dart
class EmotionConfig {
  final String modelId;                 // Model identifier
  final Duration window;                // Rolling window size (default: 60s)
  final Duration step;                  // Emission cadence (default: 5s)
  final int minRrCount;                 // Min RR intervals needed (default: 30)
  final bool returnAllProbas;           // Return all probabilities (default: true)
  final double? hrBaseline;             // Optional HR personalization
  final Map<String,double>? priors;     // Optional label priors
}
```

### EmotionResult

Result of emotion inference:

```dart
class EmotionResult {
  final DateTime timestamp;             // When inference was performed
  final String emotion;                 // Predicted emotion (top-1)
  final double confidence;              // Confidence score (0.0-1.0)
  final Map<String, double> probabilities; // All label probabilities
  final Map<String, double> features;   // Extracted features
  final Map<String, dynamic> model;     // Model metadata
}
```

## 🔒 Privacy & Security

- **On-Device Processing**: All emotion inference happens locally
- **No Data Retention**: Raw biometric data is not retained after processing
- **No Network Calls**: No data is sent to external servers
- **Privacy-First Design**: No built-in storage - you control what gets persisted
- **Real Trained Models**: Uses WESAD-trained models with 78% accuracy

## 📱 Example App

Check out the complete example in the `example/` directory:

```bash
cd example
flutter run
```

The example demonstrates:
- Real-time emotion detection
- Probability visualization
- Buffer management
- Logging system

## 🧪 Testing

Run the test suite:

```bash
flutter test
```

Run benchmarks:

```bash
flutter test test/benchmarks_test.dart
```

Tests cover:
- Feature extraction accuracy
- Model inference performance
- Edge case handling
- Memory usage patterns

## 📊 Performance

**Target Performance (mid-range phone):**
- **Latency**: < 5ms per inference
- **Model Size**: < 100 KB
- **CPU Usage**: < 2% during active streaming
- **Memory**: < 3 MB (engine + buffers)
- **Accuracy**: 78% on WESAD dataset (3-class emotion recognition)

**Benchmarks:**
- HR mean calculation: < 1ms
- SDNN/RMSSD calculation: < 2ms
- Model inference: < 1ms
- Full pipeline: < 5ms

## 🏗️ Architecture

```
Biometric Data (HR, RR)
         │
         ▼
┌─────────────────────┐
│   EmotionEngine     │
│  [RingBuffer]       │
│  [FeatureExtractor] │
│  [Model Inference]  │
└─────────────────────┘
         │
         ▼
   EmotionResult
         │
         ▼
    Your App
```

## 🔗 Integration

### With synheart-wear

Perfect integration with the Synheart Wear SDK for real wearable data:

```dart
// Stream from Apple Watch, Fitbit, etc.
final wearStream = synheartWear.streamHR();
final emotionStream = EmotionStream.emotionStream(engine, wearStream);
```

### With swip-core

Feed emotion results into the SWIP impact measurement system:

```dart
for (final emotion in emotionResults) {
  swipCore.ingestEmotion(emotion);
}
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

We welcome contributions! See our [Contributing Guidelines](CONTRIBUTING.md) for details.

## 🔗 Links

- **Documentation**: [docs/RFC-E1.1.md](docs/RFC-E1.1.md)
- **Synheart Wear**: [synheart-wear](https://github.com/synheart-ai/synheart-wear)
- **Synheart AI**: [synheart.ai](https://synheart.ai)
- **Issues**: [GitHub Issues](https://github.com/synheart-ai/synheart-emotion/issues)

## 👥 Authors

- **Synheart AI Team** - _Initial work_, _RFC Design & Architecture_

---

**Made with ❤️ by the Synheart AI Team**

_Technology with a heartbeat._
