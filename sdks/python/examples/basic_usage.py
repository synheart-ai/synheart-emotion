"""Basic usage example for synheart-emotion package."""
from datetime import datetime

from synheart_emotion import EmotionConfig, EmotionEngine


def main():
    """Run basic emotion inference example."""
    # Create engine with default configuration
    config = EmotionConfig()
    engine = EmotionEngine.from_pretrained(config)

    # Simulate wearable data
    # In a real application, this would come from a wearable device
    hr_data = [72.0, 73.5, 71.8, 74.2, 72.5]  # Heart rate in BPM
    rr_data = [
        [850.0, 820.0, 830.0, 845.0, 825.0],  # RR intervals in ms
        [855.0, 815.0, 835.0, 840.0, 830.0],
        [848.0, 822.0, 828.0, 842.0, 827.0],
        [852.0, 818.0, 832.0, 838.0, 832.0],
        [850.0, 820.0, 830.0, 845.0, 825.0],
    ]

    # Push data to engine
    for i, (hr, rr_intervals) in enumerate(zip(hr_data, rr_data)):
        timestamp = datetime.now()
        engine.push(
            hr=hr,
            rr_intervals_ms=rr_intervals,
            timestamp=timestamp,
        )
        print(f"Pushed data point {i + 1}: HR={hr}, RR count={len(rr_intervals)}")

    # Get inference results when ready
    results = engine.consume_ready()
    if results:
        for result in results:
            print(f"\n=== Emotion Inference Result ===")
            print(f"Emotion: {result.emotion}")
            print(f"Confidence: {result.confidence * 100:.1f}%")
            print(f"Probabilities:")
            for emotion, prob in result.probabilities.items():
                print(f"  {emotion}: {prob * 100:.1f}%")
            print(f"Features: {result.features}")
    else:
        print("\nNo results ready yet (need more data or time)")

    # Get buffer statistics
    stats = engine.get_buffer_stats()
    print(f"\n=== Buffer Statistics ===")
    print(f"Data points: {stats['count']}")
    print(f"Duration: {stats['duration_ms']}ms")
    print(f"HR range: {stats['hr_range']}")
    print(f"Total RR intervals: {stats['rr_count']}")


if __name__ == "__main__":
    main()
