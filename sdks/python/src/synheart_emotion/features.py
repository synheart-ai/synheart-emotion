"""Feature extraction utilities for emotion inference."""
from typing import Dict, List, Optional

import numpy as np


class FeatureExtractor:
    """Feature extraction utilities for emotion inference.

    Provides methods for extracting heart rate variability (HRV) metrics
    from biosignal data, including HR mean, SDNN, and RMSSD.
    """

    # Minimum valid RR interval in milliseconds (300ms = 200 BPM)
    MIN_VALID_RR_MS = 300.0

    # Maximum valid RR interval in milliseconds (2000ms = 30 BPM)
    MAX_VALID_RR_MS = 2000.0

    # Maximum allowed jump between successive RR intervals in milliseconds
    MAX_RR_JUMP_MS = 250.0

    # Minimum heart rate value considered valid (in BPM)
    MIN_VALID_HR = 30.0

    # Maximum heart rate value considered valid (in BPM)
    MAX_VALID_HR = 300.0

    @staticmethod
    def extract_hr_mean(hr_values: List[float]) -> float:
        """Extract HR mean from a list of HR values.

        Args:
            hr_values: List of heart rate values in BPM

        Returns:
            Mean heart rate (0.0 if empty list)
        """
        if not hr_values:
            return 0.0
        return float(np.mean(hr_values))

    @staticmethod
    def extract_sdnn(rr_intervals_ms: List[float]) -> float:
        """Extract SDNN (standard deviation of NN intervals) from RR intervals.

        Args:
            rr_intervals_ms: List of RR intervals in milliseconds

        Returns:
            SDNN value (0.0 if insufficient data)
        """
        if len(rr_intervals_ms) < 2:
            return 0.0

        # Clean RR intervals (remove outliers)
        cleaned = FeatureExtractor._clean_rr_intervals(rr_intervals_ms)
        if len(cleaned) < 2:
            return 0.0

        # Calculate standard deviation (sample std, N-1 denominator)
        return float(np.std(cleaned, ddof=1))

    @staticmethod
    def extract_rmssd(rr_intervals_ms: List[float]) -> float:
        """Extract RMSSD (root mean square of successive differences).

        Args:
            rr_intervals_ms: List of RR intervals in milliseconds

        Returns:
            RMSSD value (0.0 if insufficient data)
        """
        if len(rr_intervals_ms) < 2:
            return 0.0

        # Clean RR intervals
        cleaned = FeatureExtractor._clean_rr_intervals(rr_intervals_ms)
        if len(cleaned) < 2:
            return 0.0

        # Calculate successive differences
        diffs = np.diff(cleaned)
        squared_diffs = diffs**2
        rmssd = np.sqrt(np.mean(squared_diffs))

        return float(rmssd)

    @staticmethod
    def extract_features(
        hr_values: List[float],
        rr_intervals_ms: List[float],
        motion: Optional[Dict[str, float]] = None,
    ) -> Dict[str, float]:
        """Extract all features for emotion inference.

        Args:
            hr_values: List of heart rate values in BPM
            rr_intervals_ms: List of RR intervals in milliseconds
            motion: Optional motion data as key-value pairs

        Returns:
            Dictionary of extracted features
        """
        features = {
            "hr_mean": FeatureExtractor.extract_hr_mean(hr_values),
            "sdnn": FeatureExtractor.extract_sdnn(rr_intervals_ms),
            "rmssd": FeatureExtractor.extract_rmssd(rr_intervals_ms),
        }

        # Add motion features if provided
        if motion:
            features.update(motion)

        return features

    @staticmethod
    def _clean_rr_intervals(rr_intervals_ms: List[float]) -> List[float]:
        """Clean RR intervals by removing invalid values and artifacts.

        Removes:
        - RR intervals outside valid range (MIN_VALID_RR_MS to MAX_VALID_RR_MS)
        - Large jumps between successive intervals (> MAX_RR_JUMP_MS)

        Args:
            rr_intervals_ms: List of RR intervals in milliseconds

        Returns:
            Filtered list of clean RR intervals
        """
        if not rr_intervals_ms:
            return []

        cleaned = []
        prev_value = None

        for rr in rr_intervals_ms:
            # Skip outliers outside physiological range
            if rr < FeatureExtractor.MIN_VALID_RR_MS or rr > FeatureExtractor.MAX_VALID_RR_MS:
                continue

            # Skip large jumps that likely indicate artifacts
            if prev_value is not None and abs(rr - prev_value) > FeatureExtractor.MAX_RR_JUMP_MS:
                continue

            cleaned.append(rr)
            prev_value = rr

        return cleaned

    @staticmethod
    def validate_features(features: Dict[str, float], required_features: List[str]) -> bool:
        """Validate feature vector for model compatibility.

        Args:
            features: Dictionary of feature values
            required_features: List of required feature names

        Returns:
            True if all required features are present and valid
        """
        for feature in required_features:
            if feature not in features:
                return False
            value = features[feature]
            if np.isnan(value) or np.isinf(value):
                return False
        return True

    @staticmethod
    def normalize_features(
        features: Dict[str, float],
        mu: Dict[str, float],
        sigma: Dict[str, float],
    ) -> Dict[str, float]:
        """Normalize features using training statistics.

        Args:
            features: Dictionary of feature values
            mu: Mean values for each feature
            sigma: Standard deviation values for each feature

        Returns:
            Dictionary of normalized features
        """
        normalized = {}

        for feature_name, value in features.items():
            if feature_name in mu and feature_name in sigma:
                mean = mu[feature_name]
                std = sigma[feature_name]

                # Avoid division by zero
                if std > 0:
                    normalized[feature_name] = (value - mean) / std
                else:
                    normalized[feature_name] = 0.0
            else:
                # Keep original value if no normalization params
                normalized[feature_name] = value

        return normalized
