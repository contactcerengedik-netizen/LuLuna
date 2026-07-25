import 'package:flutter_test/flutter_test.dart';
import 'package:luluna/data/ai/decision_engine.dart';
import 'package:luluna/data/models/assistant_log.dart';
import 'package:luluna/data/models/child_profile.dart';
import 'package:luluna/data/repositories/assistant_repository.dart';
import 'package:luluna/data/services/offline_fallback_service.dart';
import 'package:luluna/data/services/speech_service.dart';

class _FakeEngine implements DecisionEngine {
  String? lastSystemPrompt;
  String? lastObservation;

  @override
  Future<String> decide({
    required String systemPrompt,
    required String observation,
    List<int>? jpegBytes,
  }) async {
    lastSystemPrompt = systemPrompt;
    lastObservation = observation;
    return 'Korkma, o sadece küçük bir köpek.';
  }
}

class _ThrowingEngine implements DecisionEngine {
  @override
  Future<String> decide({
    required String systemPrompt,
    required String observation,
    List<int>? jpegBytes,
  }) async {
    throw Exception('ağ hatası');
  }
}

class _RecordingSpeech implements SpeechService {
  final spoken = <String>[];
  VoiceTone? tone;
  var stopped = false;

  @override
  Future<void> configureTone(VoiceTone tone) async => this.tone = tone;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async => stopped = true;
}

class _RecordingOfflineFallback implements OfflineFallbackService {
  var calls = 0;

  @override
  Future<String> playComfort() async {
    calls++;
    return AssetOfflineFallbackService.comfortPhrase;
  }
}

void main() {
  group('GeminiAssistantRepository', () {
    test('gözlemi işler: log + karar + TTS', () async {
      final engine = _FakeEngine();
      final speech = _RecordingSpeech();
      final repo = GeminiAssistantRepository(
        engine: engine,
        speech: speech,
        systemPrompt: () => 'SYSTEM PROMPT',
      );

      final logs = <AssistantLog>[];
      final sub = repo.watchLogs().listen(logs.add);

      await repo.processObservation('Önde büyük bir köpek var.');
      await Future<void>.delayed(Duration.zero);

      expect(logs, hasLength(2));
      expect(logs[0].type, LogType.observation);
      expect(logs[1].type, LogType.intervention);
      expect(logs[1].message, contains('Korkma'));
      expect(engine.lastSystemPrompt, 'SYSTEM PROMPT');
      expect(engine.lastObservation, 'Önde büyük bir köpek var.');
      expect(speech.spoken, ['Korkma, o sadece küçük bir köpek.']);

      await sub.cancel();
      repo.dispose();
    });

    test('profil yoksa sistem logu üretir, motoru çağırmaz', () async {
      final repo = GeminiAssistantRepository(
        engine: _FakeEngine(),
        speech: _RecordingSpeech(),
        systemPrompt: () => null,
      );

      final logs = <AssistantLog>[];
      final sub = repo.watchLogs().listen(logs.add);
      await repo.processObservation('test');
      await Future<void>.delayed(Duration.zero);

      expect(logs.last.type, LogType.system);
      expect(logs.last.message, contains('profil'));

      await sub.cancel();
      repo.dispose();
    });

    test('motor hatasında çevrimdışı yedeğe düşer', () async {
      final speech = _RecordingSpeech();
      final fallback = _RecordingOfflineFallback();
      final repo = GeminiAssistantRepository(
        engine: _ThrowingEngine(),
        speech: speech,
        systemPrompt: () => 'SYSTEM PROMPT',
        offlineFallback: fallback,
      );

      final logs = <AssistantLog>[];
      final sub = repo.watchLogs().listen(logs.add);
      await repo.processObservation('test');
      await Future<void>.delayed(Duration.zero);

      expect(fallback.calls, 1);
      expect(logs.any((l) => l.message.contains('çevrimdışı moda')), isTrue);
      expect(logs.last.type, LogType.intervention);
      expect(speech.spoken, isEmpty);

      await sub.cancel();
      repo.dispose();
    });

    test('kriz modunda susturulunca motor ve TTS çağrılmaz', () async {
      final engine = _FakeEngine();
      final speech = _RecordingSpeech();
      var muted = true;
      final repo = GeminiAssistantRepository(
        engine: engine,
        speech: speech,
        systemPrompt: () => 'SYSTEM PROMPT',
        isMuted: () => muted,
      );

      final logs = <AssistantLog>[];
      final sub = repo.watchLogs().listen(logs.add);
      await repo.processObservation('Köpek yaklaşıyor');
      await Future<void>.delayed(Duration.zero);

      expect(logs.last.type, LogType.system);
      expect(logs.last.message, contains('Kriz modu'));
      expect(engine.lastObservation, isNull);
      expect(speech.spoken, isEmpty);

      await sub.cancel();
      repo.dispose();
    });

    test('çevrimdışıyken offline fallback devreye girer', () async {
      final engine = _FakeEngine();
      final speech = _RecordingSpeech();
      final fallback = _RecordingOfflineFallback();
      final repo = GeminiAssistantRepository(
        engine: engine,
        speech: speech,
        systemPrompt: () => 'SYSTEM PROMPT',
        isOnline: () async => false,
        offlineFallback: fallback,
      );

      final logs = <AssistantLog>[];
      final sub = repo.watchLogs().listen(logs.add);
      await repo.processObservation('Kalabalık');
      await Future<void>.delayed(Duration.zero);

      expect(fallback.calls, 1);
      expect(logs.last.type, LogType.intervention);
      expect(logs.last.message, contains('çevrimdışı'));
      expect(engine.lastObservation, isNull);

      await sub.cancel();
      repo.dispose();
    });
  });

  group('GeminiDecisionEngine istek/yanıt', () {
    test('istek gövdesine system prompt ve görüntü eklenir', () {
      final body = GeminiDecisionEngine.buildRequestBody(
        systemPrompt: 'PROMPT',
        observation: 'gözlem',
        jpegBytes: [1, 2, 3],
      );

      final systemParts =
          (body['system_instruction'] as Map)['parts'] as List;
      expect((systemParts.first as Map)['text'], 'PROMPT');

      final parts =
          ((body['contents'] as List).first as Map)['parts'] as List;
      expect((parts[0] as Map)['text'], 'gözlem');
      expect(
        ((parts[1] as Map)['inline_data'] as Map)['mime_type'],
        'image/jpeg',
      );
    });

    test('yanıttan metni ayıklar', () {
      final text = GeminiDecisionEngine.extractText({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'Merhaba '},
                {'text': 'dünya'},
              ],
            },
          },
        ],
      });
      expect(text, 'Merhaba dünya');
    });

    test('boş yanıtta null döner', () {
      expect(GeminiDecisionEngine.extractText(const {}), isNull);
    });
  });

  group('MockAssistantRepository', () {
    test('simüle gözleme demo yönlendirmesiyle yanıt verir', () async {
      final speech = _RecordingSpeech();
      final repo = MockAssistantRepository(speech: speech);

      final logs = <AssistantLog>[];
      final sub = repo.watchLogs().listen(logs.add);
      await repo.processObservation('Kalabalık bir ortam.');
      await Future<void>.delayed(Duration.zero);

      expect(
        logs.where((l) => l.type == LogType.intervention),
        isNotEmpty,
      );
      expect(speech.spoken, isNotEmpty);

      await sub.cancel();
      repo.dispose();
    });
  });
}
