import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../data/models/education_question.dart';
import '../../../data/models/skill_level.dart';
import '../domain/question_selection.dart';

/// Offline müfredat havuzu (`assets/curriculum/questions.json`).
/// `imageUrl` doluysa runtime'da Gemini görsel üretimi yapılmaz.
class CurriculumQuestionRepository {
  CurriculumQuestionRepository();

  List<EducationQuestion>? _cache;
  static const assetPath = 'assets/curriculum/questions.json';

  Future<List<EducationQuestion>> load() async {
    if (_cache != null) return _cache!;
    try {
      final raw = await rootBundle.loadString(assetPath);
      final list = jsonDecode(raw) as List<dynamic>;
      _cache = [
        for (final e in list)
          if (e is Map)
            fromCurriculumMap(Map<String, dynamic>.from(e)),
      ];
      debugPrint(
        '[Curriculum] ${_cache!.length} soru yüklendi '
        '(${_cache!.where(hasUsableImage).length} görselli)',
      );
    } catch (e) {
      debugPrint('[Curriculum] seed yok/okunamadı: $e');
      _cache = const [];
    }
    return _cache!;
  }

  static EducationQuestion fromCurriculumMap(Map<String, dynamic> map) {
    final area = map['area'] as String?;
    final skill = area == 'language'
        ? SkillArea.language
        : SkillArea.mathematics;
    final category =
        map['category'] as String? ?? map['skill'] as String? ?? 'addition';
    final difficulty =
        SkillTier.values.asNameMap()[map['difficulty'] as String?] ??
            SkillTier.easy;
    return EducationQuestion(
      id: map['id'] as String? ?? '',
      category: category,
      skill: skill,
      difficulty: difficulty,
      instruction: map['instruction'] as String? ?? '',
      questionText: map['questionText'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      solutionImageUrl:
          map['solutionImageUrl'] as String? ?? map['imageUrl'] as String?,
      choices: [
        for (final e in (map['choices'] as List? ?? const [])) '$e',
      ],
      correctAnswer: '${map['correctAnswer'] ?? map['answer'] ?? ''}',
      explanation: map['explanation'] as String?,
      metadata: {
        'area': area ?? skill.name,
        'curriculum': true,
        'type': 'multipleChoice',
      },
    );
  }

  static bool hasUsableImage(EducationQuestion q) {
    final url = q.imageUrl;
    if (url == null || url.isEmpty) return false;
    if (url.startsWith('mock:')) return false;
    return url.startsWith('http') ||
        url.startsWith('data:image') ||
        url.startsWith('assets/');
  }

  /// Yeterli görselli soru varsa — AI tamamen atlanır.
  Future<List<EducationQuestion>?> pickReady({
    required SkillArea skill,
    required String category,
    required SkillTier difficulty,
    required int count,
    List<String> excludeIds = const [],
  }) async {
    final all = await load();
    final ready = all
        .where(
          (q) =>
              q.skill == skill &&
              q.category == category &&
              q.difficulty == difficulty &&
              hasUsableImage(q),
        )
        .toList();
    if (ready.length < count) {
      debugPrint(
        '[Curriculum] $category/$difficulty görselli ${ready.length}<$count '
        '→ AI/yerel yedek',
      );
      return null;
    }
    debugPrint(
      '[Curriculum] $category/$difficulty — $count görselli soru (Gemini yok)',
    );
    return QuestionSelection.pickWithoutRecent(
      pool: ready,
      recentIds: excludeIds,
      count: count,
    );
  }

  /// Sabit metin havuzu (görsel sonra eklenebilir).
  Future<List<EducationQuestion>?> pickBank({
    required SkillArea skill,
    required String category,
    required SkillTier difficulty,
    required int count,
    List<String> excludeIds = const [],
  }) async {
    final all = await load();
    final bank = all
        .where(
          (q) =>
              q.skill == skill &&
              q.category == category &&
              q.difficulty == difficulty,
        )
        .toList();
    if (bank.length < count) return null;
    return QuestionSelection.pickWithoutRecent(
      pool: bank,
      recentIds: excludeIds,
      count: count,
    );
  }
}
