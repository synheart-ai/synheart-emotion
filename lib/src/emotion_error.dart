/// Errors that can occur during emotion inference
abstract class EmotionError {
  /// Error message
  final String message;
  
  /// Additional context
  final Map<String, dynamic>? context;

  const EmotionError(this.message, [this.context]);

  /// Too few RR intervals for stable inference
  factory EmotionError.tooFewRR({required int minExpected, required int actual}) {
    return _TooFewRRError(minExpected, actual);
  }

  /// Invalid input data
  factory EmotionError.badInput(String reason) {
    return _BadInputError(reason);
  }

  /// Model incompatible with feature dimensions
  factory EmotionError.modelIncompatible({required int expectedFeats, required int actualFeats}) {
    return _ModelIncompatibleError(expectedFeats, actualFeats);
  }

  /// Feature extraction failed
  factory EmotionError.featureExtractionFailed(String reason) {
    return _FeatureExtractionError(reason);
  }

  @override
  String toString() => 'EmotionError: $message';
}

class _TooFewRRError extends EmotionError {
  final int minExpected;
  final int actual;

  _TooFewRRError(this.minExpected, this.actual) 
      : super('Too few RR intervals: expected at least $minExpected, got $actual',
              {'minExpected': minExpected, 'actual': actual});
}

class _BadInputError extends EmotionError {
  _BadInputError(String reason) : super('Bad input: $reason');
}

class _ModelIncompatibleError extends EmotionError {
  final int expectedFeats;
  final int actualFeats;

  _ModelIncompatibleError(this.expectedFeats, this.actualFeats)
      : super('Model incompatible: expected $expectedFeats features, got $actualFeats',
              {'expectedFeats': expectedFeats, 'actualFeats': actualFeats});
}

class _FeatureExtractionError extends EmotionError {
  _FeatureExtractionError(String reason) : super('Feature extraction failed: $reason');
}
