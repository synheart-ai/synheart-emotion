import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:path_provider/path_provider.dart';

import 'emotion_error.dart';

/// ONNX-based model loader for emotion inference.
///
/// Loads and runs ONNX models with metadata from accompanying meta.json files.
class OnnxEmotionModel {
  final String modelId;
  final List<String> inputNames;
  final List<String> classNames;
  final OrtSession _session;
  final Map<String, dynamic> _metadata;

  OnnxEmotionModel._({
    required this.modelId,
    required this.inputNames,
    required this.classNames,
    required OrtSession session,
    required Map<String, dynamic> metadata,
  })  : _session = session,
        _metadata = metadata;

  /// Load ONNX model from assets
  static Future<OnnxEmotionModel> loadFromAsset({
    required String modelAssetPath,
    required String metaAssetPath,
  }) async {
    try {
      // Load metadata
      final metaString = await rootBundle.loadString(metaAssetPath);
      final metadata = json.decode(metaString) as Map<String, dynamic>;

      final modelId = metadata['model_id'] as String;
      final schema = metadata['schema'] as Map<String, dynamic>;
      final inputNames = List<String>.from(schema['input_names'] as List);
      final output = metadata['output'] as Map<String, dynamic>;
      final classNames = List<String>.from(output['class_names'] as List);

      // Load ONNX model
      final onnxRuntime = OnnxRuntime();
      OrtSession session;

      try {
        if (kIsWeb) {
          // For web, load directly from assets
          session = await onnxRuntime.createSessionFromAsset(modelAssetPath);
        } else {
          // For native platforms, extract asset to temporary file
          final directory = await getTemporaryDirectory();
          final fileName = modelAssetPath.split('/').last;
          final modelPath =
              '${directory.path}${Platform.pathSeparator}$fileName';

          final file = File(modelPath);
          if (!await file.exists()) {
            final byteData = await rootBundle.load(modelAssetPath);
            await file.writeAsBytes(byteData.buffer.asUint8List());
          }

          session = await onnxRuntime.createSession(modelPath);
        }
      } catch (e) {
        throw EmotionError.badInput('Failed to load ONNX model: $e');
      }

      return OnnxEmotionModel._(
        modelId: modelId,
        inputNames: inputNames,
        classNames: classNames,
        session: session,
        metadata: metadata,
      );
    } catch (e) {
      throw EmotionError.badInput('Failed to load ONNX model from asset: $e');
    }
  }

  /// Predict emotion probabilities from features
  ///
  /// Note: This throws an error since ONNX inference is async.
  /// Use predictAsync() instead.
  Map<String, double> predict(Map<String, double> features) {
    throw EmotionError.badInput(
      'ONNX inference requires async. Use predictAsync() instead.',
    );
  }

  /// Predict emotion probabilities from features (async version)
  Future<Map<String, double>> predictAsync(Map<String, double> features) async {
    try {
      // Extract feature vector in the order expected by the model
      final inputVector = _extractFeatureVector(features);

      // Prepare input data as Float32List
      final inputData = Float32List.fromList(inputVector);
      final inputShape = [1, inputNames.length];

      // Create input tensor
      final inputTensor = await OrtValue.fromList(inputData, inputShape);

      // Get input name from session or use default
      final inputName = _session.inputNames.isNotEmpty
          ? _session.inputNames.first
          : 'float_input';

      // Run inference
      final inputs = {inputName: inputTensor};
      final outputs = await _session.run(inputs);

      // ExtraTrees ONNX models output: [label, probabilities] or [probabilities, label]
      // We need to find the output with key "probabilities"
      List<double> probabilities;
      
      if (outputs.length >= 2) {
        // Model has both label and probabilities outputs
        // Find the one actually named "probabilities"
        String? probsKey;
        for (final key in outputs.keys) {
          if (key.toLowerCase().contains('prob')) {
            probsKey = key;
            break;
          }
        }
        
        if (probsKey == null) {
          throw EmotionError.badInput('Could not find probabilities output');
        }
        
        final probsValue = outputs[probsKey]!;
        final probsData = await probsValue.asList();
        
        // Handle the shape (1, 3) - first dimension is batch, second is classes
        if (probsData is List && probsData.isNotEmpty) {
          if (probsData[0] is List) {
            // Nested list [[p1, p2, p3]] - extract inner list
            final innerList = probsData[0] as List;
            probabilities = innerList.map((e) => (e as num).toDouble()).toList();
          } else {
            // Flat list [p1, p2, p3] - use directly
            probabilities = probsData.map((e) => (e as num).toDouble()).toList();
          }
        } else {
          throw EmotionError.badInput('Unexpected probabilities structure: empty or invalid');
        }
      } else {
        // Fallback: use first output (shouldn't happen with ExtraTrees)
        final outputKey = outputs.keys.first;
        final outputValue = outputs[outputKey]!;
        final outputData = await outputValue.asList();
        
        if (outputData is List && outputData.isNotEmpty) {
          if (outputData[0] is List) {
            final innerList = outputData[0] as List;
            probabilities = innerList.map((e) => (e as num).toDouble()).toList();
          } else {
            probabilities = outputData.map((e) => (e as num).toDouble()).toList();
          }
        } else {
          throw EmotionError.badInput('Unexpected output structure');
        }
      }

      // Release resources
      await inputTensor.dispose();
      // Output tensors are automatically managed

      // Convert to map with class names
      final result = <String, double>{};
      for (int i = 0; i < classNames.length && i < probabilities.length; i++) {
        result[classNames[i]] = probabilities[i];
      }

      return result;
    } catch (e) {
      throw EmotionError.badInput('ONNX inference failed: $e');
    }
  }

  /// Extract feature vector in the correct order for the model
  List<double> _extractFeatureVector(Map<String, double> features) {
    final featureVector = <double>[];

    // Map feature names (case-insensitive)
    final featureMap = <String, double>{};
    for (final entry in features.entries) {
      featureMap[entry.key.toLowerCase()] = entry.value;
    }

    for (final inputName in inputNames) {
      final key = inputName.toLowerCase();

      // Handle different naming conventions
      double? value;
      if (key == 'sdnn') {
        value = featureMap['sdnn'];
      } else if (key == 'rmssd') {
        value = featureMap['rmssd'];
      } else if (key == 'pnn50') {
        value = featureMap['pnn50'];
      } else if (key == 'mean_rr') {
        value = featureMap['mean_rr'];
      } else if (key == 'hr_mean') {
        value = featureMap['hr_mean'];
      } else {
        value = featureMap[key];
      }

      if (value == null) {
        throw EmotionError.badInput('Missing required feature: $inputName');
      }

      featureVector.add(value);
    }

    return featureVector;
  }

  /// Get model metadata
  Map<String, dynamic> getMetadata() => {
        'id': modelId,
        'type': 'onnx',
        'labels': classNames,
        'feature_names': inputNames,
        'num_classes': classNames.length,
        'num_features': inputNames.length,
        'format': _metadata['format'],
        'created_utc': _metadata['created_utc'],
      };

  /// Validate model integrity
  bool validate() {
    try {
      if (inputNames.isEmpty) {
        return false;
      }
      if (classNames.isEmpty) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get feature names (for compatibility with LinearSvmModel interface)
  List<String> get featureNames => inputNames;

  /// Get labels (for compatibility with LinearSvmModel interface)
  List<String> get labels => classNames;

  /// Release resources
  Future<void> dispose() async {
    try {
      await _session.close();
    } catch (e) {
      // Ignore close errors
    }
  }
}
