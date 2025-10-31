"""Example of testing SDK with generated synthetic data."""
import sys
from pathlib import Path

# Add SDK to path
sdk_path = Path(__file__).parent.parent.parent.parent / "sdks" / "python" / "src"
sys.path.insert(0, str(sdk_path))

from syndata import generate_session
from synheart_emotion import EmotionEngine, EmotionConfig


def main():
    """Test SDK with synthetic data."""
    print("=== Testing SDK with Synthetic Data ===\n")

    # Generate synthetic test data
    print("1. Generating synthetic data...")
    test_data = generate_session(
        emotions=["Calm", "Stressed", "Amused"],
        duration_per_emotion=20,
        include_transitions=True,
        seed=42,
    )
    print(f"   Generated {len(test_data)} data points")

    # Create emotion engine
    print("\n2. Creating emotion engine...")
    config = EmotionConfig(
        window_seconds=10,  # Shorter for faster results
        step_seconds=2,
    )
    engine = EmotionEngine.from_pretrained(config)
    print("   Engine initialized")

    # Feed data to engine
    print("\n3. Processing data through engine...")
    results_count = 0
    emotion_detections = {}

    for i, point in enumerate(test_data):
        engine.push(
            hr=point["hr"],
            rr_intervals_ms=point["rr_intervals_ms"],
            timestamp=point["timestamp"],
        )

        # Check for results
        results = engine.consume_ready()
        if results:
            for result in results:
                results_count += 1
                detected = result.emotion
                emotion_detections[detected] = emotion_detections.get(detected, 0) + 1

                print(f"\n   Result #{results_count}:")
                print(f"     Detected: {result.emotion} ({result.confidence * 100:.1f}%)")
                print(f"     Expected: {point['emotion']}")
                print(f"     Probabilities:")
                for emotion, prob in sorted(
                    result.probabilities.items(), key=lambda x: x[1], reverse=True
                ):
                    print(f"       {emotion}: {prob * 100:.1f}%")

    # Summary
    print(f"\n{'='*60}")
    print("Summary:")
    print(f"  Total data points processed: {len(test_data)}")
    print(f"  Inference results emitted: {results_count}")
    print(f"\n  Emotion detections:")
    for emotion, count in sorted(emotion_detections.items()):
        print(f"    {emotion}: {count} times")

    # Buffer stats
    stats = engine.get_buffer_stats()
    print(f"\n  Final buffer stats:")
    print(f"    Data points: {stats['count']}")
    print(f"    Duration: {stats['duration_ms']}ms")
    print(f"    Total RR intervals: {stats['rr_count']}")

    print(f"{'='*60}")
    print("\n✓ SDK testing complete!")


if __name__ == "__main__":
    try:
        main()
    except ImportError as e:
        print(f"Error: Could not import SDK. Make sure it's installed.")
        print(f"  {e}")
        print("\nInstall the SDK with:")
        print("  cd sdks/python && pip install -e .")
        sys.exit(1)
