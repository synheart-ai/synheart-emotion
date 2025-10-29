import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'emotion_error.dart';
import 'features.dart';

/// JSON-based Linear SVM model loader
/// 
/// Loads trained models from JSON assets following the SWIP model format
class JsonLinearModel {
  final String type;
  final String version;
  final String modelId;
  final List<String> featureOrder;
  final List<String> classes;
  final List<double> scalerMean;
  final List<double> scalerStd;
  final List<List<double>> weights;
  final List<double> bias;
  final Map<String, dynamic> inference;
  final Map<String, dynamic> training;
  final String? modelHash;
  final String? exportTimeUtc;
  final String? trainingCommit;
  final String? dataManifestId;

  JsonLinearModel({
    required this.type,
    required this.version,
    required this.modelId,
    required this.featureOrder,
    required this.classes,
    required this.scalerMean,
    required this.scalerStd,
    required this.weights,
    required this.bias,
    required this.inference,
    required this.training,
    this.modelHash,
    this.exportTimeUtc,
    this.trainingCommit,
    this.dataManifestId,
  });

  /// Load model from JSON asset
  static Future<JsonLinearModel> loadFromAsset(String assetPath) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return JsonLinearModel.fromJson(jsonData);
    } catch (e) {
      throw EmotionError.badInput('Failed to load model from asset: $e');
    }
  }

  /// Create model from JSON data
  factory JsonLinearModel.fromJson(Map<String, dynamic> json) {
    final scaler = json['scaler'] as Map<String, dynamic>;
    
    return JsonLinearModel(
      type: json['type'] as String,
      version: json['version'] as String,
      modelId: json['model_id'] as String,
      featureOrder: List<String>.from(json['feature_order'] as List),
      classes: List<String>.from(json['classes'] as List),
      scalerMean: List<double>.from(scaler['mean'] as List),
      scalerStd: List<double>.from(scaler['std'] as List),
      weights: (json['weights'] as List).map((w) => List<double>.from(w as List)).toList(),
      bias: List<double>.from(json['bias'] as List),
      inference: Map<String, dynamic>.from(json['inference'] as Map? ?? {}),
      training: Map<String, dynamic>.from(json['training'] as Map? ?? {}),
      modelHash: json['model_hash'] as String?,
      exportTimeUtc: json['export_time_utc'] as String?,
      trainingCommit: json['training_commit'] as String?,
      dataManifestId: json['data_manifest_id'] as String?,
    );
  }

  /// Predict emotion probabilities from features
  Map<String, double> predict(Map<String, double> features) {
    // Extract feature vector in correct order
    final featureVector = _extractFeatureVector(features);
    
    // Normalize features using z-score
    final normalizedFeatures = _normalizeFeatures(featureVector);
    
    // Compute scores for each class (One-vs-Rest)
    final scores = _computeScores(normalizedFeatures);
    
    // Convert scores to probabilities
    final probabilities = _computeProbabilities(scores);
    
    // Convert to map with class names
    final result = <String, double>{};
    for (int i = 0; i < classes.length; i++) {
      result[classes[i]] = probabilities[i];
    }
    
    return result;
  }

  /// Extract feature vector in the correct order
  List<double> _extractFeatureVector(Map<String, double> features) {
    final featureVector = <double>[];
    
    for (final featureName in featureOrder) {
      if (!features.containsKey(featureName)) {
        throw EmotionError.badInput('Missing required feature: $featureName');
      }
      featureVector.add(features[featureName]!);
    }
    
    return featureVector;
  }

  /// Normalize features using z-score normalization
  List<double> _normalizeFeatures(List<double> features) {
    final normalized = <double>[];
    for (int i = 0; i < features.length; i++) {
      final mean = i < scalerMean.length ? scalerMean[i] : 0.0;
      final std = i < scalerStd.length ? scalerStd[i] : 1.0;
      final normalizedValue = (features[i] - mean) / std;
      normalized.add(normalizedValue.isNaN ? 0.0 : normalizedValue);
    }
    return normalized;
  }

  /// Compute SVM scores for each class (One-vs-Rest)
  List<double> _computeScores(List<double> normalizedFeatures) {
    final scores = <double>[];
    
    for (int classIndex = 0; classIndex < weights.length; classIndex++) {
      final classWeights = weights[classIndex];
      final classBias = bias[classIndex];
      
      // Compute dot product: w · x + b
      double score = classBias;
      for (int i = 0; i < normalizedFeatures.length && i < classWeights.length; i++) {
        score += classWeights[i] * normalizedFeatures[i];
      }
      
      scores.add(score);
    }
    
    return scores;
  }

  /// Convert scores to probabilities using softmax
  List<double> _computeProbabilities(List<double> scores) {
    final scoreFn = inference['score_fn'] as String? ?? 'softmax';
    final temperature = (inference['temperature'] as num?)?.toDouble() ?? 1.0;
    
    switch (scoreFn) {
      case 'softmax':
        return _softmax(scores, temperature);
      case 'sigmoid':
        return _sigmoid(scores);
      default:
        return _softmax(scores, temperature);
    }
  }

  /// Apply softmax with temperature scaling
  List<double> _softmax(List<double> scores, double temperature) {
    // Scale by temperature
    final scaledScores = scores.map((s) => s / temperature).toList();
    
    // Find maximum for numerical stability
    final maxScore = scaledScores.reduce(max);
    
    // Compute exponentials
    final exponentials = scaledScores.map((score) => exp(score - maxScore)).toList();
    
    // Compute sum
    final sum = exponentials.reduce((a, b) => a + b);
    
    // Normalize to probabilities
    return exponentials.map((exp) => exp / sum).toList();
  }

  /// Apply sigmoid to each score
  List<double> _sigmoid(List<double> scores) {
    return scores.map((score) => 1.0 / (1.0 + exp(-score))).toList();
  }

  /// Get model information
  Map<String, dynamic> getModelInfo() {
    return {
      'id': modelId,
      'version': version,
      'type': type,
      'labels': classes,
      'feature_names': featureOrder,
      'num_classes': classes.length,
      'num_features': featureOrder.length,
      'training': training,
      'model_hash': modelHash,
      'export_time_utc': exportTimeUtc,
    };
  }

  /// Validate model integrity
  bool validate() {
    // Check basic structure
    if (featureOrder.length != scalerMean.length || 
        featureOrder.length != scalerStd.length) {
      return false;
    }
    
    if (weights.length != classes.length || 
        bias.length != classes.length) {
      return false;
    }
    
    // Check weights dimensions
    for (final weightVector in weights) {
      if (weightVector.length != featureOrder.length) {
        return false;
      }
    }
    
    return true;
  }

  /// Get model performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'accuracy': training['accuracy'],
      'balanced_accuracy': training['balanced_accuracy'],
      'f1_score': training['f1_score'],
      'dataset': training['dataset'],
      'subjects': training['subjects'],
      'windows': training['windows'],
    };
  }
}
