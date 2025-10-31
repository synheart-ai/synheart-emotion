# Examples Directory

This directory contains example applications demonstrating how to use the Synheart Emotion SDKs.

## Overview

The examples showcase different integration patterns and use cases for emotion inference from biosignals. Each example is a complete, runnable Flutter application.

## Examples

### main.dart

**Main example application** - A comprehensive demo showing:

- Real-time emotion inference from simulated biometric data
- Live emotion visualization with confidence scores
- Probability distribution display
- Buffer management and statistics
- Logging system demonstration

**Features demonstrated:**
- EmotionEngine initialization and configuration
- Simulated HR and RR interval data generation
- Real-time inference with configurable window and step sizes
- UI updates with emotion results
- Color-coded emotion display

**Run it:**
```bash
cd examples
flutter pub get
flutter run
```

### integration_example.dart

**Integration example** - Shows how to integrate synheart-emotion with synheart-wear:

- Connecting to wearable device streams
- Real-time data streaming to emotion engine
- Processing live biometric data
- Emotion result handling

**Features demonstrated:**
- Integration with synheart-wear SDK
- Stream-based data processing
- Real-world data handling patterns
- Error handling and recovery

**Note**: Requires synheart-wear SDK. Uncomment imports when available.

### json_model_example.dart

**JSON model loading example** - Demonstrates loading models from assets:

- Loading JSON models from Flutter assets
- Custom model initialization
- Asset-based model distribution
- Model validation and error handling

**Features demonstrated:**
- `JsonLinearModel.fromAsset()` usage
- Custom `LinearSvmModel` initialization
- Model metadata inspection
- Asset bundling and loading

**Run it:**
```bash
cd examples
flutter pub get
flutter run --dart-entrypoint-args=json_model
```

## Project Structure

```
examples/
├── lib/
│   ├── main.dart              # Main demo application
│   ├── integration_example.dart  # synheart-wear integration
│   └── json_model_example.dart   # JSON model loading
├── pubspec.yaml              # Example app dependencies
└── README.md                 # This file
```

## Setup

1. **Install dependencies:**
   ```bash
   cd examples
   flutter pub get
   ```

2. **Run an example:**
   ```bash
   flutter run
   ```

3. **Run with specific entry point:**
   ```bash
   # For JSON model example
   flutter run --dart-entrypoint-args=json_model
   ```

## Dependencies

The examples depend on:

- `synheart_emotion`: Path dependency to `../sdks/flutter`
- `flutter`: Flutter SDK
- `cupertino_icons`: For iOS-style icons

## Common Patterns

### Basic Emotion Engine Setup

```dart
final engine = EmotionEngine.fromPretrained(
  const EmotionConfig(
    window: Duration(seconds: 60),
    step: Duration(seconds: 5),
    minRrCount: 30,
  ),
);
```

### Pushing Data

```dart
engine.push(
  hr: 72.0,
  rrIntervalsMs: [823, 810, 798, 815],
  timestamp: DateTime.now().toUtc(),
);
```

### Getting Results

```dart
final results = engine.consumeReady();
for (final result in results) {
  print('Emotion: ${result.emotion}');
  print('Confidence: ${result.confidence}');
  print('Probabilities: ${result.probabilities}');
}
```

### Stream-Based Processing

```dart
final emotionStream = EmotionStream.emotionStream(
  engine,
  tickStream,
);

await for (final result in emotionStream) {
  // Handle emotion result
  updateUI(result);
}
```

## Integration with synheart-wear

The integration example shows how to connect real wearable data:

```dart
import 'package:synheart_wear/synheart_wear.dart';
import 'package:synheart_emotion/synheart_emotion.dart';

final wear = SynheartWear();
final engine = EmotionEngine.fromPretrained(
  const EmotionConfig(),
);

await wear.initialize();

wear.streamHR().listen((metrics) {
  engine.push(
    hr: metrics.hr,
    rrIntervalsMs: metrics.rrIntervals,
    timestamp: DateTime.now().toUtc(),
  );
  
  final emotions = engine.consumeReady();
  for (final emotion in emotions) {
    // Use emotion in your app
  }
});
```

## Customization

You can customize the examples by:

1. **Modifying window and step sizes** in `EmotionConfig`
2. **Adjusting simulation parameters** for data generation
3. **Changing UI colors and layout** for emotion display
4. **Adding custom logging** via `onLog` callback
5. **Implementing storage** for emotion results

## Troubleshooting

### Model Not Loading

If you see errors about model loading:
- Ensure `assets/ml/wesad_emotion_v1_0.json` is in `sdks/flutter/assets/ml/`
- Check that the asset is listed in `sdks/flutter/pubspec.yaml`

### No Results

If no emotion results are returned:
- Ensure you're pushing enough data (minimum 30 RR intervals)
- Check that the window size is appropriate for your data rate
- Verify the step size allows time for inference

### Performance Issues

- Reduce window or step size if inference is too slow
- Clear buffer periodically if memory usage is high
- Check device capabilities (older devices may be slower)

## Next Steps

After running the examples:

1. **Try with real data**: Integrate with synheart-wear or your own data source
2. **Customize UI**: Adapt the examples to your app's design
3. **Add storage**: Implement persistence for emotion results
4. **Integrate with swip-core**: Feed emotions into the SWIP score system

## Resources

- **Flutter SDK Documentation**: [../sdks/flutter/README.md](../sdks/flutter/README.md)
- **RFC Documentation**: [../docs/RFC-E1.1.md](../docs/RFC-E1.1.md)
- **Model Card**: [../docs/MODEL_CARD.md](../docs/MODEL_CARD.md)
- **Main README**: [../README.md](../README.md)

## Contributing Examples

We welcome new examples! When contributing:

1. Add a descriptive file name
2. Include comments explaining the pattern
3. Ensure it runs without errors
4. Update this README with a description
5. Follow the existing code style

Thank you for using Synheart Emotion! 🎉

