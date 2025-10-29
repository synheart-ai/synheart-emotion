import 'package:flutter/material.dart';
import 'package:synheart_emotion/synheart_emotion.dart';

/// Example showing how to load and use JSON-based models
class JsonModelExample extends StatefulWidget {
  const JsonModelExample({super.key});

  @override
  State<JsonModelExample> createState() => _JsonModelExampleState();
}

class _JsonModelExampleState extends State<JsonModelExample> {
  JsonLinearModel? _model;
  String _status = 'Loading model...';
  Map<String, double>? _lastPrediction;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      // Load the WESAD-trained model from assets
      _model = await JsonLinearModel.loadFromAsset('assets/ml/wesad_emotion_v1_0.json');
      
      setState(() {
        _status = 'Model loaded successfully!';
      });
      
      // Test with sample data
      _testPrediction();
    } catch (e) {
      setState(() {
        _status = 'Failed to load model: $e';
      });
    }
  }

  void _testPrediction() {
    if (_model == null) return;
    
    // Test with sample features
    final features = {
      'hr_mean': 75.0,
      'sdnn': 50.0,
      'rmssd': 35.0,
    };
    
    try {
      final prediction = _model!.predict(features);
      setState(() {
        _lastPrediction = prediction;
      });
    } catch (e) {
      setState(() {
        _status = 'Prediction failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JSON Model Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Model Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_model != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Model Info',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('ID: ${_model!.modelId}'),
                      Text('Version: ${_model!.version}'),
                      Text('Classes: ${_model!.classes.join(', ')}'),
                      Text('Features: ${_model!.featureOrder.join(', ')}'),
                      const SizedBox(height: 8),
                      Text(
                        'Performance',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Accuracy: ${(_model!.getPerformanceMetrics()['accuracy'] * 100).toStringAsFixed(1)}%'),
                      Text('Dataset: ${_model!.getPerformanceMetrics()['dataset']}'),
                    ],
                  ],
                ),
              ),
            ),
            
            if (_lastPrediction != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sample Prediction',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Features: HR=75, SDNN=50, RMSSD=35'),
                      const SizedBox(height: 8),
                      ..._lastPrediction!.entries.map((entry) {
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
                                ),
                              ),
                              Text('${(entry.value * 100).toStringAsFixed(1)}%'),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testPrediction,
              child: const Text('Test Prediction'),
            ),
          ],
        ),
      ),
    );
  }
}
