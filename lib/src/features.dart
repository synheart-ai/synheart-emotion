import 'dart:math';

/// Feature extraction utilities for emotion inference
class FeatureExtractor {
  /// Extract HR mean from a list of HR values
  static double extractHrMean(List<double> hrValues) {
    if (hrValues.isEmpty) return 0.0;
    return hrValues.reduce((a, b) => a + b) / hrValues.length;
  }

  /// Extract SDNN (standard deviation of NN intervals) from RR intervals
  static double extractSdnn(List<double> rrIntervalsMs) {
    if (rrIntervalsMs.length < 2) return 0.0;
    
    // Clean RR intervals (remove outliers)
    final cleaned = _cleanRrIntervals(rrIntervalsMs);
    if (cleaned.length < 2) return 0.0;
    
    // Calculate standard deviation (sample std, N-1 denominator)
    final mean = cleaned.reduce((a, b) => a + b) / cleaned.length;
    final variance = cleaned.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / (cleaned.length - 1);
    return sqrt(variance);
  }

  /// Extract RMSSD (root mean square of successive differences) from RR intervals
  static double extractRmssd(List<double> rrIntervalsMs) {
    if (rrIntervalsMs.length < 2) return 0.0;
    
    // Clean RR intervals
    final cleaned = _cleanRrIntervals(rrIntervalsMs);
    if (cleaned.length < 2) return 0.0;
    
    // Calculate successive differences
    double sumSquaredDiffs = 0.0;
    for (int i = 1; i < cleaned.length; i++) {
      final diff = cleaned[i] - cleaned[i - 1];
      sumSquaredDiffs += diff * diff;
    }
    
    // Root mean square
    return sqrt(sumSquaredDiffs / (cleaned.length - 1));
  }

  /// Extract all features for emotion inference
  static Map<String, double> extractFeatures({
    required List<double> hrValues,
    required List<double> rrIntervalsMs,
    Map<String, double>? motion,
  }) {
    final features = <String, double>{
      'hr_mean': extractHrMean(hrValues),
      'sdnn': extractSdnn(rrIntervalsMs),
      'rmssd': extractRmssd(rrIntervalsMs),
    };

    // Add motion features if provided
    if (motion != null) {
      features.addAll(motion);
    }

    return features;
  }

  /// Clean RR intervals by removing outliers
  static List<double> _cleanRrIntervals(List<double> rrIntervalsMs) {
    if (rrIntervalsMs.isEmpty) return [];
    
    final cleaned = <double>[];
    double? prevValue;
    
    for (final rr in rrIntervalsMs) {
      // Skip outliers: < 300ms or > 2000ms
      if (rr < 300 || rr > 2000) continue;
      
      // Skip large jumps: > 250ms difference from previous
      if (prevValue != null && (rr - prevValue).abs() > 250) continue;
      
      cleaned.add(rr);
      prevValue = rr;
    }
    
    return cleaned;
  }

  /// Validate feature vector for model compatibility
  static bool validateFeatures(Map<String, double> features, List<String> requiredFeatures) {
    for (final feature in requiredFeatures) {
      if (!features.containsKey(feature)) return false;
      if (features[feature]!.isNaN || features[feature]!.isInfinite) return false;
    }
    return true;
  }

  /// Normalize features using training statistics
  static Map<String, double> normalizeFeatures(
    Map<String, double> features,
    Map<String, double> mu,
    Map<String, double> sigma,
  ) {
    final normalized = <String, double>{};
    
    for (final entry in features.entries) {
      final featureName = entry.key;
      final value = entry.value;
      
      if (mu.containsKey(featureName) && sigma.containsKey(featureName)) {
        final mean = mu[featureName]!;
        final std = sigma[featureName]!;
        
        // Avoid division by zero
        if (std > 0) {
          normalized[featureName] = (value - mean) / std;
        } else {
          normalized[featureName] = 0.0;
        }
      } else {
        // Keep original value if no normalization params
        normalized[featureName] = value;
      }
    }
    
    return normalized;
  }
}
