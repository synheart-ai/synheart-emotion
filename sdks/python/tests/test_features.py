"""Tests for feature extraction."""
import pytest

from synheart_emotion.features import FeatureExtractor


def test_extract_hr_mean():
    """Test HR mean extraction."""
    hr_values = [70.0, 72.0, 68.0, 74.0]
    result = FeatureExtractor.extract_hr_mean(hr_values)
    assert result == 71.0


def test_extract_hr_mean_empty():
    """Test HR mean with empty list."""
    result = FeatureExtractor.extract_hr_mean([])
    assert result == 0.0


def test_extract_sdnn():
    """Test SDNN extraction."""
    rr_intervals = [800.0, 820.0, 810.0, 830.0, 815.0]
    result = FeatureExtractor.extract_sdnn(rr_intervals)
    assert result > 0  # Should return positive value


def test_extract_rmssd():
    """Test RMSSD extraction."""
    rr_intervals = [800.0, 820.0, 810.0, 830.0, 815.0]
    result = FeatureExtractor.extract_rmssd(rr_intervals)
    assert result > 0  # Should return positive value


def test_extract_features():
    """Test full feature extraction."""
    hr_values = [70.0, 72.0, 68.0]
    rr_intervals = [800.0, 820.0, 810.0, 830.0, 815.0]

    features = FeatureExtractor.extract_features(hr_values, rr_intervals)

    assert "hr_mean" in features
    assert "sdnn" in features
    assert "rmssd" in features
    assert features["hr_mean"] == 70.0


def test_clean_rr_intervals():
    """Test RR interval cleaning."""
    # Include some outliers
    rr_intervals = [
        100.0,  # Too low (< 300ms)
        800.0,  # Valid
        820.0,  # Valid
        3000.0,  # Too high (> 2000ms)
        810.0,  # Valid
    ]

    cleaned = FeatureExtractor._clean_rr_intervals(rr_intervals)

    # Should remove outliers
    assert len(cleaned) < len(rr_intervals)
    assert 100.0 not in cleaned
    assert 3000.0 not in cleaned


def test_validate_features():
    """Test feature validation."""
    features = {"hr_mean": 70.0, "sdnn": 45.0, "rmssd": 30.0}
    required = ["hr_mean", "sdnn", "rmssd"]

    assert FeatureExtractor.validate_features(features, required) is True


def test_validate_features_missing():
    """Test feature validation with missing feature."""
    features = {"hr_mean": 70.0, "sdnn": 45.0}
    required = ["hr_mean", "sdnn", "rmssd"]

    assert FeatureExtractor.validate_features(features, required) is False


def test_normalize_features():
    """Test feature normalization."""
    features = {"hr_mean": 70.0, "sdnn": 45.0}
    mu = {"hr_mean": 72.5, "sdnn": 45.3}
    sigma = {"hr_mean": 12.0, "sdnn": 18.7}

    normalized = FeatureExtractor.normalize_features(features, mu, sigma)

    # Should be normalized (approximately)
    assert normalized["hr_mean"] < 0  # Below mean
    assert abs(normalized["sdnn"]) < 0.1  # Near mean
