"""Example with streaming data simulation."""
import time
from datetime import datetime

from synheart_emotion import EmotionConfig, EmotionEngine


def simulate_wearable_stream():
    """Simulate streaming data from a wearable device."""
    # Simulate different emotional states over time
    scenarios = [
        # Calm state: lower HR, higher HRV
        {
            "name": "Calm (resting)",
            "hr_range": (60, 65),
            "rr_base": 950,
            "rr_variation": 50,
            "duration": 30,
        },
        # Stressed state: higher HR, lower HRV
        {
            "name": "Stressed (working)",
            "hr_range": (80, 90),
            "rr_base": 700,
            "rr_variation": 20,
            "duration": 30,
        },
        # Amused state: moderate HR, high HRV
        {
            "name": "Amused (watching comedy)",
            "hr_range": (75, 85),
            "rr_base": 800,
            "rr_variation": 60,
            "duration": 30,
        },
    ]

    import random

    for scenario in scenarios:
        print(f"\n{'='*60}")
        print(f"Scenario: {scenario['name']}")
        print(f"{'='*60}")

        for i in range(scenario["duration"]):
            # Generate random HR within range
            hr = random.uniform(*scenario["hr_range"])

            # Generate RR intervals with variation
            rr_base = scenario["rr_base"]
            rr_var = scenario["rr_variation"]
            rr_intervals = [
                rr_base + random.uniform(-rr_var, rr_var) for _ in range(random.randint(5, 15))
            ]

            yield hr, rr_intervals, datetime.now()

            time.sleep(0.1)  # Simulate real-time delay


def main():
    """Run streaming data example."""
    # Create engine
    config = EmotionConfig(
        window_seconds=10.0,  # Shorter window for faster results in demo
        step_seconds=2.0,  # More frequent updates
    )

    engine = EmotionEngine.from_pretrained(
        config=config,
        on_log=lambda level, msg, ctx: print(f"[{level}] {msg}") if level in ["info", "error"] else None,
    )

    print("=== Streaming Emotion Inference Demo ===")
    print(f"Window: {config.window_seconds}s, Step: {config.step_seconds}s")
    print("Starting data stream...\n")

    # Process streaming data
    for hr, rr_intervals, timestamp in simulate_wearable_stream():
        # Push data to engine
        engine.push(hr=hr, rr_intervals_ms=rr_intervals, timestamp=timestamp)

        # Try to get results
        results = engine.consume_ready()
        if results:
            for result in results:
                print(f"\n>>> RESULT: {result.emotion} ({result.confidence * 100:.1f}%)")
                print(f"    Probabilities: ", end="")
                for emotion, prob in sorted(
                    result.probabilities.items(), key=lambda x: x[1], reverse=True
                ):
                    print(f"{emotion}:{prob*100:.0f}% ", end="")
                print()
                print(f"    Features: HR={result.features['hr_mean']:.1f}, "
                      f"SDNN={result.features['sdnn']:.1f}, "
                      f"RMSSD={result.features['rmssd']:.1f}")

    # Final statistics
    print(f"\n{'='*60}")
    print("Stream ended.")
    stats = engine.get_buffer_stats()
    print(f"Final buffer: {stats['count']} data points, {stats['rr_count']} RR intervals")


if __name__ == "__main__":
    main()
