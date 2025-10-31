# Synheart Emotion - Python SDK

[![Python 3.8+](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![Tests Passing](https://img.shields.io/badge/tests-16%2F16%20passing-brightgreen.svg)](tests/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

On-device emotion inference from biosignals (heart rate and RR intervals) for Python applications.

## Features

- **Privacy-first**: All processing happens on-device
- **Real-time**: <5ms inference latency
- **Three emotion states**: Amused, Calm, Stressed
- **Sliding window**: 60s window with 5s step (configurable)
- **Python 3.8+**: Modern Python with type hints
- **Thread-safe**: Concurrent data ingestion supported
- **Zero dependencies**: Core functionality requires only NumPy and Pandas

## Installation

### From PyPI (recommended)

```bash
pip install synheart-emotion
```

### From source

```bash
git clone https://github.com/synheart/synheart-emotion.git
cd synheart-emotion/sdks/python
pip install -e .
```

### With optional ML dependencies

For advanced model loading (scikit-learn, XGBoost):

```bash
pip install synheart-emotion[ml]
```

### Development installation

```bash
pip install synheart-emotion[dev]
```

### Verify Installation

```bash
# Quick verification
python -c "from synheart_emotion import EmotionEngine, EmotionConfig; print('✓ Installation successful')"

# Run tests
pytest tests/

# Run examples
python examples/basic_usage.py
python examples/cli_demo.py --samples 15
```

### Building from Source

```bash
# Install build tools
pip install build twine

# Build package
python -m build

# This creates:
# - dist/synheart_emotion-0.1.0.tar.gz (source distribution)
# - dist/synheart_emotion-0.1.0-py3-none-any.whl (wheel)
```

### Troubleshooting

**Import Error**: Make sure the package is installed with `pip list | grep synheart-emotion`

**Version Conflicts**: Upgrade dependencies with `pip install --upgrade numpy pandas`

**Missing Dependencies**: Install all requirements with `pip install -r requirements.txt`

## Quick Start

```python
from datetime import datetime
from synheart_emotion import EmotionConfig, EmotionEngine

# Create engine with default configuration
config = EmotionConfig()
engine = EmotionEngine.from_pretrained(config)

# Push data from wearable
engine.push(
    hr=72.0,
    rr_intervals_ms=[850.0, 820.0, 830.0, 845.0, 825.0],
    timestamp=datetime.now()
)

# Get inference result when ready
results = engine.consume_ready()
for result in results:
    print(f"Emotion: {result.emotion}")
    print(f"Confidence: {result.confidence:.1%}")
    print(f"Probabilities: {result.probabilities}")
```

## Examples

### Basic Usage

```python
from datetime import datetime
from synheart_emotion import EmotionConfig, EmotionEngine

# Initialize engine
config = EmotionConfig()
engine = EmotionEngine.from_pretrained(config)

# Simulate wearable data stream
hr_data = [72.0, 73.5, 71.8, 74.2, 72.5]
rr_data = [
    [850.0, 820.0, 830.0, 845.0, 825.0],
    [855.0, 815.0, 835.0, 840.0, 830.0],
    # ... more data
]

# Push data
for hr, rr_intervals in zip(hr_data, rr_data):
    engine.push(
        hr=hr,
        rr_intervals_ms=rr_intervals,
        timestamp=datetime.now()
    )

# Consume results
results = engine.consume_ready()
if results:
    result = results[0]
    print(f"Emotion: {result.emotion} ({result.confidence:.1%})")
```

See the `examples/` directory for more comprehensive examples:
- `basic_usage.py` - Simple emotion inference
- `custom_config.py` - Custom configuration and logging
- `streaming_data.py` - Continuous data stream simulation

### Custom Configuration

```python
config = EmotionConfig(
    window_seconds=60.0,      # 60 second window
    step_seconds=5.0,         # 5 second step
    min_rr_count=30,          # Minimum RR intervals
    hr_baseline=65.0          # Personal HR baseline
)
```

### Logging

```python
def custom_logger(level, message, context):
    print(f"[{level}] {message}")

engine = EmotionEngine.from_pretrained(
    config=config,
    on_log=custom_logger
)
```

### Buffer Management

```python
# Get buffer statistics
stats = engine.get_buffer_stats()
print(f"Data points: {stats['count']}")
print(f"Duration: {stats['duration_ms']}ms")
print(f"HR range: {stats['hr_range']}")
print(f"RR count: {stats['rr_count']}")

# Clear buffer
engine.clear()
```

## API Reference

### EmotionConfig

Configuration for the emotion inference engine.

```python
@dataclass
class EmotionConfig:
    model_id: str = "svm_linear_wrist_sdnn_v1_0"
    window_seconds: float = 60.0
    step_seconds: float = 5.0
    min_rr_count: int = 30
    return_all_probas: bool = True
    hr_baseline: Optional[float] = None
    priors: Optional[Dict[str, float]] = None
```

**Attributes:**

- `model_id` - Model identifier
- `window_seconds` - Rolling window size (default: 60s)
- `step_seconds` - Emission cadence (default: 5s)
- `min_rr_count` - Minimum RR intervals required (default: 30)
- `return_all_probas` - Return all label probabilities (default: True)
- `hr_baseline` - Optional HR baseline for personalization
- `priors` - Optional label priors for calibration

### EmotionEngine

Main emotion inference engine.

**Class Methods:**

```python
@classmethod
def from_pretrained(
    config: EmotionConfig,
    model: Optional[LinearSvmModel] = None,
    on_log: Optional[Callable] = None
) -> EmotionEngine
```

Create engine from pretrained model.

**Instance Methods:**

```python
def push(
    hr: float,
    rr_intervals_ms: List[float],
    timestamp: datetime,
    motion: Optional[Dict[str, float]] = None
) -> None
```

Push new data point into the engine.

```python
def consume_ready() -> List[EmotionResult]
```

Consume ready results (throttled by step interval).

```python
def get_buffer_stats() -> Dict[str, Any]
```

Get current buffer statistics.

```python
def clear() -> None
```

Clear all buffered data.

### EmotionResult

Result of emotion inference.

```python
@dataclass
class EmotionResult:
    timestamp: datetime
    emotion: str
    confidence: float
    probabilities: Dict[str, float]
    features: Dict[str, float]
    model: Dict[str, Any]
```

**Attributes:**

- `timestamp` - Timestamp when inference was performed
- `emotion` - Predicted emotion label (top-1)
- `confidence` - Confidence score (0.0-1.0)
- `probabilities` - All label probabilities
- `features` - Extracted features (hr_mean, sdnn, rmssd)
- `model` - Model metadata

**Methods:**

```python
@classmethod
def from_inference(
    timestamp: datetime,
    probabilities: Dict[str, float],
    features: Dict[str, float],
    model: Dict[str, Any]
) -> EmotionResult
```

Create from raw inference data.

```python
def to_dict() -> Dict[str, Any]
```

Convert to dictionary for JSON serialization.

### FeatureExtractor

Static utility class for feature extraction.

```python
class FeatureExtractor:
    @staticmethod
    def extract_hr_mean(hr_values: List[float]) -> float

    @staticmethod
    def extract_sdnn(rr_intervals_ms: List[float]) -> float

    @staticmethod
    def extract_rmssd(rr_intervals_ms: List[float]) -> float

    @staticmethod
    def extract_features(
        hr_values: List[float],
        rr_intervals_ms: List[float],
        motion: Optional[Dict[str, float]] = None
    ) -> Dict[str, float]
```

### EmotionError

Base exception class with subclasses:

- `TooFewRRError` - Too few RR intervals
- `BadInputError` - Invalid input data
- `ModelIncompatibleError` - Model incompatible with features
- `FeatureExtractionError` - Feature extraction failed

## Running Examples

```bash
# Basic usage
python examples/basic_usage.py

# Custom configuration
python examples/custom_config.py

# Streaming data simulation
python examples/streaming_data.py
```

## Requirements

- Python 3.8+
- NumPy >= 1.21.0
- Pandas >= 1.3.0

Optional (for ML model loading):
- scikit-learn >= 1.0.0
- joblib >= 1.1.0
- xgboost >= 1.5.0

## Architecture

The package follows a modular architecture:

```
synheart_emotion/
├── __init__.py          # Package exports
├── config.py            # Configuration dataclass
├── engine.py            # Main inference engine
├── error.py             # Error classes
├── features.py          # Feature extraction
├── models.py            # Model classes
└── result.py            # Result dataclass
```

### Data Flow

1. **Push** - Biosignal data (HR, RR intervals) pushed to engine
2. **Buffer** - Data stored in sliding window ring buffer
3. **Extract** - Features extracted when window is full
4. **Infer** - Model predicts emotion probabilities
5. **Emit** - Results emitted at configured intervals

### Thread Safety

The engine uses `threading.RLock()` for thread-safe operations:
- Multiple threads can push data concurrently
- Buffer operations are protected
- Results can be consumed from any thread

## Privacy & Security

**IMPORTANT**: This library uses demo placeholder model weights that are NOT trained on real biosignal data. For production use, you must provide your own trained model weights.

All processing happens on-device. No data is sent to external servers.

## Development

### Running Tests

```bash
pytest tests/
```

### Code Formatting

```bash
black src/ examples/ tests/
isort src/ examples/ tests/
```

### Type Checking

```bash
mypy src/
```

## License

See LICENSE file for details.

## Contributing

Contributions are welcome! Please see CONTRIBUTING.md for guidelines.

## Citation

If you use this package in your research, please cite:

```bibtex
@software{synheart_emotion,
  title = {Synheart Emotion: On-device emotion inference from biosignals},
  author = {Synheart},
  year = {2024},
  version = {0.1.0},
  url = {https://github.com/synheart/synheart-emotion}
}
```
