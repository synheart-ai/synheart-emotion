# WESAD Reference Models (Research Artifacts)

⚠️ **This directory contains research artifacts and training pipeline reference code.**

For the **production Python SDK**, see: [`sdks/python/`](../../sdks/python/)

## Purpose

This directory contains pre-trained models from the WESAD dataset for research and comparison purposes. These are NOT the production SDK models.

## Contents

- **14 pre-trained ML models** from WESAD dataset
- Model types: XGBoost, RandomForest, ExtraTrees, KNN, LDA, SVM, etc.
- Feature scaler and metadata
- Reference inference code

## Emotion Labels (WESAD)

- **0** → Baseline (Calm)
- **1** → Stress
- **2** → Amusement

## Input Data

Input is a Pandas DataFrame with HRV features extracted using NeuroKit2:
1. ECG signal cleaned with `nk.ecg_clean()`
2. R-peaks detected with `nk.ecg_peaks()`
3. HRV features computed with `nk.hrv()` (2-minute sliding windows)
4. Features scaled with StandardScaler

Feature order must match `feature_names.json`.

## Usage (Research Only)

```python
import pandas as pd
from inference import predict_dataframe

# Load your HRV features
sample_features = pd.DataFrame([{
    "feature_1": 0.1,
    "feature_2": 0.5,
    # ... all features from feature_names.json
}])

# Predict using one of the trained models
predictions = predict_dataframe(sample_features, model_name="ExtraTrees")
print(predictions)  # [(label_num, label_name), ...]
```

## Available Models

All models stored in `models/`:

| Model | File | Type |
|-------|------|------|
| AdaBoost | AdaBoost.joblib | Ensemble |
| Decision Tree | DecisionTree.joblib | Tree |
| Extra Trees | ExtraTrees.joblib | Ensemble |
| Gradient Boosting | GradBoost.joblib | Ensemble |
| K-Nearest Neighbors | KNN.joblib | Instance |
| Linear Discriminant | LDA.joblib | Linear |
| Linear SVM | LinearSVM.joblib | SVM |
| Logistic Regression | LogReg.joblib | Linear |
| Naive Bayes | NaiveBayes.joblib | Probabilistic |
| Quadratic Discriminant | QDA.joblib | Quadratic |
| Random Forest | RF.joblib | Ensemble |
| RBF SVM | RBF-SVM.joblib | SVM |
| Ridge Classifier | Ridge.joblib | Linear |
| XGBoost | XGB.xgb | Gradient Boosting |

Each model has an associated confusion matrix image in `models/confmatrix_*.png`.

## Files

```
wesad-reference-models/
├── inference.py              # Reference inference code
├── models/
│   ├── *.joblib             # Scikit-learn models
│   ├── *.xgb                # XGBoost models
│   ├── confmatrix_*.png     # Confusion matrices
│   ├── feature_names.json   # Required feature order
│   ├── label_map_0based.json # Label mapping
│   ├── scaler.joblib        # Feature scaler
│   ├── models_all.joblib    # All models bundled
│   └── model_results.csv    # Performance metrics
└── README.md                # This file
```

## Differences from Production SDK

| Aspect | This (Research) | Production SDK |
|--------|----------------|----------------|
| **Location** | `tools/wesad-reference-models/` | `sdks/python/` |
| **Purpose** | Research/training reference | Production deployment |
| **Models** | 14 pre-trained models | 1 embedded model |
| **Input** | DataFrame with many features | Raw HR + RR intervals |
| **API** | Function-based | Class-based engine |
| **Architecture** | Stateless | Stateful sliding window |
| **Installation** | Not pip-installable | `pip install synheart-emotion` |

## For Production Use

👉 **Use the production SDK instead**: [`sdks/python/`](../../sdks/python/)

The production SDK:
- ✅ Pip-installable
- ✅ Matches Flutter/Android/iOS APIs
- ✅ Real-time sliding window processing
- ✅ Works with raw biosignal data
- ✅ Thread-safe
- ✅ Comprehensive tests and examples

```bash
cd sdks/python
pip install -e .
```

## Dependencies

```bash
pip install numpy pandas joblib xgboost scikit-learn
```

## Training Pipeline Reference

This code represents the **output** of a training pipeline:
1. ECG data collected from WESAD dataset
2. Feature extraction with NeuroKit2
3. Model training with cross-validation
4. Model serialization to joblib/xgb

For production deployment, the simplified LinearSVM model in `sdks/python/` is used.

## Citation

WESAD Dataset:
```bibtex
@article{schmidt2018introducing,
  title={Introducing WESAD, a multimodal dataset for wearable stress and affect detection},
  author={Schmidt, Philip and Reiss, Attila and Duerichen, Robert and Marberger, Claus and Van Laerhoven, Kristof},
  journal={ICMI 2018},
  year={2018}
}
```

## License

Research artifacts - See main repository LICENSE.
