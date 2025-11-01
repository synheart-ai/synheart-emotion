#!/usr/bin/env python3
"""
Interactive CLI Demo - Synheart Emotion SDK

This example provides an interactive command-line interface that:
- Simulates different emotional states (Calm, Amused, Stressed)
- Displays real-time emotion inference with visual feedback
- Shows probabilities as progress bars
- Demonstrates continuous data streaming
"""

import argparse
import random
import time
from datetime import datetime
from typing import Dict

from synheart_emotion import EmotionConfig, EmotionEngine


# ANSI color codes for terminal output
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'


class EmotionScenario:
    """Represents an emotional state with characteristic biosignals."""

    def __init__(self, name: str, emoji: str, hr_mean: float, hr_variability: float):
        self.name = name
        self.emoji = emoji
        self.hr_mean = hr_mean
        self.hr_variability = hr_variability

    def generate_hr(self) -> float:
        """Generate heart rate for this scenario."""
        return self.hr_mean + random.uniform(-5, 5)

    def generate_rr_intervals(self, hr: float) -> list[float]:
        """Generate RR intervals for given heart rate."""
        mean_rr = 60000.0 / hr
        count = random.randint(35, 50)
        return [
            mean_rr + random.uniform(-self.hr_variability, self.hr_variability)
            for _ in range(count)
        ]


def create_scenarios() -> Dict[str, EmotionScenario]:
    """Create emotion scenario definitions."""
    return {
        'Calm': EmotionScenario('Calm', '😌', hr_mean=60.0, hr_variability=8.0),
        'Amused': EmotionScenario('Amused', '😊', hr_mean=75.0, hr_variability=12.0),
        'Stressed': EmotionScenario('Stressed', '😰', hr_mean=90.0, hr_variability=15.0)
    }


def print_header():
    """Print the demo header."""
    print()
    print(f"{Colors.BOLD}{Colors.CYAN}╔════════════════════════════════════════════════════════════╗{Colors.END}")
    print(f"{Colors.BOLD}{Colors.CYAN}║       Synheart Emotion SDK - Interactive CLI Demo        ║{Colors.END}")
    print(f"{Colors.BOLD}{Colors.CYAN}╚════════════════════════════════════════════════════════════╝{Colors.END}")
    print()


def print_progress_bar(label: str, value: float, width: int = 30):
    """Print a progress bar for probability visualization."""
    filled = int(value * width)
    bar = '█' * filled + '░' * (width - filled)
    percent = int(value * 100)

    # Color based on value
    if value > 0.6:
        color = Colors.GREEN
    elif value > 0.3:
        color = Colors.YELLOW
    else:
        color = Colors.RED

    print(f"      {label:10s} {color}{bar}{Colors.END} {percent:3d}%")


def run_simulation(engine: EmotionEngine, scenario: EmotionScenario, samples: int):
    """Run simulation for a given scenario."""
    print(f"\n{Colors.BOLD}🎭 Simulating {scenario.emoji} {scenario.name} state...{Colors.END}")
    print(f"   HR: ~{int(scenario.hr_mean)} bpm (±{int(scenario.hr_variability)} ms variability)")
    print()

    results_count = 0

    for i in range(1, samples + 1):
        # Generate biosignal data
        hr = scenario.generate_hr()
        rr_intervals = scenario.generate_rr_intervals(hr)

        # Push to engine
        engine.push(
            hr=hr,
            rr_intervals_ms=rr_intervals,
            timestamp=datetime.now()
        )

        # Check for results
        results = engine.consume_ready()

        if results:
            result = results[0]
            results_count += 1

            # Clear previous lines (for cleaner output)
            print(f"\r{Colors.BOLD}   Sample {i}/{samples}{Colors.END}", end='', flush=True)
            print()

            # Display result
            emoji_map = {'Calm': '😌', 'Amused': '😊', 'Stressed': '😰'}
            detected_emoji = emoji_map.get(result.emotion, '🤔')

            print(f"   {Colors.BOLD}{Colors.GREEN}📊 Result #{results_count}:{Colors.END}")
            print(f"      {detected_emoji} Emotion: {Colors.BOLD}{result.emotion}{Colors.END}")
            print(f"      🎯 Confidence: {Colors.BOLD}{result.confidence:.1%}{Colors.END}")
            print(f"      📈 Probabilities:")

            # Sort probabilities by value
            sorted_probs = sorted(
                result.probabilities.items(),
                key=lambda x: x[1],
                reverse=True
            )

            for label, prob in sorted_probs:
                print_progress_bar(label, prob)

            print()
            time.sleep(0.5)  # Slight delay for readability
        else:
            # Show progress without result
            print(f"\r{Colors.BOLD}   Sample {i}/{samples}{Colors.END} - Building buffer...", end='', flush=True)

        time.sleep(0.1)  # Simulate real-time data collection

    print()  # New line after progress


def main():
    parser = argparse.ArgumentParser(
        description='Interactive CLI demo of Synheart Emotion SDK',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python cli_demo.py --samples 15               # Run with 15 samples per state
  python cli_demo.py --scenario Calm             # Run only Calm scenario
  python cli_demo.py --samples 20 --window 45   # Custom samples and window
        """
    )

    parser.add_argument(
        '--samples',
        type=int,
        default=20,
        help='Number of data samples to push per scenario (default: 20)'
    )

    parser.add_argument(
        '--scenario',
        choices=['Calm', 'Amused', 'Stressed'],
        help='Run only a specific scenario (default: all)'
    )

    parser.add_argument(
        '--window',
        type=float,
        default=60.0,
        help='Window size in seconds (default: 60)'
    )

    parser.add_argument(
        '--step',
        type=float,
        default=5.0,
        help='Step size in seconds (default: 5)'
    )

    args = parser.parse_args()

    # Print header
    print_header()

    # Initialize engine
    print(f"{Colors.BOLD}[1] Initializing emotion engine...{Colors.END}")
    config = EmotionConfig(
        window_seconds=args.window,
        step_seconds=args.step
    )
    engine = EmotionEngine.from_pretrained(config)
    print(f"{Colors.GREEN}✓{Colors.END} Engine initialized")
    print(f"   Window: {config.window_seconds}s, Step: {config.step_seconds}s")

    # Create scenarios
    scenarios = create_scenarios()

    # Run scenarios
    print(f"\n{Colors.BOLD}[2] Running emotion simulations...{Colors.END}")

    if args.scenario:
        # Run single scenario
        scenario = scenarios[args.scenario]
        run_simulation(engine, scenario, args.samples)
    else:
        # Run all scenarios
        for scenario in scenarios.values():
            run_simulation(engine, scenario, args.samples)

            # Clear buffer between scenarios
            if scenario != list(scenarios.values())[-1]:
                engine.clear()
                print(f"{Colors.YELLOW}🧹 Buffer cleared for next scenario{Colors.END}\n")
                print("─" * 60)

    # Final statistics
    print(f"\n{Colors.BOLD}[3] Final buffer statistics:{Colors.END}")
    stats = engine.get_buffer_stats()
    print(f"   📦 Data points: {stats['count']}")
    print(f"   ⏱️  Duration: {stats['duration_ms']:.0f}ms")
    print(f"   💓 HR range: {stats['hr_range']}")
    print(f"   📊 RR count: {stats['rr_count']}")

    print()
    print(f"{Colors.BOLD}{Colors.GREEN}✅ Demo completed successfully!{Colors.END}")
    print()


if __name__ == "__main__":
    main()
