import 'dart:collection';
import 'emotion_config.dart';
import 'emotion_result.dart';
import 'emotion_error.dart';
import 'features.dart';
import 'model_linear_svm.dart';

/// Data point for ring buffer
class _DataPoint {
  final DateTime timestamp;
  final double hr;
  final List<double> rrIntervalsMs;
  final Map<String, double>? motion;

  _DataPoint({
    required this.timestamp,
    required this.hr,
    required this.rrIntervalsMs,
    this.motion,
  });
}

/// Main emotion inference engine.
///
/// Processes biosignal data using a sliding window approach and produces
/// emotion predictions at configurable intervals.
class EmotionEngine {
  /// Expected number of core HRV features (SDNN, RMSSD, pNN50, Mean_RR, HR_mean).
  static const int expectedFeatureCount = 5;

  final EmotionConfig config;
  final dynamic model; // Can be LinearSvmModel or OnnxEmotionModel

  /// Ring buffer for sliding window
  final Queue<_DataPoint> _buffer = Queue<_DataPoint>();

  /// Last emission timestamp
  DateTime? _lastEmission;

  /// Logging callback
  void Function(String level, String message, {Map<String, Object?>? context})?
      onLog;

  EmotionEngine._({
    required this.config,
    required this.model,
    this.onLog,
  });

  /// Create engine from pretrained model
  factory EmotionEngine.fromPretrained(
    EmotionConfig config, {
    dynamic model,
    void Function(String level, String message, {Map<String, Object?>? context})?
        onLog,
  }) {
    // Use provided model or default
    final inferenceModel = model;

    // Validate model has required interface
    if (inferenceModel != null) {
      if (!inferenceModel.toString().contains('Model')) {
        throw EmotionError.badInput('Invalid model type provided');
      }
    }

    return EmotionEngine._(
      config: config,
      model: inferenceModel,
      onLog: onLog,
    );
  }

  /// Push new data point into the engine
  void push({
    required double hr,
    required List<double> rrIntervalsMs,
    required DateTime timestamp,
    Map<String, double>? motion,
  }) {
    try {
      // Validate input using physiological constants
      if (hr < FeatureExtractor.minValidHr || hr > FeatureExtractor.maxValidHr) {
        _log('warn', 'Invalid HR value: $hr (valid range: ${FeatureExtractor.minValidHr}-${FeatureExtractor.maxValidHr} BPM)');
        return;
      }

      if (rrIntervalsMs.isEmpty) {
        _log('warn', 'Empty RR intervals');
        return;
      }

      // Add to ring buffer
      final dataPoint = _DataPoint(
        timestamp: timestamp,
        hr: hr,
        rrIntervalsMs: List.from(rrIntervalsMs),
        motion: motion,
      );
      
      _buffer.add(dataPoint);
      
      // Remove old data points outside window
      _trimBuffer();
      
      _log('debug', 'Pushed data point: HR=$hr, RR count=${rrIntervalsMs.length}');
      
    } catch (e) {
      _log('error', 'Error pushing data point: $e');
    }
  }

  /// Consume ready results (throttled by step interval)
  Future<List<EmotionResult>> consumeReady() async {
    final results = <EmotionResult>[];
    
    if (model == null) {
      return results;
    }
    
    try {
      // Check if enough time has passed since last emission
      final now = DateTime.now().toUtc();
      if (_lastEmission != null && 
          now.difference(_lastEmission!).compareTo(config.step) < 0) {
        return results; // Not ready yet
      }

      // Check if we have enough data
      if (_buffer.length < 2) {
        return results; // Not enough data
      }

      // Extract features from current window
      final features = _extractWindowFeatures();
      if (features == null) {
        return results; // Feature extraction failed
      }

      // Run inference (supports both sync and async models)
      Map<String, double> probabilities;
      if (model.runtimeType.toString().contains('Onnx')) {
        // ONNX model requires async
        probabilities = await model.predictAsync(features);
      } else {
        // Linear SVM model is synchronous
        probabilities = model.predict(features);
      }
      
      // Create result
      final result = EmotionResult.fromInference(
        timestamp: now,
        probabilities: probabilities,
        features: features,
        model: model.getMetadata(),
      );

      results.add(result);
      _lastEmission = now;
      
      _log('info', 'Emitted result: ${result.emotion} (${(result.confidence * 100).toStringAsFixed(1)}%)');
      
    } catch (e) {
      _log('error', 'Error during inference: $e');
    }
    
    return results;
  }

  /// Extract features from current window
  Map<String, double>? _extractWindowFeatures() {
    if (_buffer.isEmpty) return null;

    // Collect all HR values and RR intervals in window
    final hrValues = <double>[];
    final allRrIntervals = <double>[];
    Map<String, double>? motionAggregate;

    for (final point in _buffer) {
      hrValues.add(point.hr);
      allRrIntervals.addAll(point.rrIntervalsMs);
      
      // Aggregate motion data
      if (point.motion != null) {
        motionAggregate ??= <String, double>{};
        for (final entry in point.motion!.entries) {
          motionAggregate[entry.key] = (motionAggregate[entry.key] ?? 0.0) + entry.value;
        }
      }
    }

    // Check minimum RR count
    if (allRrIntervals.length < config.minRrCount) {
      _log('warn', 'Too few RR intervals: ${allRrIntervals.length} < ${config.minRrCount}');
      return null;
    }

    // Extract features
    final features = FeatureExtractor.extractFeatures(
      hrValues: hrValues,
      rrIntervalsMs: allRrIntervals,
      motion: motionAggregate,
    );

    // Apply personalization if configured
    if (config.hrBaseline != null) {
      features['hr_mean'] = features['hr_mean']! - config.hrBaseline!;
    }

    return features;
  }

  /// Trim buffer to keep only data within window.
  ///
  /// Optimized implementation that removes all expired data points
  /// in a single pass to avoid repeated O(n) removeFirst() calls.
  void _trimBuffer() {
    if (_buffer.isEmpty) return;

    final cutoffTime = DateTime.now().toUtc().subtract(config.window);

    // Find index of first valid data point
    int firstValidIndex = 0;
    for (final point in _buffer) {
      if (!point.timestamp.isBefore(cutoffTime)) break;
      firstValidIndex++;
    }

    // Remove all expired data points at once if any found
    if (firstValidIndex > 0) {
      // Rebuild queue with only valid data points (more efficient than repeated removeFirst)
      final validPoints = _buffer.skip(firstValidIndex).toList();
      _buffer
        ..clear()
        ..addAll(validPoints);
    }
  }

  /// Get current buffer statistics
  Map<String, dynamic> getBufferStats() {
    if (_buffer.isEmpty) {
      return {
        'count': 0,
        'duration_ms': 0,
        'hr_range': [0.0, 0.0],
        'rr_count': 0,
      };
    }

    final hrValues = _buffer.map((p) => p.hr).toList();
    final rrCount = _buffer.fold(0, (sum, p) => sum + p.rrIntervalsMs.length);
    final duration = _buffer.last.timestamp.difference(_buffer.first.timestamp);

    return {
      'count': _buffer.length,
      'duration_ms': duration.inMilliseconds,
      'hr_range': [hrValues.reduce((a, b) => a < b ? a : b), hrValues.reduce((a, b) => a > b ? a : b)],
      'rr_count': rrCount,
    };
  }

  /// Clear all buffered data
  void clear() {
    _buffer.clear();
    _lastEmission = null;
    _log('info', 'Buffer cleared');
  }

  /// Log message with optional context
  void _log(String level, String message, {Map<String, Object?>? context}) {
    onLog?.call(level, message, context: context);
  }
}
