import Foundation

/// Errors that can occur during emotion inference.
public enum EmotionError: Error {
    /// Too few RR intervals for stable inference
    case tooFewRR(minExpected: Int, actual: Int)

    /// Invalid input data
    case badInput(reason: String)

    /// Model incompatible with feature dimensions
    case modelIncompatible(expectedFeats: Int, actualFeats: Int)

    /// Feature extraction failed
    case featureExtractionFailed(reason: String)
}

extension EmotionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .tooFewRR(let minExpected, let actual):
            return "Too few RR intervals: expected at least \(minExpected), got \(actual)"
        case .badInput(let reason):
            return "Bad input: \(reason)"
        case .modelIncompatible(let expectedFeats, let actualFeats):
            return "Model incompatible: expected \(expectedFeats) features, got \(actualFeats)"
        case .featureExtractionFailed(let reason):
            return "Feature extraction failed: \(reason)"
        }
    }
}

extension EmotionError: CustomStringConvertible {
    public var description: String {
        return errorDescription ?? "Unknown emotion error"
    }
}
