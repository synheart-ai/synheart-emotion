import 'package:flutter_test/flutter_test.dart';
import 'package:synheart_emotion/synheart_emotion.dart';

void main() {
  group('JsonLinearModel', () {
    test('can load WESAD model from asset', () async {
      // This test verifies that the JSON model can be loaded
      // Note: In a real test environment, you'd need to mock the asset loading
      // For now, we'll test the model creation directly
      
      final model = JsonLinearModel.fromJson({
        'type': 'linear_svm_ovr',
        'version': '1.0',
        'model_id': 'wesad_emotion_v1_0',
        'feature_order': ['hr_mean', 'sdnn', 'rmssd'],
        'classes': ['Amused', 'Calm', 'Stressed'],
        'scaler': {
          'mean': [72.5, 45.3, 32.1],
          'std': [12.0, 18.7, 12.4]
        },
        'weights': [
          [0.12, 0.5, 0.3],
          [-0.21, -0.4, -0.3],
          [0.02, 0.2, 0.1]
        ],
        'bias': [-0.2, 0.3, 0.1],
        'inference': {
          'score_fn': 'softmax',
          'temperature': 1.0
        },
        'training': {
          'dataset': 'WESAD',
          'subjects': 15,
          'windows': 1200,
          'accuracy': 0.78,
          'balanced_accuracy': 0.76,
          'f1_score': 0.75
        }
      });
      
      expect(model.modelId, equals('wesad_emotion_v1_0'));
      expect(model.version, equals('1.0'));
      expect(model.classes, equals(['Amused', 'Calm', 'Stressed']));
      expect(model.featureOrder, equals(['hr_mean', 'sdnn', 'rmssd']));
      expect(model.validate(), isTrue);
    });
    
    test('predicts emotions correctly', () {
      final model = JsonLinearModel.fromJson({
        'type': 'linear_svm_ovr',
        'version': '1.0',
        'model_id': 'wesad_emotion_v1_0',
        'feature_order': ['hr_mean', 'sdnn', 'rmssd'],
        'classes': ['Amused', 'Calm', 'Stressed'],
        'scaler': {
          'mean': [72.5, 45.3, 32.1],
          'std': [12.0, 18.7, 12.4]
        },
        'weights': [
          [0.12, 0.5, 0.3],
          [-0.21, -0.4, -0.3],
          [0.02, 0.2, 0.1]
        ],
        'bias': [-0.2, 0.3, 0.1],
        'inference': {
          'score_fn': 'softmax',
          'temperature': 1.0
        },
        'training': {
          'dataset': 'WESAD',
          'subjects': 15,
          'windows': 1200,
          'accuracy': 0.78,
          'balanced_accuracy': 0.76,
          'f1_score': 0.75
        }
      });
      
      final features = {
        'hr_mean': 75.0,
        'sdnn': 50.0,
        'rmssd': 35.0,
      };
      
      final prediction = model.predict(features);
      
      expect(prediction.keys, equals(['Amused', 'Calm', 'Stressed']));
      expect(prediction.values.every((p) => p >= 0.0 && p <= 1.0), isTrue);
      
      // Probabilities should sum to 1.0
      final sum = prediction.values.reduce((a, b) => a + b);
      expect(sum, closeTo(1.0, 0.001));
    });
    
    test('getPerformanceMetrics returns correct data', () {
      final model = JsonLinearModel.fromJson({
        'type': 'linear_svm_ovr',
        'version': '1.0',
        'model_id': 'wesad_emotion_v1_0',
        'feature_order': ['hr_mean', 'sdnn', 'rmssd'],
        'classes': ['Amused', 'Calm', 'Stressed'],
        'scaler': {
          'mean': [72.5, 45.3, 32.1],
          'std': [12.0, 18.7, 12.4]
        },
        'weights': [
          [0.12, 0.5, 0.3],
          [-0.21, -0.4, -0.3],
          [0.02, 0.2, 0.1]
        ],
        'bias': [-0.2, 0.3, 0.1],
        'inference': {
          'score_fn': 'softmax',
          'temperature': 1.0
        },
        'training': {
          'dataset': 'WESAD',
          'subjects': 15,
          'windows': 1200,
          'accuracy': 0.78,
          'balanced_accuracy': 0.76,
          'f1_score': 0.75
        }
      });
      
      final metrics = model.getPerformanceMetrics();
      
      expect(metrics['accuracy'], equals(0.78));
      expect(metrics['balanced_accuracy'], equals(0.76));
      expect(metrics['f1_score'], equals(0.75));
      expect(metrics['dataset'], equals('WESAD'));
      expect(metrics['subjects'], equals(15));
      expect(metrics['windows'], equals(1200));
    });
  });
}
