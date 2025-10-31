"""Basic example of generating synthetic biosignal data."""
from datetime import datetime
from syndata import generate_scenario, generate_session
from syndata.exporters import export_to_json


def main():
    """Generate basic synthetic data."""
    print("=== Basic Synthetic Data Generation ===\n")

    # Example 1: Generate single emotion scenario
    print("1. Generating 30 seconds of calm data...")
    calm_data = generate_scenario(
        emotion="Calm",
        duration_seconds=30,
        seed=42,  # For reproducibility
    )
    print(f"   Generated {len(calm_data)} data points")
    print(f"   First point: HR={calm_data[0]['hr']:.1f} BPM, "
          f"RR intervals={len(calm_data[0]['rr_intervals_ms'])}")

    # Example 2: Generate session with multiple emotions
    print("\n2. Generating session with 3 emotions...")
    session_data = generate_session(
        emotions=["Calm", "Stressed", "Amused"],
        duration_per_emotion=20,
        include_transitions=False,
        seed=123,
    )
    print(f"   Generated {len(session_data)} data points")

    # Show emotion distribution
    emotion_counts = {}
    for point in session_data:
        emotion = point["emotion"]
        emotion_counts[emotion] = emotion_counts.get(emotion, 0) + 1

    print("   Emotion distribution:")
    for emotion, count in emotion_counts.items():
        print(f"     {emotion}: {count} points")

    # Example 3: Export to JSON
    print("\n3. Exporting to JSON...")
    export_to_json(calm_data, "output_calm.json")
    print("   Saved to: output_calm.json")

    print("\n✓ Examples complete!")


if __name__ == "__main__":
    main()
