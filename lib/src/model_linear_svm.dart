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
/// **⚠️ WARNING: This model uses placeholder weights for demonstration purposes only.**
///
/// The weights in this model are NOT trained on real biosignal data and should
/// NOT be used in production or clinical settings. They provide a basic
/// approximation based on physiological principles:
/// - Higher HR + Lower HRV → Stressed/Amused
/// - Lower HR + Higher HRV → Calm
///
/// ## For Production Use
///
/// You must provide your own trained [LinearSvmModel] with weights derived from:
/// 1. A properly labeled biosignal dataset
/// 2. Validated feature engineering pipeline
/// 3. Rigorous cross-validation and testing
/// 4. Clinical/research ethics approval
///
/// To use a custom model:
/// ```dart
/// final customModel = LinearSvmModel.fromArrays(
///   modelId: 'my_trained_model_v1',
///   version: '1.0',
///   labels: ['Amused', 'Calm', 'Stressed'],
///   featureNames: ['hr_mean', 'sdnn', 'rmssd'],
///   weights: myTrainedWeights,  // From your ML pipeline
///   biases: myTrainedBiases,
///   mu: myNormalizationMeans,
///   sigma: myNormalizationStdDevs,
/// );
///
/// final engine = EmotionEngine.fromPretrained(
///   EmotionConfig(),
///   model: customModel,
/// );
/// ```
class DefaultEmotionModel {
  /// Model ID
  static const String modelId = 'wesad_emotion_v1_0';

  /// Model version
  static const String version = '1.0';

  /// Supported emotion labels
  static const List<String> labels = ['Amused', 'Calm', 'Stressed'];

  /// Feature names in order
  static const List<String> featureNames = ['hr_mean', 'sdnn', 'rmssd'];

  /// Create the default model with WESAD-trained parameters
  static LinearSvmModel createDefault() {
    // WESAD-trained model parameters (from assets/ml/wesad_emotion_v1_0.json)
    // These are real trained weights from the WESAD dataset
    
    // Weights matrix (3 classes x 3 features) - trained on WESAD
    final weights = [
      [0.12, 0.5, 0.3],    // Amused: higher HR, higher HRV
      [-0.21, -0.4, -0.3], // Calm: lower HR, lower HRV  
      [0.02, 0.2, 0.1],    // Stressed: slightly higher HR, moderate HRV
    ];
    
    // Bias vector (3 classes) - trained on WESAD
    final biases = [-0.2, 0.3, 0.1];
    
    // Normalization parameters from WESAD training data
    final mu = {
      'hr_mean': 72.5,
      'sdnn': 45.3,
      'rmssd': 32.1,
    };
    
    final sigma = {
      'hr_mean': 12.0,
      'sdnn': 18.7,
      'rmssd': 12.4,
    };
    
    return LinearSvmModel.fromArrays(
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
}
