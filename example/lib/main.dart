import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:synheart_emotion/synheart_emotion.dart';

void main() {
  runApp(const EmotionExampleApp());
}

class EmotionExampleApp extends StatelessWidget {
  const EmotionExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synheart Emotion Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const EmotionDemoPage(),
    );
  }
}

class EmotionDemoPage extends StatefulWidget {
  const EmotionDemoPage({super.key});

  @override
  State<EmotionDemoPage> createState() => _EmotionDemoPageState();
}

class _EmotionDemoPageState extends State<EmotionDemoPage> {
  EmotionEngine? _engine;
  Timer? _dataTimer;
  Timer? _inferenceTimer;
  
  final List<EmotionResult> _results = [];
  final List<String> _logs = [];
  
  bool _isRunning = false;
  bool _isLoading = true;
  String _currentEmotion = 'Unknown';
  double _currentConfidence = 0.0;
  Map<String, double> _currentProbabilities = {};

  @override
  void initState() {
    super.initState();
    _initializeEngine();
  }

  Future<void> _initializeEngine() async {
    try {
      // Load ONNX model from assets
      final model = await OnnxEmotionModel.loadFromAsset(
        modelAssetPath: 'assets/ml/extratrees_wrist_all_v1_0.onnx',
        metaAssetPath: 'assets/ml/extratrees_wrist_all_v1_0.meta.json',
      );

      _engine = EmotionEngine.fromPretrained(
        const EmotionConfig(
          window: Duration(seconds: 60),
          step: Duration(seconds: 2),
          minRrCount: 30,
        ),
        model: model,
        onLog: (level, message, {context}) {
          setState(() {
            _logs.add('[$level] $message');
            if (_logs.length > 50) {
              _logs.removeAt(0); // Keep only last 50 logs
            }
          });
        },
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _logs.add('[error] Failed to load model: $e');
        _isLoading = false;
      });
    }
  }

  void _startSimulation() {
    if (_isRunning || _engine == null) return;
    
    setState(() {
      _isRunning = true;
      _results.clear();
    });

    // Simulate data every 500ms
    _dataTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _simulateDataPoint();
    });

    // Run inference every 2 seconds
    _inferenceTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _runInference();
    });
  }

  void _stopSimulation() {
    _dataTimer?.cancel();
    _inferenceTimer?.cancel();
    
    setState(() {
      _isRunning = false;
    });
  }

  void _simulateDataPoint() {
    if (_engine == null) return;
    
    final random = Random();
    
    // Simulate realistic HR and RR intervals
    final baseHr = 70 + (random.nextDouble() - 0.5) * 20; // ~70 BPM ± 10
    final hr = baseHr.clamp(50.0, 120.0);
    
    // Generate RR intervals (time between heartbeats in ms)
    final rrIntervals = <double>[];
    for (int i = 0; i < 60; i++) {
      final baseRr = 60000 / hr; // Convert HR to RR
      final rr = baseRr + (random.nextDouble() - 0.5) * 40; // Add some variability
      rrIntervals.add(rr.clamp(400.0, 1200.0));
    }

    _engine!.push(
      hr: hr,
      rrIntervalsMs: rrIntervals,
      timestamp: DateTime.now().toUtc(),
    );
  }

  Future<void> _runInference() async {
    if (_engine == null) return;
    
    final results = await _engine!.consumeReady();
    
    for (final result in results) {
      setState(() {
        _results.add(result);
        _currentEmotion = result.emotion;
        _currentConfidence = result.confidence;
        _currentProbabilities = result.probabilities;
      });
    }
  }

  void _clearResults() {
    setState(() {
      _results.clear();
      _logs.clear();
      _currentEmotion = 'Unknown';
      _currentConfidence = 0.0;
      _currentProbabilities.clear();
    });
    _engine?.clear();
  }

  @override
  void dispose() {
    _stopSimulation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Synheart Emotion Demo'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading ONNX model...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Synheart Emotion Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfo,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: (_isRunning || _engine == null) ? null : _startSimulation,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                ),
                ElevatedButton.icon(
                  onPressed: _isRunning ? _stopSimulation : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
                ElevatedButton.icon(
                  onPressed: _engine == null ? null : _clearResults,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Current emotion display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Current Emotion',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentEmotion,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: _getEmotionColor(_currentEmotion),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(_currentConfidence * 100).toStringAsFixed(1)}% confidence',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Probability bars
            if (_currentProbabilities.isNotEmpty) ...[
              Text(
                'Probabilities',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._currentProbabilities.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(entry.key),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: entry.value,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getEmotionColor(entry.key),
                          ),
                        ),
                      ),
                      Text('${(entry.value * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
            
            // Results list
            Expanded(
              child: Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Results (${_results.length})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Buffer: ${_engine?.getBufferStats()['count'] ?? 0} points',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final result = _results[_results.length - 1 - index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getEmotionColor(result.emotion),
                              child: Text(
                                result.emotion[0],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(result.emotion),
                            subtitle: Text(
                              '${(result.confidence * 100).toStringAsFixed(1)}% • '
                              '${result.timestamp.toLocal().toString().substring(11, 19)}',
                            ),
                            trailing: Text(
                              'HR: ${result.features['hr_mean']?.toStringAsFixed(1) ?? 'N/A'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'amused':
        return Colors.orange;
      case 'calm':
        return Colors.blue;
      case 'stressed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About This Demo'),
        content: const Text(
          'This demo simulates real-time emotion inference from heart rate and '
          'RR interval data using the Synheart Emotion library.\n\n'
          'The app generates realistic biometric data and runs emotion inference '
          'every 2 seconds using a 60-second sliding window.\n\n'
          'Model: ExtraTrees ONNX (WESAD wrist data)\n\n'
          'Features demonstrated:\n'
          '• ONNX model inference\n'
          '• Real-time emotion detection\n'
          '• Probability visualization\n'
          '• Buffer management\n'
          '• Logging system',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}