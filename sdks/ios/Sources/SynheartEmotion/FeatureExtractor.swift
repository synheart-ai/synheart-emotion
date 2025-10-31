import Foundation

/// Feature extraction utilities for emotion inference.
///
/// Provides methods for extracting heart rate variability (HRV) metrics
/// from biosignal data, including HR mean, SDNN, and RMSSD.
public enum FeatureExtractor {
    /// Minimum valid RR interval in milliseconds (300ms = 200 BPM).
    public static let minValidRrMs: Double = 300.0

    /// Maximum valid RR interval in milliseconds (2000ms = 30 BPM).
    public static let maxValidRrMs: Double = 2000.0

    /// Maximum allowed jump between successive RR intervals in milliseconds.
    ///
    /// This threshold helps detect and remove artifacts from RR interval data.
    /// A jump > 250ms between consecutive intervals likely indicates noise.
    public static let maxRrJumpMs: Double = 250.0

    /// Minimum heart rate value considered valid (in BPM).
    public static let minValidHr: Double = 30.0

    /// Maximum heart rate value considered valid (in BPM).
    public static let maxValidHr: Double = 300.0

    /// Extract HR mean from a list of HR values.
    ///
    /// Returns 0.0 if the input list is empty.
    public static func extractHrMean(_ hrValues: [Double]) -> Double {
        guard !hrValues.isEmpty else { return 0.0 }
        return hrValues.reduce(0.0, +) / Double(hrValues.count)
    }

    /// Extract SDNN (standard deviation of NN intervals) from RR intervals
    public static func extractSdnn(_ rrIntervalsMs: [Double]) -> Double {
        guard rrIntervalsMs.count >= 2 else { return 0.0 }

        // Clean RR intervals (remove outliers)
        let cleaned = cleanRrIntervals(rrIntervalsMs)
        guard cleaned.count >= 2 else { return 0.0 }

        // Calculate standard deviation (sample std, N-1 denominator)
        let mean = cleaned.reduce(0.0, +) / Double(cleaned.count)
        let variance = cleaned.map { pow($0 - mean, 2) }.reduce(0.0, +) / Double(cleaned.count - 1)
        return sqrt(variance)
    }

    /// Extract RMSSD (root mean square of successive differences) from RR intervals
    public static func extractRmssd(_ rrIntervalsMs: [Double]) -> Double {
        guard rrIntervalsMs.count >= 2 else { return 0.0 }

        // Clean RR intervals
        let cleaned = cleanRrIntervals(rrIntervalsMs)
        guard cleaned.count >= 2 else { return 0.0 }

        // Calculate successive differences
        var sumSquaredDiffs = 0.0
        for i in 1..<cleaned.count {
            let diff = cleaned[i] - cleaned[i - 1]
            sumSquaredDiffs += diff * diff
        }

        // Root mean square
        return sqrt(sumSquaredDiffs / Double(cleaned.count - 1))
    }

    /// Extract all features for emotion inference
    public static func extractFeatures(
        hrValues: [Double],
        rrIntervalsMs: [Double],
        motion: [String: Double]? = nil
    ) -> [String: Double] {
        var features: [String: Double] = [
            "hr_mean": extractHrMean(hrValues),
            "sdnn": extractSdnn(rrIntervalsMs),
            "rmssd": extractRmssd(rrIntervalsMs)
        ]

        // Add motion features if provided
        if let motion = motion {
            features.merge(motion) { _, new in new }
        }

        return features
    }

    /// Clean RR intervals by removing physiologically invalid values and artifacts.
    ///
    /// Removes:
    /// - RR intervals outside valid range (minValidRrMs to maxValidRrMs)
    /// - Large jumps between successive intervals (> maxRrJumpMs)
    ///
    /// Returns filtered list of clean RR intervals.
    public static func cleanRrIntervals(_ rrIntervalsMs: [Double]) -> [Double] {
        guard !rrIntervalsMs.isEmpty else { return [] }

        var cleaned: [Double] = []
        var prevValue: Double?

        for rr in rrIntervalsMs {
            // Skip outliers outside physiological range
            if rr < minValidRrMs || rr > maxValidRrMs {
                continue
            }

            // Skip large jumps that likely indicate artifacts
            if let prev = prevValue, abs(rr - prev) > maxRrJumpMs {
                continue
            }

            cleaned.append(rr)
            prevValue = rr
        }

        return cleaned
    }

    /// Validate feature vector for model compatibility
    public static func validateFeatures(
        _ features: [String: Double],
        requiredFeatures: [String]
    ) -> Bool {
        for feature in requiredFeatures {
            guard let value = features[feature] else { return false }
            if value.isNaN || value.isInfinite { return false }
        }
        return true
    }

    /// Normalize features using training statistics
    public static func normalizeFeatures(
        _ features: [String: Double],
        mu: [String: Double],
        sigma: [String: Double]
    ) -> [String: Double] {
        var normalized: [String: Double] = [:]

        for (featureName, value) in features {
            if let mean = mu[featureName], let std = sigma[featureName] {
                // Avoid division by zero
                normalized[featureName] = std > 0 ? (value - mean) / std : 0.0
            } else {
                // Keep original value if no normalization params
                normalized[featureName] = value
            }
        }

        return normalized
    }
}
