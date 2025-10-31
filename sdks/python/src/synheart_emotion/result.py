"""Result of emotion inference containing probabilities and metadata."""
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Dict


@dataclass
class EmotionResult:
    """Result of emotion inference.

    Attributes:
        timestamp: Timestamp when inference was performed
        emotion: Predicted emotion label (top-1)
        confidence: Confidence score (top-1 probability)
        probabilities: All label probabilities
        features: Extracted features used for inference
        model: Model metadata
    """

    timestamp: datetime
    emotion: str
    confidence: float
    probabilities: Dict[str, float]
    features: Dict[str, float]
    model: Dict[str, Any]

    @classmethod
    def from_inference(
        cls,
        timestamp: datetime,
        probabilities: Dict[str, float],
        features: Dict[str, float],
        model: Dict[str, Any],
    ) -> "EmotionResult":
        """Create EmotionResult from raw inference data.

        Args:
            timestamp: Timestamp when inference was performed
            probabilities: Dictionary of label probabilities
            features: Extracted features used for inference
            model: Model metadata

        Returns:
            EmotionResult instance
        """
        # Find top-1 emotion
        top_emotion = max(probabilities.items(), key=lambda x: x[1])
        emotion, confidence = top_emotion

        return cls(
            timestamp=timestamp,
            emotion=emotion,
            confidence=confidence,
            probabilities=probabilities,
            features=features,
            model=model,
        )

    def __str__(self) -> str:
        confidence_percent = self.confidence * 100
        feature_names = ", ".join(self.features.keys())
        return f"EmotionResult({self.emotion}: {confidence_percent:.1f}%, features: {feature_names})"

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for JSON serialization."""
        return {
            "timestamp": self.timestamp.isoformat(),
            "emotion": self.emotion,
            "confidence": self.confidence,
            "probabilities": self.probabilities,
            "features": self.features,
            "model": self.model,
        }
