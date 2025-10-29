/// Result of emotion inference containing probabilities and metadata
class EmotionResult {
  /// Timestamp when inference was performed
  final DateTime timestamp;
  
  /// Predicted emotion label (top-1)
  final String emotion;
  
  /// Confidence score (top-1 probability)
  final double confidence;
  
  /// All label probabilities
  final Map<String, double> probabilities;
  
  /// Extracted features used for inference
  final Map<String, double> features;
  
  /// Model metadata
  final Map<String, dynamic> model;

  const EmotionResult({
    required this.timestamp,
    required this.emotion,
    required this.confidence,
    required this.probabilities,
    required this.features,
    required this.model,
  });

  /// Create EmotionResult from raw data
  factory EmotionResult.fromInference({
    required DateTime timestamp,
    required Map<String, double> probabilities,
    required Map<String, double> features,
    required Map<String, dynamic> model,
  }) {
    // Find top-1 emotion
    String topEmotion = '';
    double topConfidence = 0.0;
    
    for (final entry in probabilities.entries) {
      if (entry.value > topConfidence) {
        topConfidence = entry.value;
        topEmotion = entry.key;
      }
    }

    return EmotionResult(
      timestamp: timestamp,
      emotion: topEmotion,
      confidence: topConfidence,
      probabilities: Map.unmodifiable(probabilities),
      features: Map.unmodifiable(features),
      model: Map.unmodifiable(model),
    );
  }

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'emotion': emotion,
      'confidence': confidence,
      'probabilities': probabilities,
      'features': features,
      'model': model,
    };
  }

  /// Create from JSON
  factory EmotionResult.fromJson(Map<String, dynamic> json) {
    return EmotionResult(
      timestamp: DateTime.parse(json['timestamp']),
      emotion: json['emotion'],
      confidence: json['confidence'].toDouble(),
      probabilities: Map<String, double>.from(json['probabilities']),
      features: Map<String, double>.from(json['features']),
      model: Map<String, dynamic>.from(json['model']),
    );
  }

  @override
  String toString() {
    return 'EmotionResult($emotion: ${(confidence * 100).toStringAsFixed(1)}%, '
           'features: ${features.keys.join(', ')})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmotionResult &&
        other.timestamp == timestamp &&
        other.emotion == emotion &&
        other.confidence == confidence &&
        _mapEquals(other.probabilities, probabilities) &&
        _mapEquals(other.features, features) &&
        _mapEquals(other.model, model);
  }

  @override
  int get hashCode {
    return Object.hash(
      timestamp,
      emotion,
      confidence,
      probabilities,
      features,
      model,
    );
  }

  bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}
