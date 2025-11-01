#!/usr/bin/env python3
"""
Basic Usage Example - Synheart Emotion SDK

This example demonstrates the most basic usage of the Synheart Emotion SDK:
- Initializing the engine with default configuration
- Pushing biosignal data
- Consuming emotion inference results
"""

from datetime import datetime
import random
from synheart_emotion import EmotionConfig, EmotionEngine


def generate_rr_intervals(hr: float, count: int = 40) -> list[float]:
    """Generate synthetic RR intervals for a given heart rate."""
    mean_rr = 60000.0 / hr  # Convert HR (bpm) to mean RR interval (ms)
    variability = 20.0  # ms
    return [mean_rr + random.uniform(-variability, variability) for _ in range(count)]


def main():
    print("=" * 60)
    print("Synheart Emotion SDK - Basic Usage Example")
    print("=" * 60)
    print()

    # Step 1: Initialize the engine with default configuration
    print("[1] Initializing emotion engine...")
    config = EmotionConfig()
    engine = EmotionEngine.from_pretrained(config)
    print("✓ Engine initialized successfully")
    print(f"   Window: {config.window_seconds}s")
    print(f"   Step: {config.step_seconds}s")
    print()

    # Step 2: Simulate pushing biosignal data
    print("[2] Pushing biosignal data...")
    print()

    # We'll simulate data for a calm state
    calm_hr = 65.0  # Calm heart rate

    for i in range(1, 21):  # Push 20 data points
        hr = calm_hr + random.uniform(-3, 3)
        rr_intervals = generate_rr_intervals(hr)

        engine.push(
            hr=hr,
            rr_intervals_ms=rr_intervals,
            timestamp=datetime.now()
        )

        print(f"   Push #{i:2d}: HR={hr:.1f} bpm, RR intervals={len(rr_intervals)}")

        # Check for results
        results = engine.consume_ready()
        if results:
            result = results[0]
            print()
            print(f"   → Emotion detected: {result.emotion}")
            print(f"   → Confidence: {result.confidence:.1%}")
            print(f"   → Probabilities:")
            for label, prob in sorted(result.probabilities.items(), key=lambda x: x[1], reverse=True):
                print(f"      • {label:8s}: {prob:.1%}")
            print()

    print()

    # Step 3: Check buffer statistics
    print("[3] Buffer statistics:")
    stats = engine.get_buffer_stats()
    print(f"   Data points: {stats['count']}")
    print(f"   Duration: {stats['duration_ms']:.0f}ms")
    print(f"   HR range: {stats['hr_range']}")
    print(f"   RR count: {stats['rr_count']}")
    print()

    # Step 4: Final result consumption
    print("[4] Consuming final results...")
    final_results = engine.consume_ready()
    if final_results:
        result = final_results[0]
        print(f"   Final emotion: {result.emotion} ({result.confidence:.1%})")
    else:
        print("   No more results available")
    print()

    print("=" * 60)
    print("✅ Example completed successfully!")
    print("=" * 60)


if __name__ == "__main__":
    main()
