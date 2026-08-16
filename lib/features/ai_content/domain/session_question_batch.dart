import '../../../data/models/education_question.dart';
import '../../../data/models/sequence_question.dart';
import '../../../data/models/skill_level.dart';

/// Oturum için batch unique soru üretici (OpenAI / Gemini).
abstract class SessionQuestionBatchService {
  bool get isConfigured;

  Future<List<EducationQuestion>> generateSessionQuestions({
    required SkillArea skill,
    required String category,
    required SkillTier difficulty,
    int count = 10,
    List<String> excludeHints = const [],
  });
}

/// AI JSON → EducationQuestion ortak eşleyici.
class SessionQuestionMapper {
  static EducationQuestion fromAiMap({
    required Map<String, dynamic> map,
    required int index,
    required SkillArea skill,
    required String category,
    required SkillTier difficulty,
  }) {
    final type = map['type'] as String? ?? 'multipleChoice';
    final id = map['id'] as String? ??
        'ai-${skill.name}-$category-${difficulty.name}-$index';
    final choices = [
      for (final e in (map['choices'] as List? ?? const [])) '$e',
    ];
    final correct = '${map['correctAnswer'] ?? ''}';
    final objects = [
      for (final e in (map['objects'] as List? ?? const []))
        Map<String, dynamic>.from(e as Map),
    ];
    final characters = [
      for (final e in (map['characters'] as List? ?? const []))
        Map<String, dynamic>.from(e as Map),
    ];
    final caption = map['sceneCaption'] as String? ??
        map['questionText'] as String? ??
        '';

    final metadata = <String, dynamic>{
      'type': type == 'order' ? 'sequence' : type,
      'aiGenerated': true,
      'operation': map['operation'],
      'objects': objects,
      'characters': characters,
      'sceneVisual': {
        'template': 'scene_5n1k',
        'caption': caption,
        'objects': [
          for (final o in objects) '${o['type'] ?? 'nesne'}',
        ],
        'character': characters.isNotEmpty
            ? '${characters.first['name'] ?? ''}'
            : null,
        'setting': category,
      },
    };

    if (type == 'sequence' || type == 'order') {
      final labels = [
        for (final e in (map['correctOrderLabels'] as List? ?? choices)) '$e',
      ];
      if (labels.isNotEmpty) {
        final seq = SequenceQuestion.shuffled(labels);
        metadata.addAll(seq.toMap());
        final iconsRaw = map['cardIcons'];
        if (iconsRaw is Map) {
          metadata['cardIcons'] = {
            for (final e in iconsRaw.entries) '${e.key}': '${e.value}',
          };
        }
        metadata['visualCards'] = true;
        return EducationQuestion(
          id: id,
          category: category,
          skill: skill,
          difficulty: difficulty,
          instruction: map['instruction'] as String? ??
              'Görselli kartları sürükle ve sırala.',
          questionText: map['questionText'] as String? ?? '',
          choices: seq.items,
          correctAnswer: SequenceQuestion.encode(seq.correctItems),
          explanation: map['explanation'] as String?,
          metadata: metadata,
        );
      }
    }

    return EducationQuestion(
      id: id,
      category: category,
      skill: skill,
      difficulty: difficulty,
      instruction: map['instruction'] as String? ?? 'Soruyu çöz.',
      questionText: map['questionText'] as String? ?? '',
      choices: choices.isEmpty && correct.isNotEmpty ? [correct] : choices,
      correctAnswer: correct,
      explanation: map['explanation'] as String?,
      metadata: metadata,
    );
  }
}
