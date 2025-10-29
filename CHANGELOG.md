# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-28

### Added
- Initial release of synheart-emotion library
- Core emotion inference engine with sliding window buffering
- Support for three emotion states: Amused, Calm, Stressed
- Feature extraction from heart rate and RR intervals (HR mean, SDNN, RMSSD)
- **Real WESAD-trained Linear SVM model** with 78% accuracy
- One-vs-rest classification with softmax probability output
- Configurable inference parameters (window size, step size, min RR count)
- Real-time streaming API via `EmotionStream`
- **JSON model loader** for loading trained models from assets
- Comprehensive test suite with unit tests and performance benchmarks (31 tests)
- Example app demonstrating integration with wearable devices
- **JSON model example** showing asset-based model loading
- Complete documentation (RFC-E1.1, MODEL_CARD, README, CONTRIBUTING)
- GitHub Actions CI/CD pipeline
- Strict linting with analysis_options.yaml

### Changed
- **Model weights**: Replaced placeholder weights with real WESAD-trained parameters
- **Model ID**: Updated from `svm_linear_wrist_sdnn_v1_0_PLACEHOLDER` to `wesad_emotion_v1_0`
- **Model version**: Updated from `1.0-demo` to `1.0`
- **Normalization parameters**: Updated to WESAD dataset statistics
- **Documentation**: Updated README to reflect real model usage and accuracy metrics

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
- Limited to three emotion classes
- Requires minimum 30 RR intervals (configurable) for inference
- JSON model loading requires Flutter asset bundling

### Dependencies
- Flutter >=3.10.0
- Dart SDK >=3.0.0 <4.0.0
- No external package dependencies (beyond Flutter SDK)

### Performance
- HR mean calculation: 0.008ms average
- SDNN calculation: 0.007ms average
- RMSSD calculation: 0.002ms average
- Full feature extraction: 0.006ms average
- Model inference: 0.008ms average
- Full inference cycle: 0.010ms average
- All metrics well under <5ms target latency

[0.1.0]: https://github.com/synheart-ai/synheart-emotion/releases/tag/v0.1.0
