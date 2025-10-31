"""Main emotion inference engine."""
import threading
from collections import deque
from datetime import datetime, timedelta
from typing import Any, Callable, Deque, Dict, List, Optional

from .config import EmotionConfig
from .error import ModelIncompatibleError
from .features import FeatureExtractor
from .models import LinearSvmModel
from .result import EmotionResult


class DataPoint:
    """Data point for ring buffer."""

    def __init__(
        self,
        timestamp: datetime,
        hr: float,
        rr_intervals_ms: List[float],
        motion: Optional[Dict[str, float]] = None,
    ):
        self.timestamp = timestamp
        self.hr = hr
        self.rr_intervals_ms = rr_intervals_ms
        self.motion = motion


class EmotionEngine:
    """Main emotion inference engine.

    Processes biosignal data using a sliding window approach and produces
    emotion predictions at configurable intervals.
    """

    EXPECTED_FEATURE_COUNT = 3

    def __init__(
        self,
        config: EmotionConfig,
        model: LinearSvmModel,
        on_log: Optional[Callable[[str, str, Optional[Dict[str, Any]]], None]] = None,
    ):
        """Initialize emotion engine.

        Args:
            config: Engine configuration
            model: Linear SVM model for inference
            on_log: Optional logging callback (level, message, context)
        """
        self.config = config
        self.model = model
        self.on_log = on_log

        # Ring buffer for sliding window
        self._buffer: Deque[DataPoint] = deque()

        # Last emission timestamp
        self._last_emission: Optional[datetime] = None

        # Thread lock for buffer operations
        self._lock = threading.RLock()

    @classmethod
    def from_pretrained(
        cls,
        config: EmotionConfig,
        model: Optional[LinearSvmModel] = None,
        on_log: Optional[Callable[[str, str, Optional[Dict[str, Any]]], None]] = None,
    ) -> "EmotionEngine":
        """Create engine from pretrained model.

        Args:
            config: Engine configuration
            model: Optional custom model (defaults to WESAD model)
            on_log: Optional logging callback

        Returns:
            EmotionEngine instance

        Raises:
            ModelIncompatibleError: If model is incompatible
        """
        svm_model = model or LinearSvmModel.create_default()

        # Validate model compatibility
        has_required_features = (
            len(svm_model.feature_names) == cls.EXPECTED_FEATURE_COUNT
            and "hr_mean" in svm_model.feature_names
            and "sdnn" in svm_model.feature_names
            and "rmssd" in svm_model.feature_names
        )

        if not has_required_features:
            raise ModelIncompatibleError(
                cls.EXPECTED_FEATURE_COUNT,
                len(svm_model.feature_names),
            )

        return cls(config=config, model=svm_model, on_log=on_log)

    def push(
        self,
        hr: float,
        rr_intervals_ms: List[float],
        timestamp: datetime,
        motion: Optional[Dict[str, float]] = None,
    ) -> None:
        """Push new data point into the engine.

        Args:
            hr: Heart rate in BPM
            rr_intervals_ms: RR intervals in milliseconds
            timestamp: Timestamp of the data point
            motion: Optional motion data
        """
        with self._lock:
            try:
                # Validate input using physiological constants
                if hr < FeatureExtractor.MIN_VALID_HR or hr > FeatureExtractor.MAX_VALID_HR:
                    self._log(
                        "warn",
                        f"Invalid HR value: {hr} "
                        f"(valid range: {FeatureExtractor.MIN_VALID_HR}-{FeatureExtractor.MAX_VALID_HR} BPM)",
                    )
                    return

                if not rr_intervals_ms:
                    self._log("warn", "Empty RR intervals")
                    return

                # Add to ring buffer
                data_point = DataPoint(
                    timestamp=timestamp,
                    hr=hr,
                    rr_intervals_ms=list(rr_intervals_ms),
                    motion=motion,
                )

                self._buffer.append(data_point)

                # Remove old data points outside window
                self._trim_buffer()

                self._log("debug", f"Pushed data point: HR={hr}, RR count={len(rr_intervals_ms)}")

            except Exception as e:
                self._log("error", f"Error pushing data point: {e}")

    def consume_ready(self) -> List[EmotionResult]:
        """Consume ready results (throttled by step interval).

        Returns:
            List of emotion results (empty if not ready)
        """
        results = []

        with self._lock:
            try:
                # Check if enough time has passed since last emission
                now = datetime.now()
                if self._last_emission is not None:
                    elapsed = (now - self._last_emission).total_seconds()
                    if elapsed < self.config.step_seconds:
                        return results  # Not ready yet

                # Check if we have enough data
                if len(self._buffer) < 2:
                    return results  # Not enough data

                # Extract features from current window
                features = self._extract_window_features()
                if features is None:
                    return results  # Feature extraction failed

                # Run inference
                probabilities = self.model.predict(features)

                # Create result
                result = EmotionResult.from_inference(
                    timestamp=now,
                    probabilities=probabilities,
                    features=features,
                    model=self.model.get_metadata(),
                )

                results.append(result)
                self._last_emission = now

                self._log(
                    "info",
                    f"Emitted result: {result.emotion} ({result.confidence * 100:.1f}%)",
                )

            except Exception as e:
                self._log("error", f"Error during inference: {e}")

        return results

    def _extract_window_features(self) -> Optional[Dict[str, float]]:
        """Extract features from current window.

        Returns:
            Dictionary of features or None if extraction failed
        """
        if not self._buffer:
            return None

        # Collect all HR values and RR intervals in window
        hr_values = []
        all_rr_intervals = []
        motion_aggregate: Dict[str, float] = {}

        for point in self._buffer:
            hr_values.append(point.hr)
            all_rr_intervals.extend(point.rr_intervals_ms)

            # Aggregate motion data
            if point.motion:
                for key, value in point.motion.items():
                    motion_aggregate[key] = motion_aggregate.get(key, 0.0) + value

        # Check minimum RR count
        if len(all_rr_intervals) < self.config.min_rr_count:
            self._log(
                "warn",
                f"Too few RR intervals: {len(all_rr_intervals)} < {self.config.min_rr_count}",
            )
            return None

        # Extract features
        features = FeatureExtractor.extract_features(
            hr_values=hr_values,
            rr_intervals_ms=all_rr_intervals,
            motion=motion_aggregate if motion_aggregate else None,
        )

        # Apply personalization if configured
        if self.config.hr_baseline is not None:
            features["hr_mean"] -= self.config.hr_baseline

        return features

    def _trim_buffer(self) -> None:
        """Trim buffer to keep only data within window."""
        if not self._buffer:
            return

        cutoff_time = datetime.now() - timedelta(seconds=self.config.window_seconds)

        # Remove expired data points
        while self._buffer and self._buffer[0].timestamp < cutoff_time:
            self._buffer.popleft()

    def get_buffer_stats(self) -> Dict[str, Any]:
        """Get current buffer statistics.

        Returns:
            Dictionary of buffer statistics
        """
        with self._lock:
            if not self._buffer:
                return {
                    "count": 0,
                    "duration_ms": 0,
                    "hr_range": [0.0, 0.0],
                    "rr_count": 0,
                }

            hr_values = [point.hr for point in self._buffer]
            rr_count = sum(len(point.rr_intervals_ms) for point in self._buffer)
            duration = (self._buffer[-1].timestamp - self._buffer[0].timestamp).total_seconds() * 1000

            return {
                "count": len(self._buffer),
                "duration_ms": int(duration),
                "hr_range": [min(hr_values), max(hr_values)],
                "rr_count": rr_count,
            }

    def clear(self) -> None:
        """Clear all buffered data."""
        with self._lock:
            self._buffer.clear()
            self._last_emission = None
            self._log("info", "Buffer cleared")

    def _log(self, level: str, message: str, context: Optional[Dict[str, Any]] = None) -> None:
        """Log message with optional context.

        Args:
            level: Log level (debug, info, warn, error)
            message: Log message
            context: Optional context dictionary
        """
        if self.on_log:
            self.on_log(level, message, context)
