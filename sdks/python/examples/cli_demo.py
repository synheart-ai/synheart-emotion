#!/usr/bin/env python
"""Command-line demo for synheart-emotion package."""
import argparse
import random
from datetime import datetime

from synheart_emotion import EmotionConfig, EmotionEngine


def main():
    """Run CLI demo."""
    parser = argparse.ArgumentParser(
        description="Synheart Emotion - CLI Demo",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Run with default settings
  python cli_demo.py

  # Run with custom configuration
  python cli_demo.py --window 30 --step 3 --samples 50

  # Enable verbose logging
  python cli_demo.py --verbose
        """,
    )

    parser.add_argument(
        "--window",
        type=float,
        default=10.0,
        help="Window size in seconds (default: 10)",
    )
    parser.add_argument(
        "--step",
        type=float,
        default=2.0,
        help="Step size in seconds (default: 2)",
    )
    parser.add_argument(
        "--samples",
        type=int,
        default=30,
        help="Number of samples to generate (default: 30)",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose logging",
    )

    args = parser.parse_args()

    # Configure engine
    config = EmotionConfig(
        window_seconds=args.window,
        step_seconds=args.step,
    )

    # Logger
    def logger(level, message, context):
        if args.verbose or level in ["info", "error"]:
            print(f"[{level.upper():5s}] {message}")

    # Create engine
    engine = EmotionEngine.from_pretrained(config=config, on_log=logger)

    print("=" * 70)
    print("Synheart Emotion - CLI Demo")
    print("=" * 70)
    print(f"Configuration: {config}")
    print(f"Samples to generate: {args.samples}")
    print("=" * 70)
    print()

    # Generate and process samples
    results_count = 0

    for i in range(args.samples):
        # Generate random but plausible data
        hr = random.uniform(60, 90)
        rr_intervals = [
            random.uniform(700, 1000) for _ in range(random.randint(5, 15))
        ]

        # Push to engine
        engine.push(
            hr=hr,
            rr_intervals_ms=rr_intervals,
            timestamp=datetime.now(),
        )

        if args.verbose:
            print(f"Sample {i+1:3d}: HR={hr:5.1f}, RR count={len(rr_intervals):2d}")

        # Try to get results
        results = engine.consume_ready()
        if results:
            results_count += len(results)
            for result in results:
                print()
                print("┌" + "─" * 68 + "┐")
                print(f"│ EMOTION DETECTED: {result.emotion:30s}               │")
                print("├" + "─" * 68 + "┤")
                print(f"│ Confidence: {result.confidence*100:5.1f}%                                                   │")
                print("│ Probabilities:                                                   │")
                for emotion, prob in sorted(
                    result.probabilities.items(), key=lambda x: x[1], reverse=True
                ):
                    bar = "█" * int(prob * 40)
                    print(f"│   {emotion:10s} {prob*100:5.1f}% [{bar:40s}] │")
                print("│ Features:                                                        │")
                print(f"│   HR Mean:  {result.features['hr_mean']:6.1f} BPM                                        │")
                print(f"│   SDNN:     {result.features['sdnn']:6.1f} ms                                         │")
                print(f"│   RMSSD:    {result.features['rmssd']:6.1f} ms                                         │")
                print("└" + "─" * 68 + "┘")
                print()

    # Final statistics
    stats = engine.get_buffer_stats()
    print()
    print("=" * 70)
    print("Final Statistics")
    print("=" * 70)
    print(f"Total samples processed:  {args.samples}")
    print(f"Results emitted:          {results_count}")
    print(f"Buffer data points:       {stats['count']}")
    print(f"Buffer duration:          {stats['duration_ms']}ms")
    print(f"Total RR intervals:       {stats['rr_count']}")
    if stats['count'] > 0:
        print(f"HR range:                 {stats['hr_range'][0]:.1f} - {stats['hr_range'][1]:.1f} BPM")
    print("=" * 70)


if __name__ == "__main__":
    main()
