"""Synheart Emotion - On-device emotion inference from biosignals.

This package provides real-time emotion detection from heart rate and
RR interval data, designed for wearable devices and health monitoring apps.
"""

__version__ = "0.1.0"

from .config import EmotionConfig
from .engine import EmotionEngine
from .error import EmotionError
from .features import FeatureExtractor
from .models import LinearSvmModel
from .result import EmotionResult

__all__ = [
    "EmotionConfig",
    "EmotionEngine",
    "EmotionError",
    "EmotionResult",
    "FeatureExtractor",
    "LinearSvmModel",
]
