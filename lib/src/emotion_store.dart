import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'emotion_result.dart';

/// Storage policy for emotion data
enum StoragePolicy {
  /// No persistent storage
  none,
  /// Session-only storage (cleared on app restart)
  ephemeral,
  /// Local encrypted storage
  localPersist,
}

/// Consent state for data storage
enum ConsentState {
  /// User has not been asked
  notAsked,
  /// User has granted consent
  granted,
  /// User has denied consent
  denied,
  /// User has revoked consent
  revoked,
}

/// Abstract storage interface
abstract class EmotionStore {
  /// Write emotion result to storage
  Future<void> write(EmotionResult result);
  
  /// Read emotion results for a specific day
  Stream<EmotionResult> read(DateTime day);
  
  /// Rotate to new session
  Future<void> rotateSession();
  
  /// Clear all stored data
  Future<void> clear();
  
  /// Get storage statistics
  Future<Map<String, dynamic>> getStats();
}

/// Default implementation using file system with encryption
class DefaultEmotionStore implements EmotionStore {
  final StoragePolicy policy;
  final ConsentState consentState;
  final String? encryptionKey;
  
  Directory? _storageDir;
  String? _currentSessionId;
  final Map<String, List<EmotionResult>> _ephemeralCache = {};

  DefaultEmotionStore({
    this.policy = StoragePolicy.none,
    this.consentState = ConsentState.notAsked,
    this.encryptionKey,
  });

  /// Initialize storage
  Future<void> initialize() async {
    if (policy == StoragePolicy.none) return;
    
    if (policy == StoragePolicy.localPersist) {
      if (consentState != ConsentState.granted) {
        throw StateError('Consent not granted for local storage');
      }
      
      final appDir = await getApplicationDocumentsDirectory();
      _storageDir = Directory('${appDir.path}/emotion_store');
      await _storageDir!.create(recursive: true);
    }
    
    // Generate session ID
    _currentSessionId = _generateSessionId();
  }

  @override
  Future<void> write(EmotionResult result) async {
    if (policy == StoragePolicy.none) return;
    
    if (policy == StoragePolicy.ephemeral) {
      await _writeEphemeral(result);
    } else if (policy == StoragePolicy.localPersist) {
      await _writePersistent(result);
    }
  }

  @override
  Stream<EmotionResult> read(DateTime day) async* {
    if (policy == StoragePolicy.none) return;
    
    if (policy == StoragePolicy.ephemeral) {
      yield* _readEphemeral(day);
    } else if (policy == StoragePolicy.localPersist) {
      yield* _readPersistent(day);
    }
  }

  @override
  Future<void> rotateSession() async {
    _currentSessionId = _generateSessionId();
    
    if (policy == StoragePolicy.ephemeral) {
      _ephemeralCache.clear();
    }
  }

  @override
  Future<void> clear() async {
    if (policy == StoragePolicy.ephemeral) {
      _ephemeralCache.clear();
    } else if (policy == StoragePolicy.localPersist && _storageDir != null) {
      if (await _storageDir!.exists()) {
        await _storageDir!.delete(recursive: true);
        await _storageDir!.create(recursive: true);
      }
    }
  }

  @override
  Future<Map<String, dynamic>> getStats() async {
    if (policy == StoragePolicy.none) {
      return {'policy': 'none', 'total_sessions': 0, 'total_results': 0};
    }
    
    if (policy == StoragePolicy.ephemeral) {
      final totalResults = _ephemeralCache.values.fold(0, (sum, list) => sum + list.length);
      return {
        'policy': 'ephemeral',
        'total_sessions': _ephemeralCache.length,
        'total_results': totalResults,
      };
    }
    
    if (policy == StoragePolicy.localPersist && _storageDir != null) {
      int totalSessions = 0;
      int totalResults = 0;
      
      if (await _storageDir!.exists()) {
        final dayDirs = await _storageDir!.list().toList();
        for (final dayDir in dayDirs) {
          if (dayDir is Directory) {
            final sessionFiles = await dayDir.list().toList();
            totalSessions += sessionFiles.length;
            
            for (final sessionFile in sessionFiles) {
              if (sessionFile is File) {
                final content = await sessionFile.readAsString();
                final lines = content.split('\n').where((line) => line.trim().isNotEmpty);
                totalResults += lines.length;
              }
            }
          }
        }
      }
      
      return {
        'policy': 'local_persist',
        'total_sessions': totalSessions,
        'total_results': totalResults,
      };
    }
    
    return {'policy': 'unknown', 'total_sessions': 0, 'total_results': 0};
  }

  /// Write to ephemeral cache
  Future<void> _writeEphemeral(EmotionResult result) async {
    final dayKey = _formatDay(result.timestamp);
    _ephemeralCache.putIfAbsent(dayKey, () => []);
    _ephemeralCache[dayKey]!.add(result);
  }

  /// Read from ephemeral cache
  Stream<EmotionResult> _readEphemeral(DateTime day) async* {
    final dayKey = _formatDay(day);
    final results = _ephemeralCache[dayKey] ?? [];
    for (final result in results) {
      yield result;
    }
  }

  /// Write to persistent storage with encryption
  Future<void> _writePersistent(EmotionResult result) async {
    if (_storageDir == null || _currentSessionId == null) return;
    
    final dayDir = Directory('${_storageDir!.path}/${_formatDay(result.timestamp)}');
    await dayDir.create(recursive: true);
    
    final sessionFile = File('${dayDir.path}/session_$_currentSessionId.jsonl');
    
    // Convert to JSON and encrypt if key provided
    String content = jsonEncode(result.toJson());
    if (encryptionKey != null) {
      content = _encrypt(content, encryptionKey!);
    }
    
    await sessionFile.writeAsString('$content\n', mode: FileMode.append);
  }

  /// Read from persistent storage with decryption
  Stream<EmotionResult> _readPersistent(DateTime day) async* {
    if (_storageDir == null) return;
    
    final dayDir = Directory('${_storageDir!.path}/${_formatDay(day)}');
    if (!await dayDir.exists()) return;
    
    final sessionFiles = await dayDir.list().toList();
    for (final sessionFile in sessionFiles) {
      if (sessionFile is File) {
        final content = await sessionFile.readAsString();
        final lines = content.split('\n').where((line) => line.trim().isNotEmpty);
        
        for (final line in lines) {
          try {
            String jsonContent = line;
            if (encryptionKey != null) {
              jsonContent = _decrypt(jsonContent, encryptionKey!);
            }
            
            final json = jsonDecode(jsonContent);
            yield EmotionResult.fromJson(json);
          } catch (e) {
            // Skip malformed entries
            continue;
          }
        }
      }
    }
  }

  /// Generate session ID
  String _generateSessionId() {
    final random = Random();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Format date as YYYY-MM-DD
  String _formatDay(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }

  /// Simple encryption using AES (for demo purposes)
  String _encrypt(String plaintext, String key) {
    final keyBytes = sha256.convert(utf8.encode(key)).bytes.take(32).toList();
    
    // Simple XOR encryption (not secure, for demo only)
    final plaintextBytes = utf8.encode(plaintext);
    final encrypted = <int>[];
    
    for (int i = 0; i < plaintextBytes.length; i++) {
      encrypted.add(plaintextBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return base64Encode(encrypted);
  }

  /// Simple decryption
  String _decrypt(String ciphertext, String key) {
    final keyBytes = sha256.convert(utf8.encode(key)).bytes.take(32).toList();
    final encrypted = base64Decode(ciphertext);
    
    // Simple XOR decryption
    final decrypted = <int>[];
    for (int i = 0; i < encrypted.length; i++) {
      decrypted.add(encrypted[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return utf8.decode(decrypted);
  }
}

/// Consent manager for emotion data storage
class ConsentManager {
  static const String _consentKey = 'emotion_consent_state';
  
  /// Get current consent state
  static Future<ConsentState> getConsentState() async {
    final prefs = await SharedPreferences.getInstance();
    final stateString = prefs.getString(_consentKey);
    
    switch (stateString) {
      case 'granted': return ConsentState.granted;
      case 'denied': return ConsentState.denied;
      case 'revoked': return ConsentState.revoked;
      default: return ConsentState.notAsked;
    }
  }
  
  /// Set consent state
  static Future<void> setConsentState(ConsentState state) async {
    final prefs = await SharedPreferences.getInstance();
    String stateString;
    
    switch (state) {
      case ConsentState.granted: stateString = 'granted'; break;
      case ConsentState.denied: stateString = 'denied'; break;
      case ConsentState.revoked: stateString = 'revoked'; break;
      case ConsentState.notAsked: stateString = 'not_asked'; break;
    }
    
    await prefs.setString(_consentKey, stateString);
  }
  
  /// Check if consent is granted
  static Future<bool> hasConsent() async {
    final state = await getConsentState();
    return state == ConsentState.granted;
  }
}
