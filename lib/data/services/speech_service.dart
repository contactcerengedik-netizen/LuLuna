import 'package:flutter_tts/flutter_tts.dart';

import '../models/child_profile.dart';

/// Üretilen yönlendirme metnini sese çeviren katman.
/// Adım 6'da çıkış BLE üzerinden kemik iletimli kulaklığa yönlenecek;
/// şimdilik telefon hoparlörü kullanılır.
abstract class SpeechService {
  Future<void> configureTone(VoiceTone tone);

  Future<void> speak(String text);

  Future<void> stop();
}

class FlutterTtsSpeechService implements SpeechService {
  FlutterTtsSpeechService() {
    _tts.setLanguage('tr-TR');
  }

  final FlutterTts _tts = FlutterTts();

  @override
  Future<void> configureTone(VoiceTone tone) async {
    // Ton, konuşma hızı ve perde ile taklit edilir; Adım 3+ TTS motoru
    // değişirse yalnızca bu harita güncellenir.
    final (rate, pitch) = switch (tone) {
      VoiceTone.compassionate => (0.45, 1.05),
      VoiceTone.energetic => (0.55, 1.15),
      VoiceTone.calm => (0.38, 0.95),
    };
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
  }

  @override
  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}

/// Test ortamları ve TTS istenmeyen durumlar için sessiz implementasyon.
class NoopSpeechService implements SpeechService {
  @override
  Future<void> configureTone(VoiceTone tone) async {}

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}
