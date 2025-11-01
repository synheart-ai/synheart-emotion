# Synheart Emotion - Python Examples

This directory contains comprehensive examples demonstrating the Synheart Emotion SDK for Python.

## 📁 Examples Overview

### 1. **basic_usage.py** - Getting Started
The simplest example showing core functionality:
- Engine initialization with default config
- Pushing biosignal data
- Consuming emotion results
- Buffer statistics

**Best for**: First-time users, quick testing

```bash
python basic_usage.py
```

**Output**: Step-by-step walkthrough with emotion detection results

---

### 2. **cli_demo.py** - Interactive CLI Demo
Feature-rich interactive demonstration with:
- Visual progress bars for probabilities
- Colored terminal output
- Multiple emotional state simulations
- Configurable parameters via command-line

**Best for**: Understanding SDK capabilities, demonstrations

```bash
# Run with defaults (20 samples per state)
python cli_demo.py

# Run with custom samples
python cli_demo.py --samples 30

# Run only Calm scenario
python cli_demo.py --scenario Calm

# Custom window and step
python cli_demo.py --window 45 --step 3

# See all options
python cli_demo.py --help
```

**Features**:
- 🎨 Color-coded output
- 📊 Real-time probability visualization
- 🎭 Automatic state transitions (Calm → Amused → Stressed)
- ⚙️  Configurable via CLI arguments

---

### 3. **streaming_data.py** - Continuous Data Stream
Simulates real-world continuous biosignal streaming:
- Continuous data generation
- Real-time emotion inference
- Live statistics updates
- Graceful interrupt handling (Ctrl+C)
- Automatic emotional state transitions

**Best for**: Understanding real-time use cases, testing continuous operation

```bash
python streaming_data.py
```

**Press Ctrl+C to stop the stream**

**Features**:
- ⏱️ Real-time simulation (1 sample/second)
- 🔄 Automatic state changes every ~30 samples
- 📈 Live inference updates
- 🛑 Graceful shutdown on interrupt

---

### 4. **custom_config.py** - Advanced Configuration
Comprehensive guide to advanced features:
- Custom engine configuration (window, step, thresholds)
- Custom logging with filtering
- Buffer management and inspection
- Error handling examples
- Personalization (HR baseline, priors)

**Best for**: Production integration, advanced users

```bash
python custom_config.py
```

**Demonstrates**:
1. **Custom Configuration**: Shorter windows, custom thresholds
2. **Custom Logging**: Multi-level logging with colored output
3. **Buffer Management**: Inspecting and clearing buffers
4. **Error Handling**: Handling edge cases and invalid data
5. **Personalization**: Using HR baselines and priors

---

## 🚀 Quick Start

### Prerequisites

1. **Python 3.8 or higher** is required

2. **Install the SDK**:

```bash
# Option 1: From PyPI (recommended for end users)
pip install synheart-emotion

# Option 2: From source (recommended for development)
cd ../../sdks/python
pip install -e .

# Option 3: Install with dependencies from examples directory
cd examples/python-example
pip install -e ../../sdks/python
```

3. **Verify installation**:

```bash
python -c "from synheart_emotion import EmotionEngine; print('✓ SDK installed')"
```

### Running Examples

```bash
# Navigate to examples directory
cd examples/python-example

# Run any example
python basic_usage.py
python cli_demo.py
python streaming_data.py
python custom_config.py
```

## 📊 Example Comparison

| Example | Complexity | Interactive | Use Case |
|---------|-----------|-------------|----------|
| `basic_usage.py` | ⭐ Simple | No | Learning basics |
| `cli_demo.py` | ⭐⭐ Medium | Yes (CLI args) | Demonstrations |
| `streaming_data.py` | ⭐⭐ Medium | Yes (Ctrl+C) | Real-time testing |
| `custom_config.py` | ⭐⭐⭐ Advanced | No | Production setup |

## 🎯 Common Use Cases

### I want to...

**...learn the basics**
→ Start with `basic_usage.py`

**...see visual output**
→ Run `cli_demo.py`

**...test real-time streaming**
→ Try `streaming_data.py`

**...configure for production**
→ Study `custom_config.py`

**...integrate with my app**
→ See integration examples below

## 🔧 Integration Examples

### With Flask (Web API)

```python
from flask import Flask, request, jsonify
from synheart_emotion import EmotionEngine, EmotionConfig
from datetime import datetime

app = Flask(__name__)
engine = EmotionEngine.from_pretrained(EmotionConfig())

@app.route('/push', methods=['POST'])
def push_data():
    data = request.json
    engine.push(
        hr=data['hr'],
        rr_intervals_ms=data['rr_intervals'],
        timestamp=datetime.now()
    )
    return jsonify({'status': 'ok'})

@app.route('/results', methods=['GET'])
def get_results():
    results = engine.consume_ready()
    return jsonify([r.to_dict() for r in results])
```

### With FastAPI

```python
from fastapi import FastAPI
from pydantic import BaseModel
from synheart_emotion import EmotionEngine, EmotionConfig
from datetime import datetime

app = FastAPI()
engine = EmotionEngine.from_pretrained(EmotionConfig())

class BiosignalData(BaseModel):
    hr: float
    rr_intervals: list[float]

@app.post("/push")
async def push_data(data: BiosignalData):
    engine.push(
        hr=data.hr,
        rr_intervals_ms=data.rr_intervals,
        timestamp=datetime.now()
    )
    return {"status": "ok"}

@app.get("/results")
async def get_results():
    results = engine.consume_ready()
    return [r.to_dict() for r in results]
```

### With Asyncio

```python
import asyncio
from synheart_emotion import EmotionEngine, EmotionConfig
from datetime import datetime

async def process_stream():
    engine = EmotionEngine.from_pretrained(EmotionConfig())

    while True:
        # Get data from async source
        hr, rr = await get_biosignal_data()

        # Push to engine (thread-safe)
        engine.push(hr=hr, rr_intervals_ms=rr, timestamp=datetime.now())

        # Check for results
        results = engine.consume_ready()
        if results:
            print(f"Emotion: {results[0].emotion}")

        await asyncio.sleep(1)

asyncio.run(process_stream())
```

### With Pandas DataFrame

```python
import pandas as pd
from synheart_emotion import EmotionEngine, EmotionConfig
from datetime import datetime

# Load data from CSV
df = pd.read_csv('biosignal_data.csv')

engine = EmotionEngine.from_pretrained(EmotionConfig())

# Process each row
for _, row in df.iterrows():
    engine.push(
        hr=row['heart_rate'],
        rr_intervals_ms=eval(row['rr_intervals']),  # Assuming stored as string
        timestamp=pd.to_datetime(row['timestamp'])
    )

# Get all results
all_results = []
while True:
    results = engine.consume_ready()
    if not results:
        break
    all_results.extend(results)

# Convert to DataFrame
results_df = pd.DataFrame([r.to_dict() for r in all_results])
```

## 📝 Code Snippets

### Minimal Example (5 lines)

```python
from synheart_emotion import EmotionEngine, EmotionConfig
from datetime import datetime

engine = EmotionEngine.from_pretrained(EmotionConfig())
engine.push(hr=72.0, rr_intervals_ms=[850]*40, timestamp=datetime.now())
results = engine.consume_ready()
```

### With Error Handling

```python
from synheart_emotion import EmotionEngine, EmotionConfig, EmotionError

try:
    engine = EmotionEngine.from_pretrained(EmotionConfig())
    engine.push(hr=72.0, rr_intervals_ms=[850]*40, timestamp=datetime.now())
    results = engine.consume_ready()
except EmotionError as e:
    print(f"SDK Error: {e}")
```

### With Logging

```python
from synheart_emotion import EmotionEngine, EmotionConfig

def my_logger(level, message, context):
    print(f"[{level}] {message}")

engine = EmotionEngine.from_pretrained(
    EmotionConfig(),
    on_log=my_logger
)
```

## 🧪 Testing Examples

Run examples as tests:

```bash
# Test that examples run without errors
python -m pytest test_examples.py

# Or run individually with error checking
python basic_usage.py && echo "✓ basic_usage.py passed"
python cli_demo.py --samples 5 && echo "✓ cli_demo.py passed"
```

## 📚 Additional Resources

- [Python SDK Documentation](../../sdks/python/README.md)
- [API Reference](../../sdks/python/README.md#api-reference)
- [Main Repository README](../../README.md)

## 🐛 Troubleshooting

### Import Error

```bash
# Make sure SDK is installed
pip install synheart-emotion

# Or install from source
cd ../../sdks/python
pip install -e .
```

### No Results Returned

Results are throttled by the `step_seconds` parameter. You need to:
1. Push enough data to fill the window (default 60 seconds)
2. Wait for step interval (default 5 seconds) between results

### Console Colors Not Working

If colors don't display in your terminal:
- On Windows: Use Windows Terminal or enable ANSI support
- Set environment variable: `PYTHONUNBUFFERED=1`

## 💡 Tips

1. **Start Simple**: Begin with `basic_usage.py` to understand the flow
2. **Use CLI Demo**: Run `cli_demo.py` to see visual output
3. **Test Streaming**: Use `streaming_data.py` to understand real-time behavior
4. **Customize**: Study `custom_config.py` for production configurations
5. **Check Logs**: Enable logging to debug issues
6. **Monitor Buffer**: Use `get_buffer_stats()` to ensure data is flowing

## 📄 License

MIT License - See [LICENSE](../../LICENSE) file for details.

## 🤝 Contributing

Found a bug or have a suggestion? Please open an issue or submit a pull request!

---

**Happy coding! 🎉**
