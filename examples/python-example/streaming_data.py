#!/usr/bin/env python3
"""
Streaming Data Example - Synheart Emotion SDK

This example demonstrates continuous data streaming with:
- Simulated real-time biosignal data stream
- Continuous emotion inference
- Live statistics and updates
- Graceful handling of interruption
"""

import signal
import sys
import time
import random
from datetime import datetime
from typing import Optional

from synheart_emotion import EmotionConfig, EmotionEngine


class BiosignalStream:
    """Simulates a continuous biosignal data stream."""

    def __init__(self):
        self.running = False
        self.current_state = 'Calm'
        self.state_change_counter = 0
        self.states = {
            'Calm': {'hr_mean': 60.0, 'hr_var': 8.0},
            'Amused': {'hr_mean': 75.0, 'hr_var': 12.0},
            'Stressed': {'hr_mean': 90.0, 'hr_var': 15.0}
        }

    def start(self):
        """Start the stream."""
        self.running = True

    def stop(self):
        """Stop the stream."""
        self.running = False

    def maybe_change_state(self):
        """Randomly change emotional state."""
        self.state_change_counter += 1

        # Change state every ~30 samples
        if self.state_change_counter % 30 == 0:
            old_state = self.current_state
            self.current_state = random.choice(list(self.states.keys()))

            if old_state != self.current_state:
                print(f"\n🎭 State transition: {old_state} → {self.current_state}")
                print("─" * 60)

    def generate_sample(self) -> tuple[float, list[float]]:
        """Generate a single biosignal sample."""
        state_params = self.states[self.current_state]

        # Generate heart rate
        hr = state_params['hr_mean'] + random.uniform(-5, 5)

        # Generate RR intervals
        mean_rr = 60000.0 / hr
        variability = state_params['hr_var']
        count = random.randint(35, 50)
        rr_intervals = [
            mean_rr + random.uniform(-variability, variability)
            for _ in range(count)
        ]

        return hr, rr_intervals


class StreamingDemo:
    """Main streaming demo coordinator."""

    def __init__(self):
        self.engine: Optional[EmotionEngine] = None
        self.stream: Optional[BiosignalStream] = None
        self.running = False
        self.sample_count = 0
        self.result_count = 0
        self.last_emotion = None

        # Setup signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self.handle_interrupt)
        signal.signal(signal.SIGTERM, self.handle_interrupt)

    def handle_interrupt(self, signum, frame):
        """Handle interrupt signal (Ctrl+C)."""
        print("\n\n⚠️  Interrupt received, shutting down gracefully...")
        self.stop()

    def initialize(self):
        """Initialize the streaming demo."""
        print("=" * 60)
        print("Synheart Emotion SDK - Streaming Data Example")
        print("=" * 60)
        print()
        print("This demo simulates continuous biosignal streaming.")
        print("Press Ctrl+C to stop the stream.\n")

        # Initialize engine
        print("[1] Initializing emotion engine...")
        config = EmotionConfig(
            window_seconds=60.0,
            step_seconds=5.0,
            min_rr_count=30
        )
        self.engine = EmotionEngine.from_pretrained(config)
        print("✓ Engine initialized")
        print(f"   Configuration: {config.window_seconds}s window, {config.step_seconds}s step")
        print()

        # Initialize stream
        print("[2] Initializing biosignal stream...")
        self.stream = BiosignalStream()
        print("✓ Stream ready")
        print()

        self.running = True

    def process_sample(self):
        """Process a single sample from the stream."""
        # Generate sample
        hr, rr_intervals = self.stream.generate_sample()

        # Push to engine
        self.engine.push(
            hr=hr,
            rr_intervals_ms=rr_intervals,
            timestamp=datetime.now()
        )

        self.sample_count += 1

        # Consume results
        results = self.engine.consume_ready()

        if results:
            result = results[0]
            self.result_count += 1
            self.last_emotion = result.emotion

            # Display result
            emoji_map = {'Calm': '😌', 'Amused': '😊', 'Stressed': '😰'}
            emoji = emoji_map.get(result.emotion, '🤔')

            print(f"\n📊 Inference #{self.result_count} (Sample #{self.sample_count})")
            print(f"   {emoji} Emotion: {result.emotion}")
            print(f"   🎯 Confidence: {result.confidence:.1%}")
            print(f"   💓 HR: {hr:.1f} bpm")
            print(f"   📈 Probabilities: ", end='')

            probs_str = ", ".join([
                f"{label}: {prob:.0%}"
                for label, prob in sorted(
                    result.probabilities.items(),
                    key=lambda x: x[1],
                    reverse=True
                )
            ])
            print(probs_str)

            # Show features
            if 'hr_mean' in result.features:
                print(f"   🔬 Features: HR={result.features['hr_mean']:.1f}, "
                      f"SDNN={result.features.get('sdnn', 0):.1f}, "
                      f"RMSSD={result.features.get('rmssd', 0):.1f}")
        else:
            # Show progress
            print(f"\rSample #{self.sample_count:4d} | "
                  f"HR: {hr:5.1f} bpm | "
                  f"RR: {len(rr_intervals):2d} intervals | "
                  f"Last: {self.last_emotion or 'N/A':8s}",
                  end='', flush=True)

    def run(self):
        """Run the streaming demo."""
        self.initialize()

        print("[3] Starting continuous stream...")
        print("    (Press Ctrl+C to stop)\n")
        print("─" * 60)

        self.stream.start()

        try:
            while self.running and self.stream.running:
                # Maybe change state
                self.stream.maybe_change_state()

                # Process sample
                self.process_sample()

                # Simulate real-time delay (e.g., 1 sample per second)
                time.sleep(1.0)

        except Exception as e:
            print(f"\n\n❌ Error: {e}")
            import traceback
            traceback.print_exc()

        finally:
            self.stop()

    def stop(self):
        """Stop the streaming demo."""
        if not self.running:
            return

        self.running = False

        if self.stream:
            self.stream.stop()

        print("\n")
        print("─" * 60)
        print("\n[4] Stream stopped. Final statistics:")

        if self.engine:
            stats = self.engine.get_buffer_stats()
            print(f"   📊 Total samples processed: {self.sample_count}")
            print(f"   🎯 Total inferences: {self.result_count}")
            print(f"   📦 Buffer data points: {stats['count']}")
            print(f"   ⏱️  Buffer duration: {stats['duration_ms']:.0f}ms")
            print(f"   💓 HR range: {stats['hr_range']}")
            print(f"   📊 RR count: {stats['rr_count']}")

        print()
        print("=" * 60)
        print("✅ Streaming demo completed")
        print("=" * 60)
        print()


def main():
    demo = StreamingDemo()
    demo.run()


if __name__ == "__main__":
    main()
