import 'dart:async';

import '../ai/decision_engine.dart';
import '../models/assistant_log.dart';
import '../services/offline_fallback_service.dart';
import '../services/speech_service.dart';

/// AI asistan katmanının arayüzü (Repository Pattern).
///
/// Ekranlar yalnızca bu arayüzü tanır; motor (mock ↔ Gemini) değişse de
/// UI kodu değişmez.
abstract class AssistantRepository {
  /// Asistanın gözlem/müdahale akışı.
  Stream<AssistantLog> watchLogs();

  /// Bir çevresel gözlemi işler: log üretir, karar verir ve sesli
  /// yönlendirme yapar. `jpegBytes` Adım 6'da ESP32-CAM karesi olacak;
  /// şimdilik simülasyon girişinden beslenir.
  Future<void> processObservation(String observation, {List<int>? jpegBytes});

  void dispose();
}

/// Gemini destekli gerçek pipeline:
/// gözlem → system prompt + Gemini → kısa yönlendirme → TTS.
/// Çevrimdışıysa OfflineFallbackService devreye girer.
class GeminiAssistantRepository implements AssistantRepository {
  GeminiAssistantRepository({
    required DecisionEngine engine,
    required SpeechService speech,
    required String? Function() systemPrompt,
    bool Function()? isMuted,
    Future<bool> Function()? isOnline,
    OfflineFallbackService? offlineFallback,
  })  : _engine = engine,
        _speech = speech,
        _systemPrompt = systemPrompt,
        _isMuted = isMuted ?? (() => false),
        _isOnline = isOnline ?? (() async => true),
        _offlineFallback = offlineFallback;

  final DecisionEngine _engine;
  final SpeechService _speech;
  final String? Function() _systemPrompt;
  final bool Function() _isMuted;
  final Future<bool> Function() _isOnline;
  final OfflineFallbackService? _offlineFallback;

  final _controller = StreamController<AssistantLog>.broadcast();

  void _emit(LogType type, String message) {
    if (_controller.isClosed) return;
    _controller.add(
      AssistantLog(timestamp: DateTime.now(), type: type, message: message),
    );
  }

  @override
  Stream<AssistantLog> watchLogs() => _controller.stream;

  @override
  Future<void> processObservation(
    String observation, {
    List<int>? jpegBytes,
  }) async {
    _emit(LogType.observation, observation);

    if (_isMuted()) {
      _emit(
        LogType.system,
        'Kriz modu aktif — yapay zeka susturuldu, yönlendirme üretilmedi.',
      );
      return;
    }

    if (!await _isOnline()) {
      await _runOfflineFallback();
      return;
    }

    final prompt = _systemPrompt();
    if (prompt == null) {
      _emit(LogType.system, 'Çocuk profili tanımlı değil; karar üretilemedi.');
      return;
    }

    try {
      final guidance = await _engine.decide(
        systemPrompt: prompt,
        observation: observation,
        jpegBytes: jpegBytes,
      );
      _emit(LogType.intervention, '"$guidance" yönlendirmesi iletildi.');
      await _speech.speak(guidance);
    } catch (error) {
      _emit(LogType.system, 'Karar üretilemedi, çevrimdışı moda geçiliyor.');
      await _runOfflineFallback();
    }
  }

  Future<void> _runOfflineFallback() async {
    final fallback = _offlineFallback;
    if (fallback == null) {
      _emit(LogType.system, 'Çevrimdışı: yedek içerik tanımlı değil.');
      return;
    }
    final phrase = await fallback.playComfort();
    _emit(
      LogType.intervention,
      '"$phrase" (çevrimdışı yedek) yönlendirmesi iletildi.',
    );
  }

  @override
  void dispose() => _controller.close();
}

/// Donanım ve API anahtarı olmadan demo yapılabilmesi için senaryolu akış.
class MockAssistantRepository implements AssistantRepository {
  MockAssistantRepository({
    SpeechService? speech,
    bool Function()? isMuted,
    Future<bool> Function()? isOnline,
    OfflineFallbackService? offlineFallback,
  })  : _speech = speech ?? NoopSpeechService(),
        _isMuted = isMuted ?? (() => false),
        _isOnline = isOnline ?? (() async => true),
        _offlineFallback = offlineFallback {
    _controller = StreamController<AssistantLog>.broadcast(
      onListen: _startScript,
    );
  }

  final SpeechService _speech;
  final bool Function() _isMuted;
  final Future<bool> Function() _isOnline;
  final OfflineFallbackService? _offlineFallback;
  late final StreamController<AssistantLog> _controller;
  Timer? _timer;
  var _scriptIndex = 0;

  static const _script = <(LogType, String)>[
    (LogType.system, 'Gözlük modülü bağlandı, izleme başladı.'),
    (LogType.observation, 'Önde küçük bir köpek görüldü.'),
    (
      LogType.intervention,
      '"Korkma, o sadece küçük ve sevimli bir köpek." yönlendirmesi iletildi.',
    ),
    (LogType.observation, 'Ortam gürültüsü yükseliyor (kalabalık).'),
    (LogType.intervention, 'Nefes egzersizi hatırlatması yapıldı.'),
    (LogType.praise, 'Harikasın! Çok sakin kaldın.'),
    (LogType.system, 'Stres göstergeleri normale döndü.'),
  ];

  void _startScript() {
    _timer ??= Timer.periodic(const Duration(seconds: 4), (_) {
      if (_isMuted()) return;
      final (type, message) = _script[_scriptIndex % _script.length];
      _emit(type, message);
      _scriptIndex++;
    });
  }

  void _emit(LogType type, String message) {
    if (_controller.isClosed) return;
    _controller.add(
      AssistantLog(timestamp: DateTime.now(), type: type, message: message),
    );
  }

  @override
  Stream<AssistantLog> watchLogs() => _controller.stream;

  @override
  Future<void> processObservation(
    String observation, {
    List<int>? jpegBytes,
  }) async {
    _emit(LogType.observation, observation);

    if (_isMuted()) {
      _emit(
        LogType.system,
        'Kriz modu aktif — yapay zeka susturuldu, yönlendirme üretilmedi.',
      );
      return;
    }

    if (!await _isOnline()) {
      final fallback = _offlineFallback;
      if (fallback != null) {
        final phrase = await fallback.playComfort();
        _emit(
          LogType.intervention,
          '"$phrase" (çevrimdışı yedek) yönlendirmesi iletildi.',
        );
      } else {
        _emit(LogType.system, 'Çevrimdışı: yedek içerik tanımlı değil.');
      }
      return;
    }

    const guidance = 'Sakin ol, ben yanındayım. Her şey yolunda.';
    _emit(
      LogType.intervention,
      '"$guidance" yönlendirmesi iletildi. (demo modu)',
    );
    await _speech.speak(guidance);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
