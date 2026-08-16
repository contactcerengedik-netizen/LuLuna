import '../../../core/speech/platform_speech_recognition.dart';

/// Günlük yaşam / eski STT yüzeyi — çekirdek [SpeechRecognitionService]'e köprü.
abstract class SpeechToTextService {
  Future<bool> initialize();
  Future<String?> listenOnce({Duration timeout = const Duration(seconds: 5)});
  Future<void> stop();
}

class BridgedSpeechToTextService implements SpeechToTextService {
  BridgedSpeechToTextService(this._inner);

  final SpeechRecognitionService _inner;

  @override
  Future<bool> initialize() async {
    if (_inner is PlatformSpeechRecognitionService) {
      return _inner.initialize();
    }
    return true;
  }

  @override
  Future<String?> listenOnce({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final text = await _inner.listenOnce(timeout: timeout);
    return text.isEmpty ? null : text;
  }

  @override
  Future<void> stop() async {
    if (_inner is PlatformSpeechRecognitionService) {
      await _inner.stop();
    }
  }
}

class NoopSpeechToTextService implements SpeechToTextService {
  @override
  Future<bool> initialize() async => false;

  @override
  Future<String?> listenOnce({
    Duration timeout = const Duration(seconds: 5),
  }) async =>
      null;

  @override
  Future<void> stop() async {}
}
