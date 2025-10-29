import 'dart:async';
import 'emotion_engine.dart';
import 'emotion_result.dart';

/// Data tick for streaming
class Tick {
  final DateTime timestamp;
  final double hr;
  final List<double> rrIntervalsMs;
  final Map<String, double>? motion;

  const Tick({
    required this.timestamp,
    required this.hr,
    required this.rrIntervalsMs,
    this.motion,
  });
}

/// Stream helper for emotion inference
class EmotionStream {
  final EmotionEngine _engine;
  final StreamController<EmotionResult> _controller = StreamController<EmotionResult>.broadcast();
  StreamSubscription<Tick>? _subscription;

  EmotionStream(this._engine);

  /// Create emotion stream from tick stream
  static Stream<EmotionResult> emotionStream(
    EmotionEngine engine,
    Stream<Tick> ticks,
  ) {
    final emotionStream = EmotionStream(engine);
    return emotionStream._createStream(ticks);
  }

  /// Create stream from tick data
  Stream<EmotionResult> _createStream(Stream<Tick> ticks) {
    _subscription = ticks.listen(
      (tick) async {
        // Push data to engine
        _engine.push(
          hr: tick.hr,
          rrIntervalsMs: tick.rrIntervalsMs,
          timestamp: tick.timestamp,
          motion: tick.motion,
        );

        // Consume ready results (now async)
        final results = await _engine.consumeReady();
        for (final result in results) {
          if (!_controller.isClosed) {
            _controller.add(result);
          }
        }
      },
      onError: (error) {
        if (!_controller.isClosed) {
          _controller.addError(error);
        }
      },
      onDone: () {
        if (!_controller.isClosed) {
          _controller.close();
        }
      },
    );

    return _controller.stream;
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    if (!_controller.isClosed) {
      _controller.close();
    }
  }
}
