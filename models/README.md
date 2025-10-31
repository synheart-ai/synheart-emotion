# Models Directory

This directory contains model definitions, assets, and configurations for the Synheart Emotion SDKs.

## Overview

This directory contains the **source of truth** for all model files used by the Synheart Emotion SDKs. Models are stored as JSON files containing weights, biases, and normalization parameters.

**Important**: Models in this directory are automatically copied to SDK-specific locations during build/publish processes. You should only edit model files here, not in the SDK directories.

## Model Format

Models are stored in JSON format with the following structure:

```json
{
  "model_id": "wesad_emotion_v1_0",
  "model_version": "1.0",
  "model_type": "linear_svm_ovr",
  "features": ["hr_mean", "sdnn", "rmssd"],
  "labels": ["Amused", "Calm", "Stressed"],
  "weights": [[...], [...], [...]],
  "biases": [...],
  "scaler_mu": [...],
  "scaler_sigma": [...]
}
```

## Current Models

### wesad_emotion_v1_0

- **Type**: Linear SVM (One-vs-Rest)
- **Features**: HR mean, SDNN, RMSSD
- **Labels**: Amused, Calm, Stressed
- **Accuracy**: ~78% on WESAD validation set
- **Location**: 
  - Source: `models/wesad_emotion_v1_0.json` (this directory)
  - Flutter: Copied to `sdks/flutter/assets/ml/` during build
  - Python: Copied to `sdks/python/src/synheart_emotion/data/` during build
  - Android/iOS: Currently use embedded models (can be extended to load from JSON)

## Model Usage

### Flutter SDK

Models are bundled as Flutter assets. See the Flutter SDK documentation for loading models:

```dart
final model = await JsonLinearModel.fromAsset('assets/ml/wesad_emotion_v1_0.json');
final engine = EmotionEngine.fromPretrained(
  const EmotionConfig(),
  model: LinearSvmModel.fromJsonModel(model),
);
```

## Model Training

Models are trained using the tools in `tools/python-cli/`. The training pipeline:

1. Processes WESAD dataset
2. Extracts HRV features (HR mean, SDNN, RMSSD)
3. Trains Linear SVM with One-vs-Rest strategy
4. Exports model to JSON format for SDK consumption

See `tools/python-cli/README.md` for training instructions.

## Model Distribution to SDKs

Models from this directory are automatically copied to SDK-specific locations:

### Automatic Copying

**During Build/Publish:**
- **Flutter**: Models copied to `sdks/flutter/assets/ml/` by GitHub Actions
- **Python**: Models copied to `sdks/python/src/synheart_emotion/data/` by GitHub Actions
- **Android/iOS**: Currently use embedded models in code (JSON loading can be added)

**Local Development:**
Run the copy script before building SDKs:
```bash
# Using shell script
./scripts/copy-models.sh

# Or using Python script
python scripts/copy-models.py
```

### SDK Model Locations

- **Flutter**: `sdks/flutter/assets/ml/*.json` (referenced in `pubspec.yaml`)
- **Python**: `sdks/python/src/synheart_emotion/data/*.json` (included via `MANIFEST.in`)
- **Android**: Currently embedded (could be `res/raw/*.json` for JSON loading)
- **iOS**: Currently embedded (could be `Resources/*.json` for JSON loading)

## Adding New Models

To add a new model:

1. **Train the model** using the Python CLI tools (or other training pipeline)
2. **Export to JSON format** matching the expected schema
3. **Place the JSON file** in this directory (`models/`)
4. **Run copy script** to distribute to SDKs: `./scripts/copy-models.sh`
5. **Update model loading code** if needed (for SDKs that support JSON loading)
6. **Document the model** in this README
7. **Test** that all SDKs can load the new model

## Model Versioning

Models follow semantic versioning:
- **Major version**: Breaking changes (different feature set, label set)
- **Minor version**: Improved accuracy, new optimizations
- **Patch version**: Bug fixes, minor improvements

Model IDs follow the pattern: `{dataset}_{task}_v{major}.{minor}`

Example: `wesad_emotion_v1_0`

## Model Cards

For detailed model information, see the [Model Card](../docs/MODEL_CARD.md).

## Future Models

Planned model additions:

- **Personalized models**: User-specific calibration
- **Extended label sets**: Additional emotion categories (Focused, Fatigued)
- **Multi-modal models**: Incorporating motion/activity data
- **Alternative architectures**: TFLite/ONNX models for better portability

## License

Models are licensed under the same MIT License as the rest of the project. Model weights derived from WESAD dataset follow the original dataset's licensing terms.

## References

- WESAD Dataset: [Link](https://www.uni-augsburg.de/en/fakultaet/fai/informatik/prof/hem/datensatze-und-tools/wesad/)
- Model Card: [docs/MODEL_CARD.md](../docs/MODEL_CARD.md)
- Training Tools: [tools/python-cli/README.md](../tools/python-cli/README.md)

