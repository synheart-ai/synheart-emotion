"""Example with custom configuration and logging."""
from datetime import datetime

from synheart_emotion import EmotionConfig, EmotionEngine


def custom_logger(level: str, message: str, context=None):
    """Custom logging callback."""
    emoji = {"error": "❌", "warn": "⚠️", "info": "ℹ️", "debug": "🔍"}.get(level, "•")
    print(f"{emoji} [{level.upper()}] {message}")
    if context:
        print(f"   Context: {context}")


def main():
    """Run example with custom configuration."""
    # Create custom configuration
    config = EmotionConfig(
        window_seconds=60.0,  # 60 second window
        step_seconds=5.0,  # 5 second step
        min_rr_count=30,  # Minimum RR intervals
        hr_baseline=65.0,  # Personal HR baseline for normalization
    )

    # Create engine with custom logger
    engine = EmotionEngine.from_pretrained(
        config=config,
        on_log=custom_logger,
    )

    print("=== Custom Configuration ===")
    print(config)
    print()

    # Simulate continuous data stream
    print("=== Simulating continuous data stream ===")
    for i in range(20):
        hr = 70.0 + (i % 5) * 2.0  # Varying HR
        rr_intervals = [850.0 + (i % 3) * 10.0] * 10  # Varying RR
        timestamp = datetime.now()

        engine.push(
            hr=hr,
            rr_intervals_ms=rr_intervals,
            timestamp=timestamp,
        )

        # Try to get results
        results = engine.consume_ready()
        if results:
            print(f"\n{'='*50}")
            for result in results:
                print(f"Emotion: {result.emotion} ({result.confidence * 100:.1f}%)")
                print(f"All probabilities: {result.probabilities}")
            print(f"{'='*50}\n")

    # Final buffer statistics
    stats = engine.get_buffer_stats()
    print(f"\n=== Final Buffer Statistics ===")
    print(f"Data points buffered: {stats['count']}")
    print(f"Window duration: {stats['duration_ms']}ms")
    print(f"HR range: {stats['hr_range']}")
    print(f"Total RR intervals: {stats['rr_count']}")


if __name__ == "__main__":
    main()
