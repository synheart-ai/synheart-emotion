# **RFC: synheart-emotion **

**Status:** Draft  
**Owner:** Synheart AI – Research Team  
**Date:** Oct 28, 2025  
**Repo:** `synheart-ai/synheart-emotion`  
**Targets:** Flutter/Dart (first-class), with portable core for Python/Node parity later  
**Depends on:** `synheart-wear` (optional data source), `swip-core` (consumer)

---

## 1) Purpose & Scope

`synheart-emotion` is an on-device library that infers **momentary emotion** from **biosignals** (HR/RR; optional motion), optimized for Flutter/Dart.  
Initial label set: **Amused**, **Calm**, **Stressed** (extensible).  
Primary use cases:
- **In-app emotion awareness** (UX adaptation, biofeedback)
- **SWIP Score fusion** (emotion → SWIP Core)
- **Private analytics** (local-only storage; optional opt-in sync)

**Non-goals (v1):**
- Camera/face/audio pipelines
- Cloud inference or raw-signal upload
- Medical or diagnostic claims

---

## 2) Definitions

- **RR intervals (ms):** time between heartbeats; used to derive HRV.  
- **SDNN:** std. dev. of NN intervals (short-term HRV proxy).  
- **RMSSD:** root mean square of successive differences (parasympathetic tone proxy).  
- **Window (W):** rolling accumulation horizon (default 60 s).  
- **Step (S):** emission cadence (default 5 s).

---

## 3) Architecture

```
Wearable / Sensor
   └─(HR bpm, RR ms, motion?)──► synheart-wear (optional)
                                 OR your own data source
                                    │
                                    ▼
                            synheart-emotion
                    [RingBuffer W] → [Features] → [Scaler]
                                         │
                                      [Model]
                                         │
                                    EmotionResult
                                         │
                                         ▼
                                     swip-core
```

- **RingBuffer:** holds last W seconds of HR/RR.
- **Feature Extractor:** HR mean, SDNN, RMSSD (+extensible).
- **Scaler:** standardize features with training μ/σ bundled in model.
- **Model Runner:** linear SVM (OvR) w/ softmax over margins (v1).
- **Emitter:** throttles outputs to once per S seconds.

---

## 4) Data & Models

**Inputs**
- `hr` (double, bpm)
- `rr_intervals_ms` (List<double>, ms) – minimally 30 values for stability  
- `motion?` (Map<String,double>) – optional accelerometer/steps aggregate

**Feature vector (v1)**
- `[hr_mean, sdnn, rmssd]` computed over window W

**Model (v1)**
- `svm_linear_wrist_sdnn_v1_0` (One-vs-Rest)  
- Export as arrays (weights, bias, μ, σ) embedded in Dart; later: TFLite/ONNX FFI.

**Performance targets (mid-range phone)**
- **Latency:** < 5 ms per inference
- **Model size:** < 100 KB
- **CPU:** < 2% avg during active streaming (S=5s)
- **Memory:** < 3 MB (engine + buffers)

---

## 5) Public API (Flutter/Dart)

### Package name
- `synheart_emotion` (Dart/Flutter)

### Config
```dart
class EmotionConfig {
  final String modelId;                 // default svm_linear_wrist_sdnn_v1_0
  final Duration window;                // default 60s
  final Duration step;                  // default 5s
  final int minRrCount;                 // default 30
  final bool returnAllProbas;           // default true
  final double? hrBaseline;             // optional personalization
  final Map<String,double>? priors;     // optional label priors

  const EmotionConfig({...});
}
```

### Engine lifecycle
```dart
final engine = EmotionEngine.fromPretrained(
  const EmotionConfig(window: Duration(seconds: 60), step: Duration(seconds: 5)),
);

// push ticks (e.g., from synheart_wear stream)
engine.push(hr: 72.0, rrIntervalsMs: [823,810,798,...], timestamp: DateTime.now().toUtc());

// pull results when ready (throttled by step)
final results = engine.consumeReady(); // List<EmotionResult>
```

### Output
```dart
class EmotionResult {
  final DateTime timestamp;
  final String emotion;                 // e.g., "Calm"
  final double confidence;              // top-1 probability
  final Map<String,double> probabilities; // label→prob
  final Map<String,double> features;    // hr_mean, sdnn, rmssd
  final Map<String,dynamic> model;      // id, version, type
}
```

### Streams (convenience, optional)
```dart
// Helper to expose a Stream<EmotionResult> (debounced by step)
Stream<EmotionResult> emotionStream(EmotionEngine eng, Stream<Tick> ticks);
```

### Batch API
```dart
Future<List<EmotionResult>> batchPredict(
  EmotionEngine engine,
  List<Map<String, dynamic>> samplesOrCsvPath,
);
```

### Error surface
- `EmotionError.tooFewRR(minExpected: int)`  
- `EmotionError.badInput(reason: String)`  
- `EmotionError.modelIncompatible(expectedFeats: int)`  
Errors are **non-throwing** by default in streaming; engine just **skips emit** and logs via callback (`onWarn`).

---

## 6) Privacy, Security, Compliance

- All computations are **on-device**; no raw RR/HR leaves device by default.  
- Persisted data (if host app opts in) limited to **EmotionResult** and aggregated features; **no raw RR by default**.  
- Provide `StoragePolicy` flag:
  - `none` (default), `ephemeral` (session-only), `local_persist` (encrypted box/Isolate).  
- Provide `ConsentState` check & require host app to surface user consent UI.  
- **No medical claims**; add disclaimer and compatibility matrix.

---

## 7) Storage (optional helper)

Simple local store (when enabled):

```
emotion_store/
  YYYY-MM-DD/
    session_<uuid>.jsonl   # line-delimited EmotionResult
```

API:
```dart
abstract class EmotionStore {
  Future<void> write(EmotionResult r);
  Stream<EmotionResult> read(DateTime day);
  Future<void> rotateSession();
}
```

Default implementation uses app-docs directory with file-level encryption (platform-provided).

---

## 8) Integration Patterns

### With `synheart-wear`
```dart
final wear = WearStream(device: WearDevice.appleWatch);
await for (final tick in wear.ticks) {
  engine.push(hr: tick.hr, rrIntervalsMs: tick.rrMs, timestamp: tick.t);
  for (final r in engine.consumeReady()) {
    // send to swip-core, update UI, etc.
  }
}
```

### With `swip-core` (fusion)
- Emit `EmotionResult` → `swip-core.ingestEmotion(result)`
- `swip-core` internally fuses emotion with FocusScore and other subscores into SWIP Score.

---

## 9) Feature Engineering Details (v1)

- **hr_mean:** average of HR samples in window W.  
- **sdnn:** standard deviation of `rr_intervals_ms` (sample std; N-1 denominator).  
- **rmssd:** `sqrt(mean(diff(rr)^2))`.  
- **Pre-cleaning (light):** drop RR outliers: < 300 ms or > 2000 ms; limit jumps > 250 ms vs previous (artifact guard).  
- **Missing data:** if `rr_intervals_ms.length < minRrCount`, skip emission.  
- **Normalization:** `(x - μ)/σ` using training stats baked in model.

---

## 10) Model Spec (v1) – Linear SVM OvR

- **Labels:** `["Amused","Calm","Stressed"]`  
- **Inputs:** `[hr_mean, sdnn, rmssd]`  
- **Params:**  
  - `weights`: `List<List<double>>` (C×F)  
  - `biases`: `List<double>` (C)  
  - `mu`: `List<double>` (F)  
  - `sigma`: `List<double>` (F)
- **Inference:** margins = `W·x + b`, **softmax** over margins → probabilities  
- **Confidence:** top-1 probability  
- **Calibration (later):** temperature scaling optional

---

## 11) Telemetry & Logging

- **Default:** silent (no remote).  
- Optional callback:
```dart
typedef EmotionLog = void Function(String level, String msg, {Map<String,Object?>? ctx});
engine.onLog = (lvl, msg, {ctx}) => debugPrint('[$lvl] $msg $ctx');
```

---

## 12) Performance & Battery Budget

- **Window:** 60 s; **Step:** 5 s (tunable by app).  
- RR parsing: O(N) per step; N ~ 60–120.  
- Avoid allocations on hot paths; reuse buffers.  
- Suspend engine when app in background unless explicitly required.

---

## 13) Testing & Validation

**Unit tests**
- Feature math (SDNN/RMSSD) vs known vectors  
- Edge cases: too-few RR, outliers, NaNs  
- Deterministic model inference

**Golden tests**
- Fixed input → fixed probabilities json

**Benchmarks**
- Inference latency < 5 ms on Pixel-class phone

**Offline validation protocol (FSVP-E1.0)**
- Evaluate on held-out WESAD-derived 3-class subset  
- Metrics: Accuracy, Macro-F1, ECE (calibration)  
- Report confusion matrix & per-class F1

---

## 14) Versioning & Compatibility

- **SemVer** on package; **Model IDs** independent:
  - Package: `0.x` (pre-1.0) → `1.x` stable API
  - Model: `svm_linear_wrist_sdnn_v1_0`, `…_v1_1`, etc.
- Engine rejects incompatible model feature dims with `EmotionError.modelIncompatible`.

---

## 15) Packaging & Repo Layout

```
synheart-emotion/
├─ lib/
│  ├─ synheart_emotion.dart
│  └─ src/
│     ├─ emotion_engine.dart
│     ├─ features.dart         # (optional split)
│     ├─ model_linear_svm.dart # arrays + loader
│     └─ store.dart            # optional
├─ example/                    # Flutter demo app
├─ test/
│  ├─ emotion_engine_test.dart
│  └─ features_test.dart
├─ docs/
│  ├─ RFC-E1.1.md
│  └─ MODEL_CARD.md
├─ tool/ci.yaml                # GitHub Actions (format, test)
├─ pubspec.yaml
└─ LICENSE
```

**CI gates**
- `dart format --set-exit-if-changed .`
- `dart analyze`
- `dart test --coverage`

---

## 16) Roadmap

**E1.1 (this RFC)**
- Flutter engine + example
- Linear SVM arrays, scaler
- Basic store (opt-in), consent guard
- Unit tests + benchmark

**E1.2**
- Personalization: HR baseline & label priors
- Label set expansion (e.g., Focused, Fatigued)
- CLI (dart) for batch CSV

**E1.3**
- TFLite/ONNX backend (FFI) for portable model swaps
- Temperature scaling for calibrated probabilities
- Motion features (activity index)

**E2.x**
- Semi-supervised on-device adaptation
- Continuous valence/arousal head

---

## 17) Acceptance Criteria (v1)

- ✅ Emits `EmotionResult` every S seconds with stable probs given valid RR  
- ✅ All feature math passes goldens; no NaNs or crashes with noisy RR  
- ✅ Latency < 5 ms per inference on a mid-range device  
- ✅ Example app visualizes live label + confidence  
- ✅ No raw RR persists unless explicitly enabled by host app  
- ✅ All code documented, tested, and `dart analyze` clean

---

## 18) Open Questions

1. **RMSSD vs SDNN weighting:** keep both for robustness or drop RMSSD on devices that don’t stream RR densely?  
2. **Label taxonomy:** do we introduce `Neutral` to stabilize flips?  
3. **Consent API:** provide a small consent widget or stay headless?  
4. **Fallback model:** HR-only model when RR missing — include now or E1.2?

---

### Appendix A — Minimal Example (Flutter)
```dart
final eng = EmotionEngine.fromPretrained(
  const EmotionConfig(window: Duration(seconds: 60), step: Duration(seconds: 2)),
);

// Replace with synheart_wear stream
Timer.periodic(const Duration(milliseconds: 500), (_) {
  final rr = List<double>.generate(60, (i) => 830 + (i%3 - 1)*8.0); // fake RR ~72 bpm
  eng.push(hr: 72, rrIntervalsMs: rr);
  for (final r in eng.consumeReady()) {
    debugPrint('[${r.timestamp.toIso8601String()}] ${r.emotion} ${(r.confidence*100).toStringAsFixed(1)}%  ${r.probabilities}');
  }
});
```
