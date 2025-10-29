# MODEL_CARD: svm_linear_wrist_sdnn_v1_0

**Model Type:** Linear SVM (One-vs-Rest)  
**Task:** Momentary emotion recognition from HR/RR (wrist PPG-derived RR)  
**Labels:** `Amused`, `Calm`, `Stressed`  
**Inputs (features):** `[hr_mean, sdnn, rmssd]` over a 60s rolling window  
**Export:** Embedded arrays (weights, biases, μ, σ) in Dart. Future: TFLite/ONNX-FFI.

---

## Intended Use
- On-device inference in Flutter apps via `synheart_emotion`.
- Fusion into SWIP Score within `swip-core`.

## Limitations
- Not a medical device.  
- Sensitive to RR quality; requires minimally ~30 RR intervals over the window.  
- Trained on research-derived signals (e.g., WESAD subset) — may not generalize to all populations or sensor conditions without calibration.

## Data
- WESAD-derived 3-class subset (arousal/valence mapping to Amused/Calm/Stressed).
- Preprocessing: artifact rejection on RR (<300ms or >2000ms; jumps >250ms).

## Metrics (reference offline evaluation)
- Accuracy: ~0.75
- Macro-F1: ~0.72
- Latency: < 5 ms on modern mid-range phones

## Ethical Considerations
- On-device processing; no raw RR persisted by default.
- Consent UI must be presented by host app.
- Avoid high-stakes decisions based solely on emotion outputs.

## Versioning
- Model ID: `svm_linear_wrist_sdnn_v1_0`
- Feature order: `[hr_mean, sdnn, rmssd]`
- Scaler stats (μ, σ) must match engine config for compatibility.

## Changelog
- v1.0: Initial release (embedded arrays).
