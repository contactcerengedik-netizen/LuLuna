import 'package:audioplayers/audioplayers.dart';

import 'speech_service.dart';

/// İnternet yokken Gemini yerine devreye giren yerel sakinleştirici içerik.
abstract class OfflineFallbackService {
  /// Hazır oyalayıcı sesi çalar (örn. "Biraz dinlenelim mi?" hissi).
  Future<String> playComfort();
}

class AssetOfflineFallbackService implements OfflineFallbackService {
  AssetOfflineFallbackService({
    required SpeechService speech,
    AudioPlayer? player,
  })  : _speech = speech,
        _player = player ?? AudioPlayer();

  final SpeechService _speech;
  final AudioPlayer _player;

  static const comfortPhrase = 'Biraz dinlenelim mi? Ben yanındayım.';
  static const assetPath = 'audio/offline_comfort.wav';

  @override
  Future<String> playComfort() async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.release);
      await _player.play(AssetSource(assetPath));
    } catch (_) {
      // Asset çalınamazsa TTS ile aynı mesajı söyle.
      await _speech.speak(comfortPhrase);
    }
    return comfortPhrase;
  }
}

class NoopOfflineFallbackService implements OfflineFallbackService {
  @override
  Future<String> playComfort() async =>
      AssetOfflineFallbackService.comfortPhrase;
}
