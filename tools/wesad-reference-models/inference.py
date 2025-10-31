import joblib
import json
import time
from pathlib import Path
import numpy as np
import pandas as pd
from xgboost import XGBClassifier

OUT_DIR = Path("models")

scaler = joblib.load(OUT_DIR / "scaler.joblib")
with open(OUT_DIR / "feature_names.json", "r") as f:
    feature_names = json.load(f)
with open(OUT_DIR / "label_map_0based.json", "r") as f:
    raw = json.load(f)
    label_map_0based = {int(k): v for k, v in raw.items()}

def load_model_by_name(model_name: str):
    jb_path = OUT_DIR / f"{model_name}.joblib"
    xgb_path = OUT_DIR / f"{model_name}.xgb"
    if jb_path.exists():
        return joblib.load(jb_path)
    elif xgb_path.exists():
        model = XGBClassifier()
        model.load_model(str(xgb_path))
        return model
    else:
        all_path = OUT_DIR / "models_all.joblib"
        if all_path.exists():
            all_models = joblib.load(all_path)
            if model_name in all_models:
                return all_models[model_name]
        raise FileNotFoundError(f"No saved model found for {model_name}")

def prepare_input(df: pd.DataFrame) -> np.ndarray:
    if not isinstance(df, pd.DataFrame):
        df = pd.DataFrame([df])
    missing = [c for c in feature_names if c not in df.columns]
    if missing:
        raise ValueError(f"Input is missing these required features: {missing}")
    df = df[feature_names].copy()
    df = df.fillna(df.median())
    X_scaled = scaler.transform(df.values)
    return X_scaled

def predict_dataframe(df: pd.DataFrame, model_name: str):
    model = load_model_by_name(model_name)
    X = prepare_input(df)
    start_time = time.time()
    pred_nums = model.predict(X)
    elapsed = time.time() - start_time
    pred_names = [label_map_0based[int(p)] for p in pred_nums]
    print(f"\n⏱ Inference time: {elapsed:.4f} seconds")
    return list(zip(pred_nums.tolist(), pred_names))

if __name__ == "__main__":
    sample = pd.DataFrame([np.random.rand(len(feature_names))], columns=feature_names)
    model_to_test = "ExtraTrees"
    preds = predict_dataframe(sample, model_to_test)
    print("Predictions (numeric, label):", preds)
