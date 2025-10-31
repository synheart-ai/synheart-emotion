"""Advanced example with custom scenarios and transitions."""
from datetime import datetime
from syndata import BiosignalGenerator, EmotionScenario
from syndata.exporters import export_all_formats


def main():
    """Generate advanced synthetic data."""
    print("=== Advanced Synthetic Data Generation ===\n")

    # Create custom scenario
    custom_scenario = EmotionScenario(
        name="Exercise - Light Jogging",
        emotion="Exercise",
        hr_mean=120.0,
        hr_std=10.0,
        rr_mean=500.0,  # ~120 BPM
        rr_std=30.0,
        duration_seconds=60,
        samples_per_second=2.0,  # 2 Hz sampling
    )

    generator = BiosignalGenerator(seed=42)

    # Generate custom scenario
    print("1. Generating custom exercise scenario...")
    exercise_data = generator.generate_scenario(custom_scenario)
    print(f"   Generated {len(exercise_data)} data points")
    print(f"   HR range: {min(p['hr'] for p in exercise_data):.1f} - "
          f"{max(p['hr'] for p in exercise_data):.1f} BPM")

    # Generate with smooth transitions
    print("\n2. Generating data with smooth transitions...")
    from syndata import CALM_SCENARIO, STRESSED_SCENARIO, AMUSED_SCENARIO

    transition_data = []

    # Calm → Stressed
    print("   Calm → Stressed transition...")
    trans1 = generator.generate_transition(
        CALM_SCENARIO,
        STRESSED_SCENARIO,
        transition_seconds=15,
    )
    transition_data.extend(trans1)

    # Stressed → Amused
    print("   Stressed → Amused transition...")
    trans2 = generator.generate_transition(
        STRESSED_SCENARIO,
        AMUSED_SCENARIO,
        transition_seconds=15,
        start_time=trans1[-1]["timestamp"],
    )
    transition_data.extend(trans2)

    print(f"   Generated {len(transition_data)} transition points")

    # Analyze transition
    print("\n3. Analyzing transitions...")
    hr_values = [p["hr"] for p in transition_data]
    print(f"   HR progression: {hr_values[0]:.1f} → {hr_values[-1]:.1f} BPM")

    # Export all formats
    print("\n4. Exporting in all formats...")
    outputs = export_all_formats(
        transition_data,
        output_dir="./advanced_output",
        basename="transition_data",
    )

    print("   Generated files:")
    for fmt, path in outputs.items():
        print(f"     {fmt}: {path}")

    # Generate test dataset for SDK testing
    print("\n5. Generating complete test dataset...")
    test_data = []

    # Add each emotion type
    for scenario in [CALM_SCENARIO, STRESSED_SCENARIO, AMUSED_SCENARIO]:
        scenario_copy = EmotionScenario(
            name=scenario.name,
            emotion=scenario.emotion,
            hr_mean=scenario.hr_mean,
            hr_std=scenario.hr_std,
            rr_mean=scenario.rr_mean,
            rr_std=scenario.rr_std,
            duration_seconds=30,
        )
        data = generator.generate_scenario(scenario_copy)
        test_data.extend(data)

    print(f"   Generated {len(test_data)} test points")

    # Export test data
    from syndata.exporters import export_to_python, export_to_kotlin, export_to_swift

    export_to_python(test_data, "./advanced_output/sdk_test_data.py")
    export_to_kotlin(test_data, "./advanced_output/sdk_test_data.kt")
    export_to_swift(test_data, "./advanced_output/sdk_test_data.swift")

    print("   Test data exported for all SDKs")

    print("\n✓ Advanced generation complete!")


if __name__ == "__main__":
    main()
