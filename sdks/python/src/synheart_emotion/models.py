"""Linear SVM model and model loading utilities."""
from typing import Any, Dict, List

import numpy as np

from .error import BadInputError, ModelIncompatibleError
from .features import FeatureExtractor


class LinearSvmModel:
    """Linear SVM model with weights embedded in code.

    This is the embedded model format that stores weights directly in code.
    For loading models from files, use ModelLoader.

    Attributes:
        model_id: Model identifier
        version: Model version
        labels: Supported emotion labels
        feature_names: Feature names in order
        weights: SVM weights matrix (C x F where C=classes, F=features)
        biases: SVM bias vector (C classes)
        mu: Feature normalization means
        sigma: Feature normalization standard deviations
    """

    def __init__(
        self,
        model_id: str,
        version: str,
        labels: List[str],
        feature_names: List[str],
        weights: List[List[float]],
        biases: List[float],
        mu: Dict[str, float],
        sigma: Dict[str, float],
    ):
        # Validate dimensions
        if len(weights) != len(labels):
            raise ModelIncompatibleError(len(labels), len(weights))
        if len(biases) != len(labels):
            raise ModelIncompatibleError(len(labels), len(biases))
        if weights and len(weights[0]) != len(feature_names):
            raise ModelIncompatibleError(len(feature_names), len(weights[0]))

        self.model_id = model_id
        self.version = version
        self.labels = labels
        self.feature_names = feature_names
        self.weights = np.array(weights)
        self.biases = np.array(biases)
        self.mu = mu
        self.sigma = sigma

    def predict(self, features: Dict[str, float]) -> Dict[str, float]:
        """Predict emotion probabilities from features.

        Args:
            features: Dictionary of feature values

        Returns:
            Dictionary of emotion probabilities

        Raises:
            BadInputError: If features are invalid or missing
        """
        # Validate input features
        if not FeatureExtractor.validate_features(features, self.feature_names):
            raise BadInputError("Invalid features: missing required features or NaN values")

        # Normalize features
        normalized_features = FeatureExtractor.normalize_features(features, self.mu, self.sigma)

        # Extract feature vector in correct order
        feature_vector = []
        for feature_name in self.feature_names:
            if feature_name not in normalized_features:
                raise BadInputError(f"Missing required feature: {feature_name}")
            feature_vector.append(normalized_features[feature_name])

        feature_vector = np.array(feature_vector)

        # Calculate SVM margins: W·x + b
        margins = self.weights @ feature_vector + self.biases

        # Apply softmax to get probabilities
        return self._softmax(margins)

    def _softmax(self, margins: np.ndarray) -> Dict[str, float]:
        """Apply softmax function to convert margins to probabilities.

        Args:
            margins: Array of class margins

        Returns:
            Dictionary mapping labels to probabilities
        """
        # Find maximum margin for numerical stability
        max_margin = np.max(margins)

        # Calculate exponentials
        exponentials = np.exp(margins - max_margin)
        sum_exp = np.sum(exponentials)

        # Calculate probabilities
        probabilities = exponentials / sum_exp

        return {label: float(prob) for label, prob in zip(self.labels, probabilities)}

    def get_metadata(self) -> Dict[str, Any]:
        """Get model metadata.

        Returns:
            Dictionary of model metadata
        """
        return {
            "id": self.model_id,
            "version": self.version,
            "type": "embedded",
            "labels": self.labels,
            "feature_names": self.feature_names,
            "num_classes": len(self.labels),
            "num_features": len(self.feature_names),
        }

    def validate(self) -> bool:
        """Validate model integrity.

        Returns:
            True if model is valid
        """
        try:
            # Check dimensions
            if len(self.weights) != len(self.labels):
                return False
            if len(self.biases) != len(self.labels):
                return False
            if self.weights.size > 0 and self.weights.shape[1] != len(self.feature_names):
                return False

            # Check for NaN or infinite values
            if np.any(np.isnan(self.weights)) or np.any(np.isinf(self.weights)):
                return False
            if np.any(np.isnan(self.biases)) or np.any(np.isinf(self.biases)):
                return False

            return True
        except Exception:
            return False

    @classmethod
    def create_default(cls) -> "LinearSvmModel":
        """Create the default WESAD-trained emotion model.

        WARNING: This model uses placeholder weights for demonstration purposes only.
        The weights are NOT trained on real biosignal data and should NOT be used
        in production or clinical settings.

        Returns:
            LinearSvmModel instance with default weights
        """
        return cls(
            model_id="wesad_emotion_v1_0",
            version="1.0",
            labels=["Amused", "Calm", "Stressed"],
            feature_names=["hr_mean", "sdnn", "rmssd"],
            weights=[
                [0.12, 0.5, 0.3],  # Amused: higher HR, higher HRV
                [-0.21, -0.4, -0.3],  # Calm: lower HR, lower HRV
                [0.02, 0.2, 0.1],  # Stressed: slightly higher HR, moderate HRV
            ],
            biases=[-0.2, 0.3, 0.1],
            mu={
                "hr_mean": 72.5,
                "sdnn": 45.3,
                "rmssd": 32.1,
            },
            sigma={
                "hr_mean": 12.0,
                "sdnn": 18.7,
                "rmssd": 12.4,
            },
        )
