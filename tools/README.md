# Tools Directory

This directory contains development tools and utilities for the Synheart Emotion project.

## Available Tools

### 1. Synthetic Data Generator (`synthetic-data-generator/`)

**Purpose**: Generate realistic biosignal data for testing all SDKs

Generate synthetic heart rate and RR interval data for testing emotion inference across Python, Android, iOS, and Flutter platforms.

**Features**:
- 🎯 Realistic physiological data
- 🎭 3 emotion scenarios (Calm, Stressed, Amused)
- 🔄 Smooth transitions between emotions
- 📊 Export to CSV, JSON, Python, Kotlin, Swift
- 🔁 Reproducible with random seeds

**Quick Start**:
```bash
cd synthetic-data-generator
python cli.py --emotion Calm --duration 60 --output ./data
```

**Documentation**: See [synthetic-data-generator/README.md](synthetic-data-generator/README.md)

---

### 2. WESAD Reference Models (`wesad-reference-models/`)

**Purpose**: Research artifacts and training pipeline reference

Pre-trained models from the WESAD dataset for research and model comparison.

**Contains**:
- 14 pre-trained ML models (XGBoost, RandomForest, SVM, etc.)
- Feature scaler and metadata
- Reference inference code
- Performance metrics and confusion matrices

**⚠️ Not for Production**: This is research code. For production, use [`sdks/python/`](../sdks/python/)

**Documentation**: See [wesad-reference-models/README.md](wesad-reference-models/README.md)

---

## Tool Comparison

| Tool | Purpose | Output | Use Case |
|------|---------|--------|----------|
| **synthetic-data-generator** | Generate test data | Biosignal time series | SDK testing |
| **wesad-reference-models** | Research reference | Model predictions | Research/comparison |

## For SDK Development

If you're developing with the SDKs, you likely want:

1. **Testing SDKs** → Use `synthetic-data-generator/`
2. **Research/comparison** → See `wesad-reference-models/`
3. **Production deployment** → Use `sdks/python/`, `sdks/android/`, or `sdks/ios/`

## Directory Structure

```
tools/
├── README.md                      # This file
├── synthetic-data-generator/      # Test data generation tool
│   ├── syndata/                   # Generator package
│   ├── examples/                  # Usage examples
│   ├── cli.py                     # Command-line interface
│   └── README.md                  # Full documentation
└── wesad-reference-models/        # Research artifacts
    ├── inference.py               # Reference inference
    ├── models/                    # Pre-trained models
    └── README.md                  # Documentation
```

## Contributing

To add a new tool:

1. Create a new directory under `tools/`
2. Add a descriptive README.md
3. Update this file with a summary
4. Consider making it pip-installable if appropriate
