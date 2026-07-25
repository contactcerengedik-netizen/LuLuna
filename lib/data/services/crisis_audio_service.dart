import 'package:audioplayers/audioplayers.dart';

import '../models/crisis_state.dart';

/// Kriz anında veli sesi / sakinleştirici müzik çalan katman.
abstract class CrisisAudioService {
  Future<void> play(CrisisAudioSource source);

  Future<void> stop();
}

class AudioPlayersCrisisService implements CrisisAudioService {
  AudioPlayersCrisisService({
    AudioPlayer? player,
    this.parentVoicePathResolver,
  }) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  /// Veli kaydı varsa dosya yolu; yoksa asset fallback.
  final String? Function()? parentVoicePathResolver;

  static const _assets = {
    CrisisAudioSource.parentVoice: 'audio/parent_voice.wav',
    CrisisAudioSource.calmingMusic: 'audio/calming_music.wav',
  };

  @override
  Future<void> play(CrisisAudioSource source) async {
    if (source == CrisisAudioSource.none) {
      await stop();
      return;
    }

    await _player.stop();
    await _player.setReleaseMode(
      source == CrisisAudioSource.calmingMusic
          ? ReleaseMode.loop
          : ReleaseMode.release,
    );

    if (source == CrisisAudioSource.parentVoice) {
      final custom = parentVoicePathResolver?.call();
      if (custom != null && custom.isNotEmpty) {
        await _player.play(DeviceFileSource(custom));
        return;
      }
    }

    final asset = _assets[source];
    if (asset == null) return;
    await _player.play(AssetSource(asset));
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }
}

/// Widget testleri ve ses istenmeyen ortamlar için sessiz implementasyon.
class NoopCrisisAudioService implements CrisisAudioService {
  @override
  Future<void> play(CrisisAudioSource source) async {}

  @override
  Future<void> stop() async {}
}
