"""Tests for emotion engine."""
from datetime import datetime

import pytest

from synheart_emotion import EmotionConfig, EmotionEngine, EmotionError


def test_engine_creation():
    """Test engine creation."""
    config = EmotionConfig()
    engine = EmotionEngine.from_pretrained(config)

    assert engine is not None
    assert engine.config == config


def test_engine_push():
    """Test pushing data to engine."""
    config = EmotionConfig()
    engine = EmotionEngine.from_pretrained(config)

    # Should not raise
    engine.push(
        hr=72.0,
        rr_intervals_ms=[850.0, 820.0, 830.0],
        timestamp=datetime.now(),
    )


def test_engine_buffer_stats():
    """Test buffer statistics."""
    config = EmotionConfig()
    engine = EmotionEngine.from_pretrained(config)

    # Empty buffer
    stats = engine.get_buffer_stats()
    assert stats["count"] == 0

    # Add data
    engine.push(
        hr=72.0,
        rr_intervals_ms=[850.0, 820.0, 830.0],
        timestamp=datetime.now(),
    )

    stats = engine.get_buffer_stats()
    assert stats["count"] == 1
    assert stats["rr_count"] == 3


def test_engine_clear():
    """Test clearing buffer."""
    config = EmotionConfig()
    engine = EmotionEngine.from_pretrained(config)

    # Add data
    engine.push(
        hr=72.0,
        rr_intervals_ms=[850.0, 820.0, 830.0],
        timestamp=datetime.now(),
    )

    # Clear
    engine.clear()

    stats = engine.get_buffer_stats()
    assert stats["count"] == 0


def test_engine_consume_ready_not_ready():
    """Test consume when not ready."""
    config = EmotionConfig()
    engine = EmotionEngine.from_pretrained(config)

    # No data
    results = engine.consume_ready()
    assert len(results) == 0

    # Not enough data
    engine.push(
        hr=72.0,
        rr_intervals_ms=[850.0, 820.0, 830.0],
        timestamp=datetime.now(),
    )

    results = engine.consume_ready()
    assert len(results) == 0  # Not enough data yet


def test_engine_invalid_hr():
    """Test invalid HR values."""
    config = EmotionConfig()
    engine = EmotionEngine.from_pretrained(config)

    log_messages = []

    def logger(level, message, context):
        log_messages.append((level, message))

    engine.on_log = logger

    # Too high
    engine.push(
        hr=400.0,  # Invalid
        rr_intervals_ms=[850.0, 820.0, 830.0],
        timestamp=datetime.now(),
    )

    # Should log warning
    assert any("Invalid HR" in msg for level, msg in log_messages)


def test_engine_empty_rr():
    """Test empty RR intervals."""
    config = EmotionConfig()
    engine = EmotionEngine.from_pretrained(config)

    log_messages = []

    def logger(level, message, context):
        log_messages.append((level, message))

    engine.on_log = logger

    # Empty RR
    engine.push(
        hr=72.0,
        rr_intervals_ms=[],  # Empty
        timestamp=datetime.now(),
    )

    # Should log warning
    assert any("Empty RR" in msg for level, msg in log_messages)
