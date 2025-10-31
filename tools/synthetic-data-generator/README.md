## Synthetic Biosignal Data Generator

Generate realistic synthetic heart rate and RR interval data for testing Synheart Emotion SDKs across all platforms (Python, Android, iOS, Flutter).

## Features

- 🎯 **Realistic Physiological Data**: Generates HR and RR intervals matching real biosignal patterns
- 🎭 **Multiple Emotions**: Pre-configured scenarios for Calm, Stressed, and Amused states
- 🔄 **Smooth Transitions**: Optional gradual transitions between emotional states
- 📊 **Multiple Formats**: Export to CSV, JSON, Python, Kotlin, and Swift
- 🔁 **Reproducible**: Support for random seeds
- 🎨 **Customizable**: Create custom emotion scenarios

## Installation

```bash
cd tools/synthetic-data-generator
pip install -e .
```

Or install dependencies manually:
```bash
pip install numpy  # Optional, only for advanced features
```

## Quick Start

### Command Line

```bash
# Generate 60 seconds of calm data
python cli.py --emotion Calm --duration 60 --output ./data

# Generate a session with multiple emotions
python cli.py --session Calm Stressed Amused --duration 30 --output ./data

# Generate with smooth transitions
python cli.py --session Calm Stressed --transitions --duration 45 --output ./data

# Generate reproducible data
python cli.py --emotion Amused --seed 42 --output ./data

# Export only specific formats
python cli.py --emotion Calm --formats python json --output ./data
```

### Python API

```python
from syndata import generate_scenario, generate_session
from syndata.exporters import export_to_json

# Generate single emotion
data = generate_scenario(
    emotion="Calm",
    duration_seconds=60,
    seed=42
)

# Generate multi-emotion session
session_data = generate_session(
    emotions=["Calm", "Stressed", "Amused"],
    duration_per_emotion=30,
    include_transitions=True,
    seed=123
)

# Export to JSON
export_to_json(data, "output.json")
```

## Emotion Scenarios

### Pre-configured Scenarios

| Emotion | HR Mean | HR Std | RR Mean | RR Std | HRV |
|---------|---------|--------|---------|--------|-----|
| **Calm** | 65 BPM | 5 BPM | 920 ms | 50 ms | High |
| **Stressed** | 85 BPM | 8 BPM | 705 ms | 25 ms | Low |
| **Amused** | 80 BPM | 10 BPM | 750 ms | 60 ms | High |

### Physiological Characteristics

- **Calm**: Lower heart rate, high heart rate variability (relaxed parasympathetic state)
- **Stressed**: Elevated heart rate, low variability (sympathetic activation)
- **Amused**: Moderate heart rate, high variability (positive arousal)

## Export Formats

### CSV Format
```csv
timestamp,hr,emotion,scenario,rr_intervals
2024-10-30T10:00:00,65.2,Calm,Calm - Resting,"920.5,918.3,922.1"
```

### JSON Format
```json
[
  {
    "timestamp": "2024-10-30T10:00:00",
    "hr": 65.2,
    "rr_intervals_ms": [920.5, 918.3, 922.1],
    "emotion": "Calm",
    "scenario": "Calm - Resting"
  }
]
```

### Python Format
```python
test_data = [
    {
        "timestamp": datetime.fromisoformat("2024-10-30T10:00:00"),
        "hr": 65.2,
        "rr_intervals_ms": [920.5, 918.3, 922.1],
        "emotion": "Calm",
        "scenario": "Calm - Resting",
    },
]
```

### Kotlin Format
```kotlin
val testData = listOf(
    DataPoint(
        timestamp = dateFormat.parse("2024-10-30T10:00:00")!!,
        hr = 65.2,
        rrIntervalsMs = listOf(920.5, 918.3, 922.1),
        emotion = "Calm",
        scenario = "Calm - Resting"
    ),
)
```

### Swift Format
```swift
let testData: [TestDataPoint] = [
    TestDataPoint(
        timestamp: ISO8601DateFormatter().date(from: "2024-10-30T10:00:00")!,
        hr: 65.2,
        rrIntervalsMs: [920.5, 918.3, 922.1],
        emotion: "Calm",
        scenario: "Calm - Resting"
    ),
]
```

## Advanced Usage

### Custom Scenarios

```python
from syndata import BiosignalGenerator, EmotionScenario

# Create custom scenario
custom = EmotionScenario(
    name="Exercise - Light Jogging",
    emotion="Exercise",
    hr_mean=120.0,
    hr_std=10.0,
    rr_mean=500.0,
    rr_std=30.0,
    duration_seconds=60
)

generator = BiosignalGenerator(seed=42)
data = generator.generate_scenario(custom)
```

### Smooth Transitions

```python
from syndata import BiosignalGenerator, CALM_SCENARIO, STRESSED_SCENARIO

generator = BiosignalGenerator()
transition = generator.generate_transition(
    from_scenario=CALM_SCENARIO,
    to_scenario=STRESSED_SCENARIO,
    transition_seconds=15
)
```

### Export All Formats

```python
from syndata.exporters import export_all_formats

outputs = export_all_formats(
    data,
    output_dir="./output",
    basename="test_data"
)

# Returns: {'csv': 'path', 'json': 'path', 'python': 'path', ...}
```

## Examples

### Basic Generation
```bash
python examples/basic_generation.py
```

Demonstrates:
- Single emotion generation
- Multi-emotion sessions
- JSON export

### Advanced Generation
```bash
python examples/advanced_generation.py
```

Demonstrates:
- Custom scenarios
- Smooth transitions
- Export to all formats
- SDK test data generation

## Testing SDKs

### Python SDK

```python
from synheart_emotion import EmotionEngine, EmotionConfig

# Load generated test data
from test_data import test_data

# Create engine
config = EmotionConfig()
engine = EmotionEngine.from_pretrained(config)

# Test with synthetic data
for point in test_data:
    engine.push(
        hr=point['hr'],
        rr_intervals_ms=point['rr_intervals_ms'],
        timestamp=point['timestamp']
    )
    results = engine.consume_ready()
    if results:
        print(f"Detected: {results[0].emotion}")
```

### Android SDK

```kotlin
import com.synheart.emotion.*
import com.synheart.emotion.testdata.TestData

val config = EmotionConfig()
val engine = EmotionEngine.fromPretrained(config)

for (point in TestData.testData) {
    engine.push(
        hr = point.hr,
        rrIntervalsMs = point.rrIntervalsMs,
        timestamp = point.timestamp
    )
    val results = engine.consumeReady()
    if (results.isNotEmpty()) {
        println("Detected: ${results[0].emotion}")
    }
}
```

### iOS SDK

```swift
import SynheartEmotion

let config = EmotionConfig()
let engine = try! EmotionEngine.fromPretrained(config: config)

for point in testData {
    engine.push(
        hr: point.hr,
        rrIntervalsMs: point.rrIntervalsMs,
        timestamp: point.timestamp
    )
    let results = engine.consumeReady()
    if !results.isEmpty {
        print("Detected: \(results[0].emotion)")
    }
}
```

## CLI Reference

```
usage: cli.py [-h] [--emotion {Calm,Stressed,Amused}]
              [--session EMOTION [EMOTION ...]]
              [--duration DURATION] [--transitions]
              [--seed SEED] [--output OUTPUT]
              [--formats {csv,json,python,kotlin,swift,all} [...]]
              [--basename BASENAME] [--verbose]

Options:
  --emotion          Generate data for single emotion
  --session          Generate session with multiple emotions
  --duration         Duration in seconds per emotion (default: 60)
  --transitions      Add smooth transitions between emotions
  --seed             Random seed for reproducibility
  --output, -o       Output directory (default: ./generated_data)
  --formats          Export formats (default: all)
  --basename         Base name for output files (default: test_data)
  --verbose, -v      Verbose output
```

## Data Characteristics

### Sampling Rate
- Default: 1 Hz (1 sample per second)
- Configurable up to 10 Hz
- Typical wearable devices: 0.2-1 Hz

### RR Intervals
- Count per sample: 8-15 intervals
- Range: 300-2000 ms (30-200 BPM)
- Maximum jump: 100 ms (for realism)

### Validation
- HR range: 30-200 BPM
- RR range: 300-2000 ms
- Physiological artifact simulation

## Use Cases

1. **SDK Development**: Test emotion inference pipelines
2. **Unit Testing**: Reproducible test data with seeds
3. **Integration Testing**: Multi-platform SDK validation
4. **Performance Testing**: Large datasets for benchmarking
5. **Demo Applications**: Realistic demo data for presentations
6. **Algorithm Validation**: Compare across different implementations

## Architecture

```
syndata/
├── __init__.py          # Package exports
├── generator.py         # Core data generation logic
└── exporters.py         # Format exporters (CSV, JSON, etc.)

examples/
├── basic_generation.py  # Basic usage examples
└── advanced_generation.py  # Advanced features

cli.py                   # Command-line interface
```

## Contributing

To add new export formats:

1. Add exporter function in `syndata/exporters.py`
2. Update `export_all_formats()` function
3. Add CLI option in `cli.py`
4. Update documentation

## License

MIT License - See LICENSE file for details.

## Citation

If you use this tool in research:

```bibtex
@software{synheart_synthetic_data,
  title = {Synthetic Biosignal Data Generator for Emotion Inference},
  author = {Synheart},
  year = {2024},
  version = {0.1.0},
  url = {https://github.com/synheart/synheart-emotion}
}
```
