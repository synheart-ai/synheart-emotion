#!/usr/bin/env python3
"""Command-line interface for synthetic biosignal data generator."""
import argparse
import sys
from datetime import datetime
from pathlib import Path

from syndata import (
    BiosignalGenerator,
    CALM_SCENARIO,
    STRESSED_SCENARIO,
    AMUSED_SCENARIO,
    generate_scenario,
    generate_session,
)
from syndata.exporters import export_all_formats


def main():
    """Run CLI."""
    parser = argparse.ArgumentParser(
        description="Generate synthetic biosignal data for testing Emotion SDKs",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Generate 60 seconds of calm data
  python cli.py --emotion Calm --duration 60 --output ./data

  # Generate a session with multiple emotions
  python cli.py --session Calm Stressed Amused --duration 30 --output ./data

  # Generate with transitions between emotions
  python cli.py --session Calm Stressed --transitions --duration 45 --output ./data

  # Generate reproducible data with seed
  python cli.py --emotion Amused --seed 42 --output ./data

  # Export only specific formats
  python cli.py --emotion Calm --formats python json --output ./data
        """,
    )

    parser.add_argument(
        "--emotion",
        choices=["Calm", "Stressed", "Amused"],
        help="Generate data for a single emotion",
    )
    parser.add_argument(
        "--session",
        nargs="+",
        metavar="EMOTION",
        help="Generate session with multiple emotions (Calm, Stressed, Amused)",
    )
    parser.add_argument(
        "--duration",
        type=int,
        default=60,
        help="Duration in seconds per emotion (default: 60)",
    )
    parser.add_argument(
        "--transitions",
        action="store_true",
        help="Add smooth transitions between emotions in sessions",
    )
    parser.add_argument(
        "--seed",
        type=int,
        help="Random seed for reproducible data",
    )
    parser.add_argument(
        "--output",
        "-o",
        default="./generated_data",
        help="Output directory (default: ./generated_data)",
    )
    parser.add_argument(
        "--formats",
        nargs="+",
        choices=["csv", "json", "python", "kotlin", "swift", "all"],
        default=["all"],
        help="Export formats (default: all)",
    )
    parser.add_argument(
        "--basename",
        default="test_data",
        help="Base name for output files (default: test_data)",
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Verbose output",
    )

    args = parser.parse_args()

    # Validate arguments
    if not args.emotion and not args.session:
        parser.error("Must specify either --emotion or --session")

    if args.emotion and args.session:
        parser.error("Cannot specify both --emotion and --session")

    # Generate data
    print("Generating synthetic biosignal data...")
    print(f"Duration per emotion: {args.duration}s")
    if args.seed is not None:
        print(f"Random seed: {args.seed}")

    try:
        if args.emotion:
            # Single emotion
            print(f"Emotion: {args.emotion}")
            data = generate_scenario(
                emotion=args.emotion,
                duration_seconds=args.duration,
                seed=args.seed,
                start_time=datetime.now(),
            )
        else:
            # Session with multiple emotions
            print(f"Session: {' → '.join(args.session)}")
            if args.transitions:
                print("Including smooth transitions")

            data = generate_session(
                emotions=args.session,
                duration_per_emotion=args.duration,
                include_transitions=args.transitions,
                seed=args.seed,
                start_time=datetime.now(),
            )

        print(f"Generated {len(data)} data points")

        # Calculate statistics
        if args.verbose:
            hr_values = [p["hr"] for p in data]
            rr_counts = [len(p["rr_intervals_ms"]) for p in data]
            print(f"\nStatistics:")
            print(f"  HR range: {min(hr_values):.1f} - {max(hr_values):.1f} BPM")
            print(f"  RR intervals per point: {min(rr_counts)} - {max(rr_counts)}")
            print(f"  Total RR intervals: {sum(rr_counts)}")

        # Export data
        print(f"\nExporting to: {args.output}")

        formats = args.formats
        if "all" in formats:
            outputs = export_all_formats(data, args.output, args.basename)
        else:
            # Export specific formats
            output_path = Path(args.output)
            output_path.mkdir(parents=True, exist_ok=True)
            outputs = {}

            from syndata.exporters import (
                export_to_csv,
                export_to_json,
                export_to_python,
                export_to_kotlin,
                export_to_swift,
            )

            exporters = {
                "csv": export_to_csv,
                "json": export_to_json,
                "python": export_to_python,
                "kotlin": export_to_kotlin,
                "swift": export_to_swift,
            }

            for fmt in formats:
                file_path = output_path / f"{args.basename}.{fmt if fmt != 'python' else 'py'}"
                if fmt == "kotlin":
                    file_path = output_path / f"{args.basename}.kt"
                exporters[fmt](data, str(file_path))
                outputs[fmt] = str(file_path)

        # Print output files
        print("\nGenerated files:")
        for fmt, path in outputs.items():
            print(f"  {fmt:8s}: {path}")

        print("\n✓ Data generation complete!")

    except Exception as e:
        print(f"\n✗ Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
