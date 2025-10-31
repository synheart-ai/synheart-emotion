# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Enhanced model variants and configurations
- Additional emotion classes
- Performance optimizations
- Expanded platform support

## [0.1.0] - 2025-01-30

This release includes synchronized versions across all platforms. All SDKs are at version 0.1.0.

### Added

#### Multi-Platform SDK Support
- **Flutter/Dart SDK**: Primary SDK for Flutter applications
  - Published to pub.dev as `synheart_emotion`
  - Full API parity with all features
  - Asset-based model loading support
  
- **Python SDK**: Cross-platform Python package
  - Published to PyPI as `synheart-emotion`
  - Installable via `pip install synheart-emotion`
  - Complete feature implementation with NumPy/Pandas
  
- **Android SDK**: Kotlin library for Android applications
  - Published to Maven Central as `ai.synheart:emotion`
  - Minimum SDK 21 (Android 5.0+)
  - Coroutines support for async operations
  
- **iOS SDK**: Swift package for iOS/macOS/watchOS/tvOS
  - Available via Swift Package Manager
  - Published to CocoaPods as `SynheartEmotion`
  - Supports iOS 13.0+, macOS 10.15+, watchOS 6.0+, tvOS 13.0+

#### Core Features
- Core emotion inference engine with sliding window buffering
- Support for three emotion states: Amused, Calm, Stressed
- Feature extraction from heart rate and RR intervals (HR mean, SDNN, RMSSD)
- **Real WESAD-trained Linear SVM model** with 78% accuracy
- One-vs-rest classification with softmax probability output
- Configurable inference parameters (window size, step size, min RR count)
- Real-time streaming API via `EmotionStream` (Flutter)
- **JSON model loader** for loading trained models from assets
- Comprehensive test suite with unit tests and performance benchmarks
- Example applications for each platform
- Complete documentation (RFC-E1.1, MODEL_CARD, README, CONTRIBUTING)

#### Publishing Infrastructure
- GitHub Actions workflows for automated publishing:
  - Flutter → pub.dev (OIDC trusted publishing)
  - Python → PyPI (OIDC trusted publishing)
  - Android → Maven Central (with GPG signing)
  - iOS → Swift Package Manager + CocoaPods
- Automated CI/CD pipeline with tests and validation
- Version management across all SDKs
- Publishing documentation and guides

### Changed
- **Repository structure**: Restructured into monorepo with separate SDKs and examples directories
- **Model weights**: Replaced placeholder weights with real WESAD-trained parameters
- **Model ID**: Updated from `svm_linear_wrist_sdnn_v1_0_PLACEHOLDER` to `wesad_emotion_v1_0`
- **Model version**: Updated from `1.0-demo` to `1.0`
- **Normalization parameters**: Updated to WESAD dataset statistics
- **Documentation**: Updated README to reflect multi-platform SDKs, publishing setup, and real model usage

### Architectural Decisions
- **No built-in storage**: Library focuses on emotion inference only
  - Users can implement their own storage using preferred methods
  - Reduces dependencies and security concerns
  - Provides flexibility for different storage requirements
- **Privacy-first**: All processing happens on-device, no network calls
- **Minimal dependencies**: Only requires Flutter SDK
- **Asset-based models**: Support for loading JSON models from Flutter assets
- **SWIP SDK compatibility**: Follows SWIP SDK model format and architecture patterns

### Security Notes
- **✅ Real trained model**: Default SVM weights are trained on WESAD dataset
- **Production ready**: Model achieves 78% accuracy on validation data
- **Data storage**: Not included - implement your own secure storage as needed

### Model Performance
- **Dataset**: WESAD (15 subjects, 1200 windows)
- **Accuracy**: 78% on 3-class emotion recognition
- **Balanced Accuracy**: 76%
- **F1-Score**: 75%
- **Features**: HR mean, SDNN, RMSSD
- **Classes**: Amused, Calm, Stressed

### Known Limitations
- Limited to three emotion classes (Amused, Calm, Stressed)
- Requires minimum 30 RR intervals (configurable) for inference
- JSON model loading requires platform-specific asset bundling
- Android: Manual staging repository release required after publishing workflow

### Dependencies

#### Flutter SDK
- Flutter >=3.10.0
- Dart SDK >=3.0.0 <4.0.0
- No external package dependencies (beyond Flutter SDK)

#### Python SDK
- Python >=3.8
- NumPy >=1.21.0
- Pandas >=1.3.0
- Optional: scikit-learn, joblib, xgboost (for ML features)

#### Android SDK
- Android API 21+ (Android 5.0 Lollipop)
- Kotlin 1.8+
- AndroidX Core KTX
- Kotlin Coroutines

#### iOS SDK
- iOS 13.0+ / macOS 10.15+ / watchOS 6.0+ / tvOS 13.0+
- Swift 5.0+
- No external dependencies

### Performance
- HR mean calculation: 0.008ms average
- SDNN calculation: 0.007ms average
- RMSSD calculation: 0.002ms average
- Full feature extraction: 0.006ms average
- Model inference: 0.008ms average
- Full inference cycle: 0.010ms average
- All metrics well under <5ms target latency (measured on mid-range devices)

### Installation

#### Flutter
```yaml
dependencies:
  synheart_emotion: ^0.1.0
```

#### Python
```bash
pip install synheart-emotion
```

#### Android
```kotlin
dependencies {
    implementation("ai.synheart:emotion:0.1.0")
}
```

#### iOS
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

### Publishing Information
- **Flutter**: Published to [pub.dev](https://pub.dev/packages/synheart_emotion)
- **Python**: Published to [PyPI](https://pypi.org/project/synheart-emotion/)
- **Android**: Published to [Maven Central](https://central.sonatype.com/artifact/ai.synheart/emotion)
- **iOS**: Available via [Swift Package Manager](https://github.com/synheart-ai/synheart-emotion) and [CocoaPods](https://cocoapods.org/pods/SynheartEmotion)

### Acknowledgments
- WESAD dataset for training data
- All contributors and testers

[0.1.0]: https://github.com/synheart-ai/synheart-emotion/releases/tag/v0.1.0
