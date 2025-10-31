import Foundation

/// Configuration for the emotion inference engine.
public struct EmotionConfig {
    /// Model identifier (default: svm_linear_wrist_sdnn_v1_0)
    public let modelId: String

    /// Rolling window size for feature calculation (default: 60s)
    public let window: TimeInterval

    /// Emission cadence for results (default: 5s)
    public let step: TimeInterval

    /// Minimum RR intervals required for inference (default: 30)
    public let minRrCount: Int

    /// Whether to return all label probabilities (default: true)
    public let returnAllProbas: Bool

    /// Optional HR baseline for personalization
    public let hrBaseline: Double?

    /// Optional label priors for calibration
    public let priors: [String: Double]?

    /// Initialize emotion configuration
    public init(
        modelId: String = "svm_linear_wrist_sdnn_v1_0",
        window: TimeInterval = 60.0,
        step: TimeInterval = 5.0,
        minRrCount: Int = 30,
        returnAllProbas: Bool = true,
        hrBaseline: Double? = nil,
        priors: [String: Double]? = nil
    ) {
        self.modelId = modelId
        self.window = window
        self.step = step
        self.minRrCount = minRrCount
        self.returnAllProbas = returnAllProbas
        self.hrBaseline = hrBaseline
        self.priors = priors
    }
}

extension EmotionConfig: CustomStringConvertible {
    public var description: String {
        return "EmotionConfig(modelId: \(modelId), window: \(Int(window))s, " +
               "step: \(Int(step))s, minRrCount: \(minRrCount))"
    }
}

extension EmotionConfig: Equatable {
    public static func == (lhs: EmotionConfig, rhs: EmotionConfig) -> Bool {
        return lhs.modelId == rhs.modelId &&
               lhs.window == rhs.window &&
               lhs.step == rhs.step &&
               lhs.minRrCount == rhs.minRrCount &&
               lhs.returnAllProbas == rhs.returnAllProbas &&
               lhs.hrBaseline == rhs.hrBaseline &&
               lhs.priors == rhs.priors
    }
}
