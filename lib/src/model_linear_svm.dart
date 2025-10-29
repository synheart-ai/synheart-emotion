import 'dart:math';
import 'emotion_error.dart';
import 'features.dart';

/// Linear SVM model for emotion inference
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

  const LinearSvmModel({
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

  /// Get model metadata
  Map<String, dynamic> getMetadata() {
    return {
      'id': modelId,
      'version': version,
      'type': 'linear_svm',
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

/// Default model for emotion inference (v1.0)
class DefaultEmotionModel {
  /// Model ID
  static const String modelId = 'svm_linear_wrist_sdnn_v1_0';
  
  /// Model version
  static const String version = '1.0';
  
  /// Supported emotion labels
  static const List<String> labels = ['Amused', 'Calm', 'Stressed'];
  
  /// Feature names in order
  static const List<String> featureNames = ['hr_mean', 'sdnn', 'rmssd'];
  
  /// Create the default model with embedded parameters
  static LinearSvmModel createDefault() {
    // These would be replaced with actual trained model parameters
    // For now, using placeholder values that create reasonable behavior
    
    // Weights matrix (3 classes x 3 features)
    final weights = [
      [0.1, -0.05, -0.02],  // Amused: higher HR, lower HRV
      [-0.1, 0.1, 0.1],     // Calm: lower HR, higher HRV
      [0.2, -0.1, -0.05],   // Stressed: higher HR, lower HRV
    ];
    
    // Bias vector (3 classes)
    final biases = [0.0, 0.0, 0.0];
    
    // Normalization parameters (would come from training data)
    final mu = {
      'hr_mean': 72.0,
      'sdnn': 45.0,
      'rmssd': 35.0,
    };
    
    final sigma = {
      'hr_mean': 15.0,
      'sdnn': 20.0,
      'rmssd': 15.0,
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
