"""Configuration for the emotion inference engine."""
from dataclasses import dataclass
from typing import Dict, Optional


@dataclass
class EmotionConfig:
    """Configuration for the emotion inference engine.

    Attributes:
        model_id: Model identifier (default: svm_linear_wrist_sdnn_v1_0)
        window_seconds: Rolling window size for feature calculation (default: 60s)
        step_seconds: Emission cadence for results (default: 5s)
        min_rr_count: Minimum RR intervals required for inference (default: 30)
        return_all_probas: Whether to return all label probabilities (default: True)
        hr_baseline: Optional HR baseline for personalization
        priors: Optional label priors for calibration
    """

    model_id: str = "svm_linear_wrist_sdnn_v1_0"
    window_seconds: float = 60.0
    step_seconds: float = 5.0
    min_rr_count: int = 30
    return_all_probas: bool = True
    hr_baseline: Optional[float] = None
    priors: Optional[Dict[str, float]] = None

    def __str__(self) -> str:
        return (
            f"EmotionConfig(model_id={self.model_id}, "
            f"window={self.window_seconds}s, "
            f"step={self.step_seconds}s, "
            f"min_rr_count={self.min_rr_count})"
        )
