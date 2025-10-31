"""Synthetic Biosignal Data Generator for Testing Emotion SDKs.

This package generates realistic synthetic heart rate and RR interval data
for testing the Synheart Emotion SDKs across all platforms.
"""

__version__ = "0.1.0"

from .generator import (
    BiosignalGenerator,
    EmotionScenario,
    generate_scenario,
    generate_session,
    CALM_SCENARIO,
    STRESSED_SCENARIO,
    AMUSED_SCENARIO,
)
from .exporters import (
    export_to_csv,
    export_to_json,
    export_to_python,
    export_to_kotlin,
    export_to_swift,
    export_all_formats,
)

__all__ = [
    "BiosignalGenerator",
    "EmotionScenario",
    "generate_scenario",
    "generate_session",
    "CALM_SCENARIO",
    "STRESSED_SCENARIO",
    "AMUSED_SCENARIO",
    "export_to_csv",
    "export_to_json",
    "export_to_python",
    "export_to_kotlin",
    "export_to_swift",
    "export_all_formats",
]
