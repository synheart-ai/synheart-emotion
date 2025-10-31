# Synheart Emotion

**On-device emotion inference from biosignals (HR/RR) for Flutter, Python, Android, and iOS applications**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python Tests](https://img.shields.io/badge/Python%20tests-16%2F16%20passing-brightgreen.svg)](sdks/python/tests/)
[![Platform Support](https://img.shields.io/badge/platforms-Flutter%20%7C%20Python%20%7C%20Android%20%7C%20iOS-blue.svg)](#-sdks)

Synheart Emotion is a comprehensive SDK ecosystem for inferring momentary emotions from biosignals (heart rate and RR intervals) directly on device, ensuring privacy and real-time performance.

## 🚀 Features

- **📱 Multi-Platform**: Flutter, Python, Android (Kotlin), iOS (Swift)
- **🔄 Real-Time Inference**: Live emotion detection from heart rate and RR intervals
- **🧠 On-Device Processing**: All computations happen locally for privacy
- **📊 Unified API**: Consistent API across all platforms
- **🔒 Privacy-First**: No raw biometric data leaves your device
- **⚡ High Performance**: < 5ms inference latency on mid-range devices
- **🎓 Research-Based**: Models trained on WESAD dataset with 78% accuracy
- **🧪 Thread-Safe**: Concurrent data ingestion supported on all platforms

## 📦 SDKs

All SDKs provide **identical functionality** with platform-idiomatic APIs:

### Flutter/Dart SDK (Primary)
```yaml
dependencies:
  synheart_emotion: ^0.1.0
```
📖 [Flutter SDK Documentation](sdks/flutter/README.md)

### Python SDK [![PyPI](https://img.shields.io/badge/PyPI-pip%20installable-blue.svg)](sdks/python/)
```bash
pip install synheart-emotion
```
📖 [Python SDK Documentation](sdks/python/README.md)

### Android SDK (Kotlin) [![Android API 21+](https://img.shields.io/badge/API-21%2B-brightgreen.svg)](sdks/android/)
```kotlin
dependencies {
    implementation("ai.synheart:emotion:0.1.0")
}
```
📖 [Android SDK Documentation](sdks/android/README.md)

### iOS SDK (Swift) [![iOS 13.0+](https://img.shields.io/badge/iOS-13.0%2B-blue.svg)](sdks/ios/)
**Swift Package Manager:**
```swift
dependencies: [
    .package(url: "https://github.com/synheart-ai/synheart-emotion.git", from: "0.1.0")
]
```

**CocoaPods:**
```ruby
pod 'SynheartEmotion', '~> 0.1.0'
```
📖 [iOS SDK Documentation](sdks/ios/README.md)

## 📂 Repository Structure

```
synheart-emotion/
├── sdks/                          # Platform-specific SDKs
│   ├── flutter/                   # Flutter/Dart SDK (reference implementation)
│   ├── python/                    # Python SDK (pip-installable)
│   ├── android/                   # Android SDK (Kotlin)
│   └── ios/                       # iOS SDK (Swift)
│
├── tools/                         # Development tools
│   ├── synthetic-data-generator/  # Generate test biosignal data
│   └── wesad-reference-models/    # Research artifacts (14 ML models)
│
├── examples/                      # Example applications
├── docs/                          # Documentation (RFC, Model Cards)
├── models/                        # Model definitions and assets
└── test/                          # Cross-platform test suite
```

## 🎯 Quick Start

### Python (Recommended for Testing)

```python
from datetime import datetime
from synheart_emotion import EmotionEngine, EmotionConfig

# Initialize engine
config = EmotionConfig()
engine = EmotionEngine.from_pretrained(config)

# Push biosignal data
engine.push(
    hr=72.0,
    rr_intervals_ms=[850.0, 820.0, 830.0, 845.0, 825.0],
    timestamp=datetime.now()
)

# Get inference results
results = engine.consume_ready()
for result in results:
    print(f"Emotion: {result.emotion} ({result.confidence:.1%})")
```

### Flutter

```dart
import 'package:synheart_emotion/synheart_emotion.dart';

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
  rrIntervalsMs: [850.0, 820.0, 830.0, 845.0, 825.0],
  timestamp: DateTime.now(),
);

// Get results
final results = engine.consumeReady();
for (final result in results) {
  print('Emotion: ${result.emotion} (${result.confidence})');
}
```

### Android (Kotlin)

```kotlin
import com.synheart.emotion.*

val config = EmotionConfig()
val engine = EmotionEngine.fromPretrained(config)

engine.push(
    hr = 72.0,
    rrIntervalsMs = listOf(850.0, 820.0, 830.0, 845.0, 825.0),
    timestamp = Date()
)

val results = engine.consumeReady()
results.forEach { result ->
    println("Emotion: ${result.emotion} (${result.confidence})")
}
```

### iOS (Swift)

```swift
import SynheartEmotion

let config = EmotionConfig()
let engine = try! EmotionEngine.fromPretrained(config: config)

engine.push(
    hr: 72.0,
    rrIntervalsMs: [850.0, 820.0, 830.0, 845.0, 825.0],
    timestamp: Date()
)

let results = engine.consumeReady()
results.forEach { result in
    print("Emotion: \(result.emotion) (\(result.confidence))")
}
```

## 📊 Supported Emotions

The library currently supports three emotion categories:

- **😊 Amused**: Positive, engaged emotional state
- **😌 Calm**: Relaxed, peaceful emotional state
- **😰 Stressed**: Anxious, tense emotional state

## 🛠️ Development Tools

### Synthetic Data Generator

Generate realistic biosignal data for testing all SDKs:

```bash
cd tools/synthetic-data-generator

# Generate test data
python cli.py --emotion Calm --duration 60 --output ./data

# Generate session with transitions
python cli.py --session Calm Stressed Amused --transitions --output ./data
```

Exports to: CSV, JSON, Python, Kotlin, Swift

📖 [Data Generator Documentation](tools/synthetic-data-generator/README.md)

### WESAD Reference Models

Research artifacts with 14 pre-trained ML models from WESAD dataset:

- XGBoost, RandomForest, ExtraTrees, KNN, LDA, SVM, etc.
- For research and model comparison only
- **Not for production use** (use SDKs instead)

📖 [Research Models Documentation](tools/wesad-reference-models/README.md)

## 🏗️ Architecture

All SDKs implement the same architecture:

```
Wearable / Sensor
   └─(HR bpm, RR ms)──► Your App
                           │
                           ▼
                   Synheart Emotion SDK
            [Ring Buffer] → [Feature Extraction] → [Normalization]
                                     │
                                  [Model]
                                     │
                              EmotionResult
```

**Components:**
- **Ring Buffer**: Holds last 60s of HR/RR data (configurable)
- **Feature Extractor**: Computes HR mean, SDNN, RMSSD
- **Scaler**: Standardizes features using training μ/σ
- **Model**: Linear SVM (One-vs-Rest) with softmax
- **Emitter**: Throttles outputs (default: every 5s)

## 🎨 API Parity

All SDKs expose identical functionality:

| Feature | Python | Android | iOS | Flutter |
|---------|--------|---------|-----|---------|
| EmotionConfig | ✅ | ✅ | ✅ | ✅ |
| EmotionEngine | ✅ | ✅ | ✅ | ✅ |
| EmotionResult | ✅ | ✅ | ✅ | ✅ |
| EmotionError | ✅ | ✅ | ✅ | ✅ |
| Feature Extraction | ✅ | ✅ | ✅ | ✅ |
| Linear SVM Model | ✅ | ✅ | ✅ | ✅ |
| Thread-Safe | ✅ | ✅ | ✅ | ✅ |
| Sliding Window | ✅ | ✅ | ✅ | ✅ |

## 🧪 Test Results

### Python SDK
- ✅ **16/16 tests passing** (100%)
- ✅ All examples working
- ✅ CLI demo functional

### Android SDK
- ✅ All modules compile successfully
- ✅ 6 Kotlin source files
- ✅ API parity verified
- ✅ Gradle build and tests passing

### iOS SDK
- ✅ Swift build successful
- ✅ 6 Swift source files
- ✅ Multi-platform support (iOS, macOS, watchOS, tvOS)
- ✅ Swift Package Manager integration

## 🔬 Model Details

**Model Type**: Linear SVM (One-vs-Rest)
**Task**: Momentary emotion recognition from HR/RR
**Input Features**: `[hr_mean, sdnn, rmssd]` over a 60s rolling window
**Performance**:
- Accuracy: ~78%
- Macro-F1: ~72%
- Latency: < 5ms on modern mid-range devices

The model is trained on WESAD-derived 3-class subset with artifact rejection and normalization.

📖 [Model Card](docs/MODEL_CARD.md) | [RFC E1.1](docs/RFC-E1.1.md)

## 🔒 Privacy & Security

- **On-Device Processing**: All emotion inference happens locally
- **No Data Retention**: Raw biometric data is not retained after processing
- **No Network Calls**: No data is sent to external servers
- **Privacy-First Design**: No built-in storage - you control what gets persisted
- **Not a Medical Device**: This library is for wellness and research purposes only

⚠️ **Important**: The default model weights are trained on the WESAD dataset and achieve 78% accuracy. For production use, consider training on your own data if needed.

## 📚 Documentation

### SDK Documentation
- [Flutter SDK](sdks/flutter/README.md) - Flutter/Dart implementation
- [Python SDK](sdks/python/README.md) - Python implementation
- [Android SDK](sdks/android/README.md) - Kotlin/Android implementation
- [iOS SDK](sdks/ios/README.md) - Swift/iOS implementation

### Tools Documentation
- [Synthetic Data Generator](tools/synthetic-data-generator/README.md) - Test data generation
- [WESAD Reference Models](tools/wesad-reference-models/README.md) - Research artifacts

### Technical Documentation
- [RFC E1.1](docs/RFC-E1.1.md) - Complete technical specification
- [Model Card](docs/MODEL_CARD.md) - Model details and performance
- [Contributing Guide](CONTRIBUTING.md) - How to contribute (covers all SDKs)
- [Changelog](CHANGELOG.md) - Version history for all SDKs

## 🔧 Development

### Requirements

- **Flutter SDK**: Flutter >= 3.10.0, Dart >= 3.0.0
- **Python SDK**: Python >= 3.8
- **Android SDK**: Android API 21+, Kotlin 1.8+
- **iOS SDK**: iOS 13+, Swift 5.9+

### Running Tests

```bash
# Python SDK
cd sdks/python
pytest tests/

# Flutter SDK
cd sdks/flutter
flutter test

# Android SDK
cd sdks/android
./gradlew test

# iOS SDK
cd sdks/ios
swift build
swift test

# Generate test data
cd tools/synthetic-data-generator
python cli.py --emotion Calm --duration 60 --output ./test_data
```

## 🔗 Integration Examples

### With Custom Data Source

```python
# Python example
from synheart_emotion import EmotionEngine, EmotionConfig
from your_sensor import get_biosignal_stream

engine = EmotionEngine.from_pretrained(EmotionConfig())

for data_point in get_biosignal_stream():
    engine.push(
        hr=data_point.heart_rate,
        rr_intervals_ms=data_point.rr_intervals,
        timestamp=data_point.timestamp
    )

    results = engine.consume_ready()
    if results:
        print(f"Current emotion: {results[0].emotion}")
```

### With Apple HealthKit (iOS)

See [iOS SDK Examples](sdks/ios/README.md#healthkit-integration) for HealthKit integration.

## 📈 Performance Targets

**Target Performance (mid-range device):**
- **Latency**: < 5ms per inference
- **Model Size**: < 100 KB
- **CPU Usage**: < 2% during active streaming
- **Memory**: < 3 MB (engine + buffers)
- **Accuracy**: 78% on WESAD dataset (3-class emotion recognition)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details on:

- Code style and conventions
- Testing requirements
- Pull request process
- Development setup

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Synheart AI**: [synheart.ai](https://synheart.ai)
- **Documentation**: [Full Documentation](docs/)
- **Issues**: [GitHub Issues](https://github.com/synheart-ai/synheart-emotion/issues)
- **Discussions**: [GitHub Discussions](https://github.com/synheart-ai/synheart-emotion/discussions)

## 📖 Citation

If you use this SDK in your research:

```bibtex
@software{synheart_emotion,
  title = {Synheart Emotion: Multi-platform SDK for on-device emotion inference from biosignals},
  author = {Synheart AI Team},
  year = {2025},
  version = {0.1.0},
  url = {https://github.com/synheart-ai/synheart-emotion}
}
```

WESAD Dataset:
```bibtex
@article{schmidt2018introducing,
  title={Introducing WESAD, a multimodal dataset for wearable stress and affect detection},
  author={Schmidt, Philip and Reiss, Attila and Duerichen, Robert and Marberger, Claus and Van Laerhoven, Kristof},
  journal={ICMI 2018},
  year={2018}
}
```

## 👥 Authors

- **Israel Goytom** - _Initial work_, _RFC Design & Architecture_
- **Synheart AI Team** - _Development & Research_

---

**Made with ❤️ by the Synheart AI Team**

_Technology with a heartbeat._
