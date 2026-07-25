import 'package:flutter_test/flutter_test.dart';
import 'package:luluna/data/models/achievement_badge.dart';
import 'package:luluna/data/models/crisis_state.dart';
import 'package:luluna/data/repositories/badge_repository.dart';
import 'package:luluna/data/services/crisis_audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingCrisisAudio implements CrisisAudioService {
  final played = <CrisisAudioSource>[];
  var stopCount = 0;

  @override
  Future<void> play(CrisisAudioSource source) async => played.add(source);

  @override
  Future<void> stop() async => stopCount++;
}

void main() {
  group('BadgeRepository', () {
    test('rozetleri kaydeder ve yükler', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = BadgeRepository(prefs);

      final badge = AchievementBadge(
        id: '1',
        title: 'Harika An',
        earnedAt: DateTime(2026, 7, 25, 16, 0),
      );
      await repo.save([badge]);

      final loaded = repo.load();
      expect(loaded, hasLength(1));
      expect(loaded.first.title, 'Harika An');
    });
  });

  group('CrisisAudioService noop', () {
    test('sessiz implementasyon hata vermez', () async {
      final audio = NoopCrisisAudioService();
      await audio.play(CrisisAudioSource.parentVoice);
      await audio.play(CrisisAudioSource.calmingMusic);
      await audio.stop();
      expect(true, isTrue);
    });
  });

  group('Recording crisis audio', () {
    test('play/stop çağrılarını kaydeder', () async {
      final audio = _RecordingCrisisAudio();
      await audio.play(CrisisAudioSource.parentVoice);
      await audio.play(CrisisAudioSource.calmingMusic);
      await audio.stop();
      expect(audio.played, [
        CrisisAudioSource.parentVoice,
        CrisisAudioSource.calmingMusic,
      ]);
      expect(audio.stopCount, 1);
    });
  });
}
