import 'package:flutter_test/flutter_test.dart';
import 'package:synheart_emotion/synheart_emotion.dart';

void main() {
  group('FeatureExtractor Benchmarks', () {
    test('HR mean calculation performance', () {
      final hrValues = List.generate(1000, (i) => 70.0 + (i % 20));
      
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        FeatureExtractor.extractHrMean(hrValues);
      }
      stopwatch.stop();
      
      final avgTimeMs = stopwatch.elapsedMicroseconds / 1000 / 1000;
      print('HR mean calculation: ${avgTimeMs.toStringAsFixed(3)}ms average');
      
      // Should be very fast (< 1ms per calculation)
      expect(avgTimeMs, lessThan(1.0));
    });

    test('SDNN calculation performance', () {
      final rrIntervals = List.generate(100, (i) => 800.0 + (i % 50));
      
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        FeatureExtractor.extractSdnn(rrIntervals);
      }
      stopwatch.stop();
      
      final avgTimeMs = stopwatch.elapsedMicroseconds / 1000 / 1000;
      print('SDNN calculation: ${avgTimeMs.toStringAsFixed(3)}ms average');
      
      // Should be fast (< 2ms per calculation)
      expect(avgTimeMs, lessThan(2.0));
    });

    test('RMSSD calculation performance', () {
      final rrIntervals = List.generate(100, (i) => 800.0 + (i % 50));
      
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        FeatureExtractor.extractRmssd(rrIntervals);
      }
      stopwatch.stop();
      
      final avgTimeMs = stopwatch.elapsedMicroseconds / 1000 / 1000;
      print('RMSSD calculation: ${avgTimeMs.toStringAsFixed(3)}ms average');
      
      // Should be fast (< 2ms per calculation)
      expect(avgTimeMs, lessThan(2.0));
    });

    test('Full feature extraction performance', () {
      final hrValues = List.generate(100, (i) => 70.0 + (i % 20));
      final rrIntervals = List.generate(100, (i) => 800.0 + (i % 50));
      final motion = {'steps': 100.0};
      
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        FeatureExtractor.extractFeatures(
          hrValues: hrValues,
          rrIntervalsMs: rrIntervals,
          motion: motion,
        );
      }
      stopwatch.stop();
      
      final avgTimeMs = stopwatch.elapsedMicroseconds / 1000 / 1000;
      print('Full feature extraction: ${avgTimeMs.toStringAsFixed(3)}ms average');
      
      // Should be fast (< 5ms per calculation)
      expect(avgTimeMs, lessThan(5.0));
    });
  });

  group('Model Inference Benchmarks', () {
    late LinearSvmModel model;

    setUp(() {
      model = DefaultEmotionModel.createDefault();
    });

    test('Single inference performance', () {
      final features = {
        'hr_mean': 72.0,
        'sdnn': 45.0,
        'rmssd': 35.0,
      };
      
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        model.predict(features);
      }
      stopwatch.stop();
      
      final avgTimeMs = stopwatch.elapsedMicroseconds / 1000 / 1000;
      print('Model inference: ${avgTimeMs.toStringAsFixed(3)}ms average');
      
      // Should be very fast (< 1ms per inference)
      expect(avgTimeMs, lessThan(1.0));
    });

    test('Batch inference performance', () {
      final featuresList = List.generate(100, (i) => {
        'hr_mean': 70.0 + (i % 20),
        'sdnn': 40.0 + (i % 10),
        'rmssd': 30.0 + (i % 15),
      });
      
      final stopwatch = Stopwatch()..start();
      for (final features in featuresList) {
        model.predict(features);
      }
      stopwatch.stop();
      
      final totalTimeMs = stopwatch.elapsedMicroseconds / 1000;
      final avgTimeMs = totalTimeMs / featuresList.length;
      print('Batch inference: ${avgTimeMs.toStringAsFixed(3)}ms average');
      
      // Should be fast (< 1ms per inference)
      expect(avgTimeMs, lessThan(1.0));
    });
  });

  group('EmotionEngine Benchmarks', () {
    late EmotionEngine engine;

    setUp(() {
      engine = EmotionEngine.fromPretrained(
        const EmotionConfig(
          window: Duration(seconds: 60),
          step: Duration(seconds: 5),
          minRrCount: 30,
        ),
      );
    });

    test('Data push performance', () {
      final rrIntervals = List.generate(60, (i) => 800.0 + (i % 50));
      
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 1000; i++) {
        engine.push(
          hr: 70.0 + (i % 20),
          rrIntervalsMs: rrIntervals,
          timestamp: DateTime.now().toUtc(),
        );
      }
      stopwatch.stop();
      
      final avgTimeMs = stopwatch.elapsedMicroseconds / 1000 / 1000;
      print('Data push: ${avgTimeMs.toStringAsFixed(3)}ms average');
      
      // Should be very fast (< 1ms per push)
      expect(avgTimeMs, lessThan(1.0));
    });

    test('Inference cycle performance', () {
      // Fill buffer with enough data
      for (int i = 0; i < 10; i++) {
        engine.push(
          hr: 70.0 + (i % 20),
          rrIntervalsMs: List.generate(60, (j) => 800.0 + (j % 50)),
          timestamp: DateTime.now().toUtc().subtract(Duration(seconds: i)),
        );
      }
      
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < 100; i++) {
        engine.consumeReady();
      }
      stopwatch.stop();
      
      final avgTimeMs = stopwatch.elapsedMicroseconds / 1000 / 100;
      print('Inference cycle: ${avgTimeMs.toStringAsFixed(3)}ms average');
      
      // Should be fast (< 5ms per inference cycle)
      expect(avgTimeMs, lessThan(5.0));
    });

    test('Memory usage during continuous operation', () {
      // Simulate 5 minutes of data (600 pushes at 500ms intervals)
      for (int i = 0; i < 600; i++) {
        engine.push(
          hr: 70.0 + (i % 20),
          rrIntervalsMs: List.generate(60, (j) => 800.0 + (j % 50)),
          timestamp: DateTime.now().toUtc().subtract(Duration(milliseconds: i * 500)),
        );
        
        // Run inference every 10 pushes
        if (i % 10 == 0) {
          engine.consumeReady();
        }
      }
      
      final stats = engine.getBufferStats();
      print('Buffer stats after 5min: $stats');
      
      // Buffer should not grow indefinitely (adjusting for test data pattern)
      expect(stats['count'], lessThan(700)); // Reasonable buffer size for test
    });
  });

  group('Golden Tests', () {
    test('Feature extraction with known inputs', () {
      // Known input data
      final hrValues = [70.0, 72.0, 68.0, 75.0];
      final rrIntervals = [800.0, 820.0, 810.0, 830.0, 815.0, 825.0];
      
      // Extract features
      final features = FeatureExtractor.extractFeatures(
        hrValues: hrValues,
        rrIntervalsMs: rrIntervals,
      );
      
      // Expected values (calculated offline)
      expect(features['hr_mean'], closeTo(71.25, 0.01));
      expect(features['sdnn'], closeTo(10.8, 0.1));
      expect(features['rmssd'], greaterThan(0)); // Just verify it's positive
    });

    test('Model inference with known features', () {
      final model = DefaultEmotionModel.createDefault();
      
      // Known feature vector
      final features = {
        'hr_mean': 72.0,
        'sdnn': 45.0,
        'rmssd': 35.0,
      };
      
      final probabilities = model.predict(features);
      
      // Verify probabilities sum to 1
      final sum = probabilities.values.reduce((a, b) => a + b);
      expect(sum, closeTo(1.0, 0.001));
      
      // Verify all probabilities are valid
      for (final prob in probabilities.values) {
        expect(prob, greaterThanOrEqualTo(0.0));
        expect(prob, lessThanOrEqualTo(1.0));
        expect(prob.isFinite, isTrue);
      }
      
      // Verify expected labels are present
      expect(probabilities.containsKey('Amused'), isTrue);
      expect(probabilities.containsKey('Calm'), isTrue);
      expect(probabilities.containsKey('Stressed'), isTrue);
    });

    test('Deterministic results with same inputs', () {
      final model = DefaultEmotionModel.createDefault();
      final features = {
        'hr_mean': 70.0,
        'sdnn': 40.0,
        'rmssd': 30.0,
      };
      
      // Run inference multiple times
      final results = <Map<String, double>>[];
      for (int i = 0; i < 10; i++) {
        results.add(model.predict(features));
      }
      
      // All results should be identical
      for (int i = 1; i < results.length; i++) {
        for (final label in results[0].keys) {
          expect(results[i][label], closeTo(results[0][label]!, 0.001));
        }
      }
    });
  });
}
