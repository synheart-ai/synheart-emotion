#!/usr/bin/env python3
"""
Custom Configuration Example - Synheart Emotion SDK

This example demonstrates advanced features:
- Custom engine configuration
- Custom logging
- Buffer management
- Error handling
- Personalized settings (HR baseline, priors)
"""

import random
from datetime import datetime
from typing import Dict, Any, Optional

from synheart_emotion import EmotionConfig, EmotionEngine, EmotionError
from synheart_emotion.error import TooFewRRError, BadInputError


class CustomLogger:
    """Custom logger with colored output and filtering."""

    def __init__(self, min_level: str = "info"):
        self.levels = {"debug": 0, "info": 1, "warn": 2, "error": 3}
        self.min_level = self.levels.get(min_level, 1)
        self.log_count = {"debug": 0, "info": 0, "warn": 0, "error": 0}

    def __call__(self, level: str, message: str, context: Optional[Dict[str, Any]] = None):
        """Log a message with optional context."""
        if self.levels.get(level, 0) < self.min_level:
            return

        self.log_count[level] = self.log_count.get(level, 0) + 1

        # Color codes
        colors = {
            "debug": "\033[36m",  # Cyan
            "info": "\033[32m",   # Green
            "warn": "\033[33m",   # Yellow
            "error": "\033[31m"   # Red
        }
        reset = "\033[0m"

        color = colors.get(level, "")
        emoji = {"debug": "🔍", "info": "ℹ️", "warn": "⚠️", "error": "❌"}.get(level, "📝")

        print(f"{color}{emoji} [{level.upper():5s}]{reset} {message}")

        if context:
            for key, value in context.items():
                print(f"        {key}: {value}")

    def get_summary(self) -> str:
        """Get logging summary."""
        total = sum(self.log_count.values())
        return f"Logged {total} messages: " + ", ".join([
            f"{level}={count}" for level, count in self.log_count.items() if count > 0
        ])


def generate_biosignal_data(hr: float) -> tuple[float, list[float]]:
    """Generate synthetic biosignal data."""
    hr_noisy = hr + random.uniform(-2, 2)
    mean_rr = 60000.0 / hr_noisy
    count = random.randint(35, 50)
    rr_intervals = [mean_rr + random.uniform(-10, 10) for _ in range(count)]
    return hr_noisy, rr_intervals


def demonstrate_custom_config():
    """Demonstrate custom configuration options."""
    print("\n" + "=" * 60)
    print("Example 1: Custom Configuration")
    print("=" * 60 + "\n")

    # Create custom configuration
    custom_config = EmotionConfig(
        window_seconds=45.0,        # Shorter window for faster response
        step_seconds=3.0,           # More frequent updates
        min_rr_count=25,            # Lower threshold
        hr_baseline=68.0,           # Personal baseline
        return_all_probas=True,     # Return all probabilities
        priors={'Calm': 0.5, 'Amused': 0.3, 'Stressed': 0.2}  # Prior beliefs
    )

    print("Custom configuration:")
    print(f"   Window: {custom_config.window_seconds}s (default: 60s)")
    print(f"   Step: {custom_config.step_seconds}s (default: 5s)")
    print(f"   Min RR: {custom_config.min_rr_count} (default: 30)")
    print(f"   HR baseline: {custom_config.hr_baseline} bpm")
    print(f"   Priors: {custom_config.priors}")
    print()

    # Initialize with custom config
    logger = CustomLogger(min_level="debug")
    engine = EmotionEngine.from_pretrained(custom_config, on_log=logger)

    print("✓ Engine initialized with custom configuration\n")

    # Push some data
    for i in range(15):
        hr, rr = generate_biosignal_data(70.0)
        engine.push(hr=hr, rr_intervals_ms=rr, timestamp=datetime.now())

    results = engine.consume_ready()
    if results:
        result = results[0]
        print(f"\n📊 Result: {result.emotion} ({result.confidence:.1%})")

    print(f"\n{logger.get_summary()}")


def demonstrate_logging():
    """Demonstrate custom logging capabilities."""
    print("\n" + "=" * 60)
    print("Example 2: Custom Logging")
    print("=" * 60 + "\n")

    # Different logging levels
    for min_level in ["debug", "info", "warn"]:
        print(f"\nLogging level: {min_level}")
        print("-" * 40)

        logger = CustomLogger(min_level=min_level)
        config = EmotionConfig()
        engine = EmotionEngine.from_pretrained(config, on_log=logger)

        # Push some data to trigger logs
        for _ in range(5):
            hr, rr = generate_biosignal_data(72.0)
            engine.push(hr=hr, rr_intervals_ms=rr, timestamp=datetime.now())

        print(f"→ {logger.get_summary()}")


def demonstrate_buffer_management():
    """Demonstrate buffer management features."""
    print("\n" + "=" * 60)
    print("Example 3: Buffer Management")
    print("=" * 60 + "\n")

    config = EmotionConfig()
    engine = EmotionEngine.from_pretrained(config)

    print("Filling buffer with data...\n")

    for i in range(1, 11):
        hr, rr = generate_biosignal_data(75.0)
        engine.push(hr=hr, rr_intervals_ms=rr, timestamp=datetime.now())

        # Get buffer stats
        stats = engine.get_buffer_stats()
        print(f"   Push #{i:2d}: "
              f"Buffer size={stats['count']:2d}, "
              f"Duration={stats['duration_ms']:6.0f}ms, "
              f"RR count={stats['rr_count']:3d}")

    print("\n📦 Final buffer state:")
    stats = engine.get_buffer_stats()
    for key, value in stats.items():
        print(f"   {key}: {value}")

    print("\n🧹 Clearing buffer...")
    engine.clear()

    stats = engine.get_buffer_stats()
    print(f"   Buffer size after clear: {stats['count']}")


def demonstrate_error_handling():
    """Demonstrate error handling."""
    print("\n" + "=" * 60)
    print("Example 4: Error Handling")
    print("=" * 60 + "\n")

    config = EmotionConfig()
    engine = EmotionEngine.from_pretrained(config)

    # Test 1: Too few RR intervals
    print("Test 1: Handling too few RR intervals")
    try:
        engine.push(
            hr=72.0,
            rr_intervals_ms=[850.0, 820.0],  # Only 2 intervals (need 30+)
            timestamp=datetime.now()
        )
        print("   ✓ Data accepted (will wait for more)")
    except TooFewRRError as e:
        print(f"   ❌ Error: {e}")

    # Test 2: Invalid heart rate
    print("\nTest 2: Handling invalid heart rate")
    try:
        engine.push(
            hr=-10.0,  # Invalid negative HR
            rr_intervals_ms=[850.0] * 40,
            timestamp=datetime.now()
        )
        print("   ⚠️  Data accepted (validation may vary)")
    except BadInputError as e:
        print(f"   ❌ Error: {e}")

    # Test 3: Extremely high heart rate
    print("\nTest 3: Handling extreme heart rate")
    try:
        engine.push(
            hr=250.0,  # Very high HR
            rr_intervals_ms=[240.0] * 40,  # RR = 60000/250
            timestamp=datetime.now()
        )
        print("   ✓ Data accepted (extreme but valid)")
    except Exception as e:
        print(f"   ❌ Error: {e}")


def demonstrate_personalization():
    """Demonstrate personalized settings."""
    print("\n" + "=" * 60)
    print("Example 5: Personalization")
    print("=" * 60 + "\n")

    print("Comparing generic vs personalized configuration:\n")

    # Generic configuration
    print("Generic configuration (no personalization):")
    generic_config = EmotionConfig()
    generic_engine = EmotionEngine.from_pretrained(generic_config)

    # Personalized configuration
    print("\nPersonalized configuration:")
    print("   - HR baseline: 58 bpm (athlete)")
    print("   - Priors: More likely to be calm")

    personalized_config = EmotionConfig(
        hr_baseline=58.0,  # Athlete's resting HR
        priors={'Calm': 0.6, 'Amused': 0.25, 'Stressed': 0.15}
    )
    personalized_engine = EmotionEngine.from_pretrained(personalized_config)

    # Push same data to both
    hr, rr = generate_biosignal_data(65.0)

    for engine, label in [(generic_engine, "Generic"), (personalized_engine, "Personalized")]:
        for _ in range(20):
            hr_sample, rr_sample = generate_biosignal_data(65.0)
            engine.push(hr=hr_sample, rr_intervals_ms=rr_sample, timestamp=datetime.now())

        results = engine.consume_ready()
        if results:
            result = results[0]
            print(f"\n{label} result:")
            print(f"   Emotion: {result.emotion}")
            print(f"   Confidence: {result.confidence:.1%}")
            print(f"   Probabilities: {result.probabilities}")


def main():
    print("\n" + "=" * 60)
    print("Synheart Emotion SDK - Custom Configuration Examples")
    print("=" * 60)

    demonstrate_custom_config()
    demonstrate_logging()
    demonstrate_buffer_management()
    demonstrate_error_handling()
    demonstrate_personalization()

    print("\n" + "=" * 60)
    print("✅ All examples completed successfully!")
    print("=" * 60 + "\n")


if __name__ == "__main__":
    main()
