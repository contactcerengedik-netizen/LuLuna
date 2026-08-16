/// Diyalog motoru modelleri (prompt v3 §2.3 — Kural B).
enum DialogueSpeaker { aiCharacter, student }

enum DialogueResponseType { choice, freeSpeech, none }

class DialogueTurn {
  const DialogueTurn({
    required this.id,
    required this.speaker,
    required this.text,
    required this.responseType,
    this.audioUrl,
    this.choices = const [],
    this.expectedKeywords = const [],
    this.onCorrectFeedback = 'Tebrikler!',
    this.onIncorrectFeedback = 'Tekrar deneyelim.',
    this.imageUrl,
  });

  final String id;
  final DialogueSpeaker speaker;
  final String text;
  final DialogueResponseType responseType;
  final String? audioUrl;
  final List<String> choices;
  final List<String> expectedKeywords;
  final String onCorrectFeedback;
  final String onIncorrectFeedback;
  final String? imageUrl;

  Map<String, dynamic> toMap() => {
        'id': id,
        'speaker': speaker.name,
        'text': text,
        'responseType': responseType.name,
        'audioUrl': audioUrl,
        'choices': choices,
        'expectedKeywords': expectedKeywords,
        'onCorrectFeedback': onCorrectFeedback,
        'onIncorrectFeedback': onIncorrectFeedback,
        'imageUrl': imageUrl,
      };

  factory DialogueTurn.fromMap(Map<String, dynamic> map) {
    return DialogueTurn(
      id: map['id'] as String? ?? '',
      speaker: DialogueSpeaker.values.asNameMap()[map['speaker'] as String?] ??
          DialogueSpeaker.aiCharacter,
      text: map['text'] as String? ?? '',
      responseType: DialogueResponseType.values
              .asNameMap()[map['responseType'] as String?] ??
          DialogueResponseType.none,
      audioUrl: map['audioUrl'] as String?,
      choices: [for (final e in (map['choices'] as List? ?? const [])) '$e'],
      expectedKeywords: [
        for (final e in (map['expectedKeywords'] as List? ?? const [])) '$e',
      ],
      onCorrectFeedback: map['onCorrectFeedback'] as String? ?? 'Tebrikler!',
      onIncorrectFeedback:
          map['onIncorrectFeedback'] as String? ?? 'Tekrar deneyelim.',
      imageUrl: map['imageUrl'] as String?,
    );
  }
}

class Dialogue {
  const Dialogue({
    required this.id,
    required this.topic,
    required this.level,
    required this.turns,
    this.conceptId,
  });

  final String id;
  final String topic;
  final String level;
  final String? conceptId;
  final List<DialogueTurn> turns;

  Map<String, dynamic> toMap() => {
        'id': id,
        'topic': topic,
        'level': level,
        'conceptId': conceptId,
        'turns': turns.map((e) => e.toMap()).toList(),
      };

  factory Dialogue.fromMap(Map<String, dynamic> map) {
    return Dialogue(
      id: map['id'] as String? ?? '',
      topic: map['topic'] as String? ?? '',
      level: map['level'] as String? ?? 'easy',
      conceptId: map['conceptId'] as String?,
      turns: [
        for (final e in (map['turns'] as List? ?? const []))
          DialogueTurn.fromMap(Map<String, dynamic>.from(e as Map)),
      ],
    );
  }

  /// Kavramdan örnek diyalog (mock / demo).
  factory Dialogue.forConcept({
    required String conceptName,
    required String conceptId,
    String level = 'easy',
  }) {
    final name = conceptName.trim().isEmpty ? 'elma' : conceptName.trim();
    return Dialogue(
      id: 'dlg_$conceptId',
      topic: name,
      level: level,
      conceptId: conceptId,
      turns: [
        DialogueTurn(
          id: 't1',
          speaker: DialogueSpeaker.aiCharacter,
          text: 'Bak, bu bir $name. Sen de “$name” de.',
          responseType: DialogueResponseType.freeSpeech,
          expectedKeywords: [name.toLowerCase()],
          imageUrl: 'mock://dialogue/$conceptId/t1',
        ),
        DialogueTurn(
          id: 't2',
          speaker: DialogueSpeaker.aiCharacter,
          text: 'Hangisi $name?',
          responseType: DialogueResponseType.choice,
          choices: [name, 'masa', 'araba'],
          imageUrl: 'mock://dialogue/$conceptId/t2',
        ),
        DialogueTurn(
          id: 't3',
          speaker: DialogueSpeaker.aiCharacter,
          text: 'Aferin! $name ile ilgili konuşmayı bitirdik.',
          responseType: DialogueResponseType.none,
        ),
      ],
    );
  }
}

class DialogueEvalResult {
  const DialogueEvalResult({
    required this.correct,
    required this.feedback,
    required this.advance,
  });

  final bool correct;
  final String feedback;
  final bool advance;
}

/// Turn turn ilerleyen diyalog oturumu.
class DialogueRunnerEngine {
  DialogueRunnerEngine(this.dialogue) {
    if (dialogue.turns.isEmpty) {
      throw ArgumentError('Dialogue en az bir turn ister');
    }
  }

  final Dialogue dialogue;
  var _index = 0;

  int get index => _index;
  bool get isComplete => _index >= dialogue.turns.length;
  DialogueTurn get current => dialogue.turns[_index];

  /// free_speech: expectedKeywords ile basit kök/kelime eşleşmesi.
  DialogueEvalResult submitSpeech(String transcript) {
    final turn = current;
    if (turn.responseType != DialogueResponseType.freeSpeech) {
      throw StateError('Bu tur free_speech değil');
    }
    final ok = matchesKeywords(transcript, turn.expectedKeywords);
    if (ok) {
      _index++;
      return DialogueEvalResult(
        correct: true,
        feedback: turn.onCorrectFeedback,
        advance: true,
      );
    }
    return DialogueEvalResult(
      correct: false,
      feedback: turn.onIncorrectFeedback,
      advance: false,
    );
  }

  DialogueEvalResult submitChoice(String choice) {
    final turn = current;
    if (turn.responseType != DialogueResponseType.choice) {
      throw StateError('Bu tur choice değil');
    }
    final expected = turn.choices.isNotEmpty ? turn.choices.first : '';
    final ok = choice.trim().toLowerCase() == expected.trim().toLowerCase();
    if (ok) {
      _index++;
      return DialogueEvalResult(
        correct: true,
        feedback: turn.onCorrectFeedback,
        advance: true,
      );
    }
    return DialogueEvalResult(
      correct: false,
      feedback: turn.onIncorrectFeedback,
      advance: false,
    );
  }

  /// `none` turlarını otomatik geç.
  void skipNone() {
    while (!isComplete && current.responseType == DialogueResponseType.none) {
      _index++;
    }
  }

  static bool matchesKeywords(String transcript, List<String> keywords) {
    final t = _normalize(transcript);
    if (t.isEmpty || keywords.isEmpty) return false;
    for (final k in keywords) {
      final key = _normalize(k);
      if (key.isEmpty) continue;
      if (t.contains(key) || key.contains(t)) return true;
    }
    return false;
  }

  static String _normalize(String s) =>
      s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// STT soyutlaması — mock ile ilerlenir.
abstract class SpeechRecognitionService {
  Future<String> listenOnce({Duration timeout = const Duration(seconds: 4)});
}

class MockSpeechRecognitionService implements SpeechRecognitionService {
  MockSpeechRecognitionService({this.scripted = const ['elma']});

  final List<String> scripted;
  var _i = 0;

  @override
  Future<String> listenOnce({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (scripted.isEmpty) return '';
    final out = scripted[_i % scripted.length];
    _i++;
    return out;
  }
}
