"""Errors that can occur during emotion inference."""
from typing import Any, Dict, Optional


class EmotionError(Exception):
    """Base class for emotion inference errors."""

    def __init__(self, message: str, context: Optional[Dict[str, Any]] = None):
        super().__init__(message)
        self.message = message
        self.context = context or {}

    def __str__(self) -> str:
        return f"EmotionError: {self.message}"


class TooFewRRError(EmotionError):
    """Too few RR intervals for stable inference."""

    def __init__(self, min_expected: int, actual: int):
        super().__init__(
            f"Too few RR intervals: expected at least {min_expected}, got {actual}",
            {"min_expected": min_expected, "actual": actual},
        )


class BadInputError(EmotionError):
    """Invalid input data."""

    def __init__(self, reason: str):
        super().__init__(f"Bad input: {reason}")


class ModelIncompatibleError(EmotionError):
    """Model incompatible with feature dimensions."""

    def __init__(self, expected_feats: int, actual_feats: int):
        super().__init__(
            f"Model incompatible: expected {expected_feats} features, got {actual_feats}",
            {"expected_feats": expected_feats, "actual_feats": actual_feats},
        )


class FeatureExtractionError(EmotionError):
    """Feature extraction failed."""

    def __init__(self, reason: str):
        super().__init__(f"Feature extraction failed: {reason}")
