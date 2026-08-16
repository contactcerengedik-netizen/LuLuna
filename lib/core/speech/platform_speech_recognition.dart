import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../features/dialogue/domain/dialogue_models.dart';

export '../../features/dialogue/domain/dialogue_models.dart'
    show SpeechRecognitionService, MockSpeechRecognitionService;

/// Platform STT iskeleti (`speech_to_text`).
/// Cihaz/izin yoksa [fallback] (genelde mock) kullanılır.
class PlatformSpeechRecognitionService implements SpeechRecognitionService {
  PlatformSpeechRecognitionService({
    SpeechRecognitionService? fallback,
    stt.SpeechToText? plugin,
  })  : _fallback = fallback ?? MockSpeechRecognitionService(),
        _plugin = plugin ?? stt.SpeechToText();

  final SpeechRecognitionService _fallback;
  final stt.SpeechToText _plugin;
  var _initialized = false;
  var _available = false;

  Future<bool> initialize() async {
    if (_initialized) return _available;
    try {
      _available = await _plugin.initialize(
        onError: (e) => debugPrint('STT error: $e'),
        onStatus: (s) => debugPrint('STT status: $s'),
      );
    } catch (e) {
      debugPrint('STT init failed: $e');
      _available = false;
    }
    _initialized = true;
    return _available;
  }

  bool get isAvailable => _available;

  @override
  Future<String> listenOnce({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    await initialize();
    if (!_available) {
      return _fallback.listenOnce(timeout: timeout);
    }

    final completer = Completer<String>();
    var last = '';
    try {
      await _plugin.listen(
        onResult: (result) {
          last = result.recognizedWords;
          if (result.finalResult && !completer.isCompleted) {
            completer.complete(last);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: timeout,
          pauseFor: const Duration(seconds: 2),
          localeId: 'tr_TR',
          cancelOnError: true,
          partialResults: true,
        ),
      );
      final text = await completer.future.timeout(
        timeout + const Duration(seconds: 1),
        onTimeout: () => last,
      );
      await _plugin.stop();
      final trimmed = text.trim();
      if (trimmed.isEmpty) {
        return _fallback.listenOnce(timeout: timeout);
      }
      return trimmed;
    } catch (e) {
      debugPrint('STT listen failed: $e');
      try {
        await _plugin.stop();
      } catch (_) {}
      return _fallback.listenOnce(timeout: timeout);
    }
  }

  Future<void> stop() async {
    if (_available) {
      try {
        await _plugin.stop();
      } catch (_) {}
    }
  }
}

/// Anahtar kelimeye göre scripted mock — demo / test.
SpeechRecognitionService mockSttForKeywords(List<String> keywords) {
  return MockSpeechRecognitionService(
    scripted: keywords.isNotEmpty ? keywords : const ['elma'],
  );
}
