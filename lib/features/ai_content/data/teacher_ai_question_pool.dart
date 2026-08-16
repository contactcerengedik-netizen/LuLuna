import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/education_question.dart';
import '../../../data/models/skill_keys.dart';
import '../../../data/models/skill_level.dart';
import '../domain/ai_content_models.dart';

/// Yayınlanan öğretmen AI soruları — kategori oturumlarına enjekte edilir.
class TeacherAiQuestionPool {
  TeacherAiQuestionPool(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'teacher_ai_question_pool_v1';

  List<EducationQuestion> loadAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list)
          EducationQuestion.fromMap(Map<String, dynamic>.from(e as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveAll(List<EducationQuestion> items) async {
    await _prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toMap()).toList()),
    );
  }

  Future<void> upsertFromActivity(TeacherAiActivity activity) async {
    final skillKey = activity.skillKey;
    if (skillKey == null) return;
    final category = SkillKeys.toCategory(skillKey);
    if (category == null) return;
    final imageUrl = activity.image.assetPath;
    final q = EducationQuestion(
      id: activity.id,
      category: category,
      skill: SkillKeys.areaFor(skillKey),
      difficulty: activity.structured.difficulty,
      instruction: activity.structured.instruction,
      questionText: activity.structured.questionText,
      imageUrl: (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.startsWith('mock:'))
          ? imageUrl
          : null,
      solutionImageUrl: imageUrl,
      choices: activity.structured.choices.isEmpty
          ? [activity.structured.answer]
          : activity.structured.choices,
      correctAnswer: activity.structured.answer,
      explanation: activity.structured.explanation,
      metadata: {
        'type': 'multipleChoice',
        'source': activity.source,
        'skillKey': skillKey,
        'teacherAi': true,
        if (activity.targetStudentId != null)
          'priorityStudentId': activity.targetStudentId,
      },
    );
    final all = [...loadAll()];
    final i = all.indexWhere((e) => e.id == q.id);
    if (i >= 0) {
      all[i] = q;
    } else {
      all.insert(0, q);
    }
    await saveAll(all);
  }

  List<EducationQuestion> forSession({
    required String category,
    required SkillTier difficulty,
    String? studentId,
  }) {
    final all = loadAll().where(
      (q) => q.category == category && q.difficulty == difficulty,
    );
    final prioritized = <EducationQuestion>[];
    final rest = <EducationQuestion>[];
    for (final q in all) {
      final pri = q.metadata['priorityStudentId'] as String?;
      if (studentId != null &&
          pri != null &&
          (pri == studentId || pri.startsWith('demo-student'))) {
        prioritized.add(q);
      } else {
        rest.add(q);
      }
    }
    return [...prioritized, ...rest];
  }
}
