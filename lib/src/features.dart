import 'dart:math';

/// Feature extraction utilities for emotion inference.
///
/// Provides methods for extracting heart rate variability (HRV) metrics
/// from biosignal data, including HR mean, SDNN, and RMSSD.
class FeatureExtractor {
  /// Minimum valid RR interval in milliseconds (300ms = 200 BPM).
  static const double minValidRrMs = 300.0;

  /// Maximum valid RR interval in milliseconds (2000ms = 30 BPM).
  static const double maxValidRrMs = 2000.0;

  /// Maximum allowed jump between successive RR intervals in milliseconds.
  ///
  /// This threshold helps detect and remove artifacts from RR interval data.
  /// A jump > 250ms between consecutive intervals likely indicates noise.
  static const double maxRrJumpMs = 250.0;

  /// Minimum heart rate value considered valid (in BPM).
  static const double minValidHr = 30.0;

  /// Maximum heart rate value considered valid (in BPM).
  static const double maxValidHr = 300.0;

  /// Extract HR mean from a list of HR values.
  ///
  /// Returns 0.0 if the input list is empty.
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

  /// Extract pNN50 (percentage of successive RR intervals differing by more than 50ms)
  static double extractPnn50(List<double> rrIntervalsMs) {
    if (rrIntervalsMs.length < 2) return 0.0;
    
    // Clean RR intervals
    final cleaned = _cleanRrIntervals(rrIntervalsMs);
    if (cleaned.length < 2) return 0.0;
    
    // Count successive differences > 50ms
    int count = 0;
    for (int i = 1; i < cleaned.length; i++) {
      if ((cleaned[i] - cleaned[i - 1]).abs() > 50.0) {
        count++;
      }
    }
    
    // Return percentage
    return (count / (cleaned.length - 1)) * 100.0;
  }

  /// Extract Mean RR interval from RR intervals
  static double extractMeanRr(List<double> rrIntervalsMs) {
    if (rrIntervalsMs.isEmpty) return 0.0;
    
    // Clean RR intervals
    final cleaned = _cleanRrIntervals(rrIntervalsMs);
    if (cleaned.isEmpty) return 0.0;
    
    return cleaned.reduce((a, b) => a + b) / cleaned.length;
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
      'pnn50': extractPnn50(rrIntervalsMs),
      'mean_rr': extractMeanRr(rrIntervalsMs),
    };

    // Add motion features if provided
    if (motion != null) {
      features.addAll(motion);
    }

    return features;
  }

  /// Clean RR intervals by removing physiologically invalid values and artifacts.
  ///
  /// Removes:
  /// - RR intervals outside valid range ([minValidRrMs] to [maxValidRrMs])
  /// - Large jumps between successive intervals (> [maxRrJumpMs])
  ///
  /// Returns filtered list of clean RR intervals.
  static List<double> _cleanRrIntervals(List<double> rrIntervalsMs) {
    if (rrIntervalsMs.isEmpty) return [];

    final cleaned = <double>[];
    double? prevValue;

    for (final rr in rrIntervalsMs) {
      // Skip outliers outside physiological range
      if (rr < minValidRrMs || rr > maxValidRrMs) continue;

      // Skip large jumps that likely indicate artifacts
      if (prevValue != null && (rr - prevValue).abs() > maxRrJumpMs) {
        continue;
      }

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
