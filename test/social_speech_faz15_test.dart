import 'package:flutter_test/flutter_test.dart';

import 'package:luluna/core/speech/platform_speech_recognition.dart';
import 'package:luluna/features/dialogue/domain/dialogue_models.dart';
import 'package:luluna/features/social_speech/data/social_dialogue_catalog.dart';

void main() {
  group('SocialDialogueCatalog', () {
    test('üç modül Dialogue üretir', () {
      for (final m in SocialSpeechModule.values) {
        final d = m.dialogue();
        expect(d.turns, isNotEmpty, reason: m.name);
        expect(
          d.turns.any((t) => t.responseType != DialogueResponseType.none),
          isTrue,
        );
      }
    });

    test('telaffuz free_speech → choice tamamlanır', () {
      final dlg = SocialDialogueCatalog.pronunciation(word: 'elma');
      final eng = DialogueRunnerEngine(dlg);
      expect(eng.current.responseType, DialogueResponseType.freeSpeech);
      expect(eng.submitSpeech('elma').correct, isTrue);
      eng.skipNone();
      expect(eng.current.responseType, DialogueResponseType.choice);
      expect(eng.submitChoice('elma').correct, isTrue);
      eng.skipNone();
      expect(eng.isComplete, isTrue);
    });

    test('duygu diyaloğu choice + free_speech', () {
      final dlg = SocialDialogueCatalog.emotionSocial();
      final eng = DialogueRunnerEngine(dlg);
      expect(eng.submitChoice('Oyuncağı kırıldı').correct, isTrue);
      expect(
        eng.submitChoice('Yanındayım, yardım edebilirim').correct,
        isTrue,
      );
      expect(eng.current.responseType, DialogueResponseType.freeSpeech);
      expect(eng.submitSpeech('çok üzgün').correct, isTrue);
      eng.skipNone();
      expect(eng.isComplete, isTrue);
    });
  });

  group('MockSpeechRecognitionService', () {
    test('scripted transcript', () async {
      final stt = MockSpeechRecognitionService(scripted: const ['su', 'elma']);
      expect(await stt.listenOnce(), 'su');
      expect(await stt.listenOnce(), 'elma');
    });

    test('mockSttForKeywords', () async {
      final stt = mockSttForKeywords(const ['üzgün']);
      expect(await stt.listenOnce(), 'üzgün');
    });
  });

  group('PlatformSpeechRecognitionService fallback', () {
    test('plugin yokken fallback mock', () async {
      final stt = PlatformSpeechRecognitionService(
        fallback: MockSpeechRecognitionService(scripted: const ['elma']),
      );
      // Initialize may fail in test VM → fallback
      final text = await stt.listenOnce(
        timeout: const Duration(milliseconds: 100),
      );
      expect(text, isNotEmpty);
    });
  });
}
