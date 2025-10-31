import Foundation

/// Linear SVM model with weights embedded in code.
///
/// This is the original embedded model format that stores weights
/// directly in code. For loading models from assets, use
/// a JSON-based model loader instead.
public struct LinearSvmModel {
    /// Model identifier
    public let modelId: String

    /// Model version
    public let version: String

    /// Supported emotion labels
    public let labels: [String]

    /// Feature names in order
    public let featureNames: [String]

    /// SVM weights matrix (C x F where C=classes, F=features)
    public let weights: [[Double]]

    /// SVM bias vector (C classes)
    public let biases: [Double]

    /// Feature normalization means
    public let mu: [String: Double]

    /// Feature normalization standard deviations
    public let sigma: [String: Double]

    /// Initialize linear SVM model
    public init(
        modelId: String,
        version: String,
        labels: [String],
        featureNames: [String],
        weights: [[Double]],
        biases: [Double],
        mu: [String: Double],
        sigma: [String: Double]
    ) throws {
        // Validate dimensions
        guard weights.count == labels.count else {
            throw EmotionError.modelIncompatible(
                expectedFeats: labels.count,
                actualFeats: weights.count
            )
        }
        guard biases.count == labels.count else {
            throw EmotionError.modelIncompatible(
                expectedFeats: labels.count,
                actualFeats: biases.count
            )
        }
        if !weights.isEmpty {
            guard weights[0].count == featureNames.count else {
                throw EmotionError.modelIncompatible(
                    expectedFeats: featureNames.count,
                    actualFeats: weights[0].count
                )
            }
        }

        self.modelId = modelId
        self.version = version
        self.labels = labels
        self.featureNames = featureNames
        self.weights = weights
        self.biases = biases
        self.mu = mu
        self.sigma = sigma
    }

    /// Predict emotion probabilities from features
    public func predict(_ features: [String: Double]) throws -> [String: Double] {
        // Validate input features
        guard FeatureExtractor.validateFeatures(features, requiredFeatures: featureNames) else {
            throw EmotionError.badInput(reason: "Invalid features: missing required features or NaN values")
        }

        // Normalize features
        let normalizedFeatures = FeatureExtractor.normalizeFeatures(features, mu: mu, sigma: sigma)

        // Extract feature vector in correct order
        var featureVector: [Double] = []
        for featureName in featureNames {
            guard let value = normalizedFeatures[featureName] else {
                throw EmotionError.badInput(reason: "Missing required feature: \(featureName)")
            }
            featureVector.append(value)
        }

        // Calculate SVM margins: W·x + b
        var margins: [Double] = []
        for i in 0..<labels.count {
            var margin = biases[i]
            for j in 0..<featureVector.count {
                margin += weights[i][j] * featureVector[j]
            }
            margins.append(margin)
        }

        // Apply softmax to get probabilities
        return softmax(margins: margins, labels: labels)
    }

    /// Apply softmax function to convert margins to probabilities
    private func softmax(margins: [Double], labels: [String]) -> [String: Double] {
        // Find maximum margin for numerical stability
        let maxMargin = margins.max() ?? 0.0

        // Calculate exponentials
        let exponentials = margins.map { exp($0 - maxMargin) }
        let sumExp = exponentials.reduce(0.0, +)

        // Calculate probabilities
        var probabilities: [String: Double] = [:]
        for i in 0..<labels.count {
            probabilities[labels[i]] = exponentials[i] / sumExp
        }

        return probabilities
    }

    /// Get model metadata
    public func getMetadata() -> [String: Any] {
        return [
            "id": modelId,
            "version": version,
            "type": "embedded",
            "labels": labels,
            "feature_names": featureNames,
            "num_classes": labels.count,
            "num_features": featureNames.count
        ]
    }

    /// Validate model integrity
    public func validate() -> Bool {
        // Check dimensions
        guard weights.count == labels.count else { return false }
        guard biases.count == labels.count else { return false }
        if !weights.isEmpty {
            guard weights[0].count == featureNames.count else { return false }
        }

        // Check for NaN or infinite values
        for weightRow in weights {
            for weight in weightRow {
                if weight.isNaN || weight.isInfinite { return false }
            }
        }

        for bias in biases {
            if bias.isNaN || bias.isInfinite { return false }
        }

        return true
    }

    /// Create the default WESAD-trained emotion model
    ///
    /// **⚠️ WARNING: This model uses placeholder weights for demonstration purposes only.**
    ///
    /// The weights in this model are NOT trained on real biosignal data and should
    /// NOT be used in production or clinical settings.
    public static func createDefault() -> LinearSvmModel {
        return try! LinearSvmModel(
            modelId: "wesad_emotion_v1_0",
            version: "1.0",
            labels: ["Amused", "Calm", "Stressed"],
            featureNames: ["hr_mean", "sdnn", "rmssd"],
            weights: [
                [0.12, 0.5, 0.3],    // Amused: higher HR, higher HRV
                [-0.21, -0.4, -0.3], // Calm: lower HR, lower HRV
                [0.02, 0.2, 0.1]     // Stressed: slightly higher HR, moderate HRV
            ],
            biases: [-0.2, 0.3, 0.1],
            mu: [
                "hr_mean": 72.5,
                "sdnn": 45.3,
                "rmssd": 32.1
            ],
            sigma: [
                "hr_mean": 12.0,
                "sdnn": 18.7,
                "rmssd": 12.4
            ]
        )
    }
}
