import 'dart:async';
import 'package:flutter/material.dart';
import 'package:synheart_emotion/synheart_emotion.dart';
// import 'package:synheart_wear/synheart_wear.dart'; // Uncomment when available

/// Example integration showing how to use synheart_emotion with synheart_wear
/// 
/// To use this:
/// 1. Add synheart_wear to your pubspec.yaml
/// 2. Uncomment the import above
/// 3. Initialize both SDKs in your app
class SynheartIntegrationExample extends StatefulWidget {
  const SynheartIntegrationExample({super.key});

  @override
  State<SynheartIntegrationExample> createState() => _SynheartIntegrationExampleState();
}

class _SynheartIntegrationExampleState extends State<SynheartIntegrationExample> {
  late EmotionEngine _emotionEngine;
  // late SynheartWear _wearable; // Uncomment when synheart_wear is available
  StreamSubscription? _wearableSubscription;
  StreamSubscription? _emotionSubscription;
  
  final List<EmotionResult> _results = [];
  String _currentEmotion = 'Unknown';
  double _currentConfidence = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeSDKs();
  }

  Future<void> _initializeSDKs() async {
    // Initialize emotion engine
    _emotionEngine = EmotionEngine.fromPretrained(
      const EmotionConfig(
        window: Duration(seconds: 60),
        step: Duration(seconds: 5),
        minRrCount: 30,
      ),
    );

    // Uncomment when synheart_wear is available:
    /*
    // Initialize bespoke wearable SDK
    _wearable = SynheartWear();
    await _wearable.initialize();
    
    // Request permissions
    await _wearable.requestPermissions(
      permissions: {
        PermissionType.heartRate,
        PermissionType.rrIntervals,
      },
      reason: 'This app needs access to your health data for emotion insights.',
    );
    
    // Stream wearable data and feed to emotion engine
    _wearableSubscription = _wearable.streamHR(
      interval: Duration(seconds: 1),
    ).listen((metrics) {
      // Push data to emotion engine
      _emotionEngine.push(
        hr: metrics.getMetric(MetricType.hr),
        rrIntervalsMs: metrics.getMetric(MetricType.rrIntervals),
        timestamp: DateTime.now().toUtc(),
      );
      
      // Get emotion results
      final emotions = _emotionEngine.consumeReady();
      for (final emotion in emotions) {
        setState(() {
          _results.add(emotion);
          _currentEmotion = emotion.emotion;
          _currentConfidence = emotion.confidence;
        });
        
        // Optional: Send to swip-core for impact measurement
        // swipCore.ingestEmotion(emotion);
      }
    });
    */
  }

  @override
  void dispose() {
    _wearableSubscription?.cancel();
    _emotionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Synheart Integration Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Current Emotion: $_currentEmotion',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      'Confidence: ${(_currentConfidence * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[_results.length - 1 - index];
                  return ListTile(
                    title: Text(result.emotion),
                    subtitle: Text('${(result.confidence * 100).toStringAsFixed(1)}%'),
                    trailing: Text(
                      result.timestamp.toLocal().toString().substring(11, 19),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alternative: Use EmotionStream helper for simpler integration
class StreamIntegrationExample extends StatefulWidget {
  const StreamIntegrationExample({super.key});

  @override
  State<StreamIntegrationExample> createState() => _StreamIntegrationExampleState();
}

class _StreamIntegrationExampleState extends State<StreamIntegrationExample> {
  late EmotionEngine _emotionEngine;
  StreamSubscription? _emotionSubscription;
  
  EmotionResult? _latestResult;

  @override
  void initState() {
    super.initState();
    _initializeStreaming();
  }

  Future<void> _initializeStreaming() async {
    // Initialize emotion engine
    _emotionEngine = EmotionEngine.fromPretrained(
      const EmotionConfig(window: Duration(seconds: 60)),
    );

    // Uncomment when synheart_wear is available:
    /*
    // Initialize wearable SDK
    final wearable = SynheartWear();
    await wearable.initialize();
    
    // Get wearable data stream
    final wearableStream = wearable.streamHR(interval: Duration(seconds: 1));
    
    // Convert wearable ticks to emotion engine ticks
    final tickStream = wearableStream.map((metrics) => Tick(
      timestamp: DateTime.now().toUtc(),
      hr: metrics.getMetric(MetricType.hr),
      rrIntervalsMs: metrics.getMetric(MetricType.rrIntervals),
    ));
    
    // Stream emotion results
    final emotionStream = EmotionStream.emotionStream(_emotionEngine, tickStream);
    
    _emotionSubscription = emotionStream.listen((result) {
      setState(() {
        _latestResult = result;
      });
    });
    */
  }

  @override
  void dispose() {
    _emotionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stream Integration Example'),
      ),
      body: Center(
        child: _latestResult != null
            ? Text(
                'Emotion: ${_latestResult!.emotion}\n'
                'Confidence: ${(_latestResult!.confidence * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              )
            : const Text('Waiting for emotion data...'),
      ),
    );
  }
}
