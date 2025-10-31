"""Core biosignal data generator."""
import random
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple


@dataclass
class EmotionScenario:
    """Configuration for an emotion scenario.

    Attributes:
        name: Scenario name (e.g., "Calm - Resting")
        emotion: Target emotion (Calm, Stressed, Amused)
        hr_mean: Mean heart rate in BPM
        hr_std: Heart rate standard deviation
        rr_mean: Mean RR interval in milliseconds
        rr_std: RR interval standard deviation
        duration_seconds: Scenario duration
        samples_per_second: Data sampling rate
    """

    name: str
    emotion: str
    hr_mean: float
    hr_std: float
    rr_mean: float
    rr_std: float
    duration_seconds: int = 30
    samples_per_second: float = 1.0


# Predefined emotion scenarios based on physiological research
CALM_SCENARIO = EmotionScenario(
    name="Calm - Resting",
    emotion="Calm",
    hr_mean=65.0,
    hr_std=5.0,
    rr_mean=920.0,  # ~65 BPM
    rr_std=50.0,  # High HRV
    duration_seconds=60,
)

STRESSED_SCENARIO = EmotionScenario(
    name="Stressed - Working",
    emotion="Stressed",
    hr_mean=85.0,
    hr_std=8.0,
    rr_mean=705.0,  # ~85 BPM
    rr_std=25.0,  # Low HRV
    duration_seconds=60,
)

AMUSED_SCENARIO = EmotionScenario(
    name="Amused - Laughing",
    emotion="Amused",
    hr_mean=80.0,
    hr_std=10.0,
    rr_mean=750.0,  # ~80 BPM
    rr_std=60.0,  # High HRV
    duration_seconds=60,
)


class BiosignalGenerator:
    """Generate synthetic biosignal data for testing."""

    def __init__(self, seed: Optional[int] = None):
        """Initialize generator with optional random seed.

        Args:
            seed: Random seed for reproducibility
        """
        if seed is not None:
            random.seed(seed)

    def generate_hr_sample(self, mean: float, std: float) -> float:
        """Generate a single heart rate sample.

        Args:
            mean: Mean heart rate in BPM
            std: Standard deviation

        Returns:
            Heart rate value in BPM (clamped to physiological range)
        """
        hr = random.gauss(mean, std)
        return max(30.0, min(200.0, hr))  # Clamp to valid range

    def generate_rr_intervals(
        self, mean: float, std: float, count: int = 10
    ) -> List[float]:
        """Generate RR intervals.

        Args:
            mean: Mean RR interval in milliseconds
            std: Standard deviation
            count: Number of intervals to generate

        Returns:
            List of RR intervals in milliseconds
        """
        intervals = []
        prev_interval = mean

        for _ in range(count):
            # Generate with some correlation to previous interval (more realistic)
            target = random.gauss(mean, std)
            # Limit jump size for physiological realism
            max_jump = 100.0
            if abs(target - prev_interval) > max_jump:
                target = prev_interval + random.choice([-1, 1]) * random.uniform(0, max_jump)

            # Clamp to valid range (300-2000ms)
            interval = max(300.0, min(2000.0, target))
            intervals.append(interval)
            prev_interval = interval

        return intervals

    def generate_scenario(
        self, scenario: EmotionScenario, start_time: Optional[datetime] = None
    ) -> List[Dict]:
        """Generate data for a complete emotion scenario.

        Args:
            scenario: Emotion scenario configuration
            start_time: Starting timestamp (defaults to now)

        Returns:
            List of data points with timestamp, HR, and RR intervals
        """
        if start_time is None:
            start_time = datetime.now()

        data_points = []
        total_samples = int(scenario.duration_seconds * scenario.samples_per_second)

        for i in range(total_samples):
            timestamp = start_time + timedelta(
                seconds=i / scenario.samples_per_second
            )

            hr = self.generate_hr_sample(scenario.hr_mean, scenario.hr_std)
            rr_intervals = self.generate_rr_intervals(
                scenario.rr_mean,
                scenario.rr_std,
                count=random.randint(8, 15),
            )

            data_points.append(
                {
                    "timestamp": timestamp,
                    "hr": hr,
                    "rr_intervals_ms": rr_intervals,
                    "emotion": scenario.emotion,
                    "scenario": scenario.name,
                }
            )

        return data_points

    def generate_session(
        self, scenarios: List[EmotionScenario], start_time: Optional[datetime] = None
    ) -> List[Dict]:
        """Generate data for a session with multiple scenarios.

        Args:
            scenarios: List of emotion scenarios
            start_time: Starting timestamp (defaults to now)

        Returns:
            Combined list of data points from all scenarios
        """
        if start_time is None:
            start_time = datetime.now()

        all_data = []
        current_time = start_time

        for scenario in scenarios:
            scenario_data = self.generate_scenario(scenario, current_time)
            all_data.extend(scenario_data)

            # Update time for next scenario
            if scenario_data:
                current_time = scenario_data[-1]["timestamp"] + timedelta(seconds=1)

        return all_data

    def generate_transition(
        self,
        from_scenario: EmotionScenario,
        to_scenario: EmotionScenario,
        transition_seconds: int = 15,
        start_time: Optional[datetime] = None,
    ) -> List[Dict]:
        """Generate data with gradual transition between scenarios.

        Args:
            from_scenario: Starting scenario
            to_scenario: Target scenario
            transition_seconds: Duration of transition
            start_time: Starting timestamp

        Returns:
            List of data points with gradual transition
        """
        if start_time is None:
            start_time = datetime.now()

        data_points = []
        total_samples = transition_seconds

        for i in range(total_samples):
            # Linear interpolation factor (0 to 1)
            factor = i / (total_samples - 1) if total_samples > 1 else 1.0

            # Interpolate parameters
            hr_mean = from_scenario.hr_mean + factor * (
                to_scenario.hr_mean - from_scenario.hr_mean
            )
            hr_std = from_scenario.hr_std + factor * (
                to_scenario.hr_std - from_scenario.hr_std
            )
            rr_mean = from_scenario.rr_mean + factor * (
                to_scenario.rr_mean - from_scenario.rr_mean
            )
            rr_std = from_scenario.rr_std + factor * (
                to_scenario.rr_std - from_scenario.rr_std
            )

            timestamp = start_time + timedelta(seconds=i)
            hr = self.generate_hr_sample(hr_mean, hr_std)
            rr_intervals = self.generate_rr_intervals(
                rr_mean, rr_std, count=random.randint(8, 15)
            )

            data_points.append(
                {
                    "timestamp": timestamp,
                    "hr": hr,
                    "rr_intervals_ms": rr_intervals,
                    "emotion": f"{from_scenario.emotion}→{to_scenario.emotion}",
                    "scenario": f"Transition ({int(factor * 100)}%)",
                }
            )

        return data_points


# Convenience functions
def generate_scenario(
    emotion: str,
    duration_seconds: int = 60,
    seed: Optional[int] = None,
    start_time: Optional[datetime] = None,
) -> List[Dict]:
    """Generate data for a single emotion scenario.

    Args:
        emotion: Emotion type (Calm, Stressed, Amused)
        duration_seconds: Duration in seconds
        seed: Random seed for reproducibility
        start_time: Starting timestamp

    Returns:
        List of data points
    """
    scenarios = {
        "Calm": CALM_SCENARIO,
        "Stressed": STRESSED_SCENARIO,
        "Amused": AMUSED_SCENARIO,
    }

    if emotion not in scenarios:
        raise ValueError(f"Unknown emotion: {emotion}. Use: {list(scenarios.keys())}")

    scenario = scenarios[emotion]
    scenario.duration_seconds = duration_seconds

    generator = BiosignalGenerator(seed=seed)
    return generator.generate_scenario(scenario, start_time)


def generate_session(
    emotions: List[str],
    duration_per_emotion: int = 60,
    include_transitions: bool = False,
    seed: Optional[int] = None,
    start_time: Optional[datetime] = None,
) -> List[Dict]:
    """Generate data for a session with multiple emotions.

    Args:
        emotions: List of emotion types
        duration_per_emotion: Duration for each emotion in seconds
        include_transitions: Add smooth transitions between emotions
        seed: Random seed for reproducibility
        start_time: Starting timestamp

    Returns:
        List of data points
    """
    scenarios_map = {
        "Calm": CALM_SCENARIO,
        "Stressed": STRESSED_SCENARIO,
        "Amused": AMUSED_SCENARIO,
    }

    scenarios = []
    for emotion in emotions:
        if emotion not in scenarios_map:
            raise ValueError(f"Unknown emotion: {emotion}")
        scenario = scenarios_map[emotion]
        scenario.duration_seconds = duration_per_emotion
        scenarios.append(scenario)

    generator = BiosignalGenerator(seed=seed)

    if not include_transitions:
        return generator.generate_session(scenarios, start_time)

    # Generate with transitions
    all_data = []
    current_time = start_time or datetime.now()

    for i, scenario in enumerate(scenarios):
        # Generate scenario data
        scenario_data = generator.generate_scenario(scenario, current_time)
        all_data.extend(scenario_data)

        if scenario_data:
            current_time = scenario_data[-1]["timestamp"] + timedelta(seconds=1)

        # Add transition to next scenario
        if i < len(scenarios) - 1:
            transition_data = generator.generate_transition(
                scenario, scenarios[i + 1], transition_seconds=15, start_time=current_time
            )
            all_data.extend(transition_data)
            if transition_data:
                current_time = transition_data[-1]["timestamp"] + timedelta(seconds=1)

    return all_data
