import 'dart:math';
import 'emotion_error.dart';
import 'features.dart';

/// Linear SVM model with weights embedded in Dart code.
///
/// This is the original embedded model format that stores weights
/// directly in Dart code. For loading models from assets, use
/// [JsonLinearModel] instead.
///
/// This class is maintained for backwards compatibility and for
/// cases where you want to embed small models directly in code.
class LinearSvmModel {

  /// Model identifier
  final String modelId;

  /// Model version
  final String version;

  /// Supported emotion labels
  final List<String> labels;

  /// Feature names in order
  final List<String> featureNames;
  
  /// SVM weights matrix (C x F where C=classes, F=features)
  final List<List<double>> weights;
  
  /// SVM bias vector (C classes)
  final List<double> biases;
  
  /// Feature normalization means
  final Map<String, double> mu;
  
  /// Feature normalization standard deviations
  final Map<String, double> sigma;

  LinearSvmModel({
    required this.modelId,
    required this.version,
    required this.labels,
    required this.featureNames,
    required this.weights,
    required this.biases,
    required this.mu,
    required this.sigma,
  });

  /// Create model from arrays (embedded in Dart)
  factory LinearSvmModel.fromArrays({
    required String modelId,
    required String version,
    required List<String> labels,
    required List<String> featureNames,
    required List<List<double>> weights,
    required List<double> biases,
    required Map<String, double> mu,
    required Map<String, double> sigma,
  }) {
    // Validate dimensions
    if (weights.length != labels.length) {
      throw ArgumentError('Weights length (${weights.length}) must match labels length (${labels.length})');
    }
    if (biases.length != labels.length) {
      throw ArgumentError('Biases length (${biases.length}) must match labels length (${labels.length})');
    }
    if (weights.isNotEmpty && weights.first.length != featureNames.length) {
      throw ArgumentError('Weight feature dimension (${weights.first.length}) must match feature names length (${featureNames.length})');
    }

    return LinearSvmModel(
      modelId: modelId,
      version: version,
      labels: labels,
      featureNames: featureNames,
      weights: weights,
      biases: biases,
      mu: mu,
      sigma: sigma,
    );
  }

  /// Predict emotion probabilities from features
  Map<String, double> predict(Map<String, double> features) {
    // Validate input features
    if (!FeatureExtractor.validateFeatures(features, featureNames)) {
      throw EmotionError.badInput('Invalid features: missing required features or NaN values');
    }

    // Normalize features
    final normalizedFeatures = FeatureExtractor.normalizeFeatures(features, mu, sigma);
    
    // Extract feature vector in correct order
    final featureVector = <double>[];
    for (final featureName in featureNames) {
      if (!normalizedFeatures.containsKey(featureName)) {
        throw EmotionError.badInput('Missing required feature: $featureName');
      }
      featureVector.add(normalizedFeatures[featureName]!);
    }

    // Calculate SVM margins: W·x + b
    final margins = <double>[];
    for (int i = 0; i < labels.length; i++) {
      double margin = biases[i];
      for (int j = 0; j < featureVector.length; j++) {
        margin += weights[i][j] * featureVector[j];
      }
      margins.add(margin);
    }

    // Apply softmax to get probabilities
    return _softmax(margins, labels);
  }

  /// Apply softmax function to convert margins to probabilities
  Map<String, double> _softmax(List<double> margins, List<String> labels) {
    // Find maximum margin for numerical stability
    final maxMargin = margins.reduce(max);
    
    // Calculate exponentials
    final exponentials = margins.map((m) => exp(m - maxMargin)).toList();
    final sumExp = exponentials.reduce((a, b) => a + b);
    
    // Calculate probabilities
    final probabilities = <String, double>{};
    for (int i = 0; i < labels.length; i++) {
      probabilities[labels[i]] = exponentials[i] / sumExp;
    }
    
    return probabilities;
  }


  /// Get model metadata (deprecated - use info instead)
  @Deprecated('Use info property instead')
  Map<String, dynamic> getMetadata() {
    return {
      'id': modelId,
      'version': version,
      'type': 'embedded',
      'labels': labels,
      'feature_names': featureNames,
      'num_classes': labels.length,
      'num_features': featureNames.length,
    };
  }

  /// Validate model integrity
  bool validate() {
    try {
      // Check dimensions
      if (weights.length != labels.length) return false;
      if (biases.length != labels.length) return false;
      if (weights.isNotEmpty && weights.first.length != featureNames.length) return false;
      
      // Check for NaN or infinite values
      for (final weightRow in weights) {
        for (final weight in weightRow) {
          if (weight.isNaN || weight.isInfinite) return false;
        }
      }
      
      for (final bias in biases) {
        if (bias.isNaN || bias.isInfinite) return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Default model for emotion inference (v1.0).
///
/// Now uses ONNX-based ExtraTrees model trained on WESAD wrist data.
///
/// ## Features
///
/// - Model: ExtraTreesClassifier (ONNX format)
/// - Features: SDNN, RMSSD, pNN50, Mean_RR, HR_mean
/// - Classes: Calm, Stressed, Amused
/// - Dataset: WESAD wrist_all
///
/// ## For Production Use
///
/// To use a custom model:
/// ```dart
/// final customModel = await OnnxEmotionModel.loadFromAsset(
///   modelAssetPath: 'assets/ml/my_model.onnx',
///   metaAssetPath: 'assets/ml/my_model.meta.json',
/// );
///
/// final engine = EmotionEngine.fromPretrained(
///   EmotionConfig(),
///   model: customModel,
/// );
/// ```
class DefaultEmotionModel {
  /// Model ID
  static const String modelId = 'extratrees_wrist_all_v1_0';

  /// Model version
  static const String version = '1.0';

  /// Supported emotion labels
  static const List<String> labels = ['Calm', 'Stressed', 'Amused'];

  /// Feature names in order
  static const List<String> featureNames = ['SDNN', 'RMSSD', 'pNN50', 'Mean_RR', 'HR_mean'];

  // Note: The default model is now loaded asynchronously via loadDefault()
  // This class is kept for backwards compatibility
}
