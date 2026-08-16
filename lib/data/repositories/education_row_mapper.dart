import '../models/education_question.dart';
import '../models/skill_keys.dart';
import '../models/skill_level.dart';
import '../models/student_profile.dart';

/// Supabase satır → domain model (unit test edilebilir, client yok).
abstract final class EducationRowMapper {
  static StudentProfile studentFromRow(Map<String, dynamic> row) {
    final skillsRaw = row['student_skill_levels'];
    final teachersRaw = row['teacher_student'];
    final skillLevels = <StudentSkillLevel>[];
    if (skillsRaw is List) {
      for (final e in skillsRaw) {
        if (e is Map) {
          skillLevels.add(skillLevelFromRow(Map<String, dynamic>.from(e)));
        }
      }
    }
    final teacherIds = <String>[];
    if (teachersRaw is List) {
      for (final e in teachersRaw) {
        if (e is Map && e['teacher_id'] != null) {
          teacherIds.add(e['teacher_id'].toString());
        }
      }
    }
    return StudentProfile(
      id: row['id']?.toString() ?? '',
      name: row['name'] as String? ?? '',
      birthDate: DateTime.tryParse(row['birth_date']?.toString() ?? ''),
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
      teacherIds: teacherIds,
      skillLevels: skillLevels,
      accessibility: AccessibilitySettings.fromMap(
        Map<String, dynamic>.from(
          (row['accessibility'] as Map?) ?? const {},
        ),
      ),
      preferences: Map<String, dynamic>.from(
        (row['preferences'] as Map?) ?? const {},
      ),
    );
  }

  static StudentSkillLevel skillLevelFromRow(Map<String, dynamic> e) {
    final skillKey = e['skill_key'] as String? ?? e['skillKey'] as String?;
    final skillName = e['skill'] as String? ?? '';
    final area = SkillArea.values.asNameMap()[skillName] ??
        (skillKey != null
            ? SkillKeys.areaFor(skillKey)
            : SkillArea.mathematics);
    final sourceName = e['source'] as String?;
    return StudentSkillLevel(
      skill: area,
      skillKey: skillKey ?? skillName,
      tier: SkillTier.values.asNameMap()[e['tier'] as String? ?? e['level']] ??
          SkillTier.easy,
      source: SkillLevelSource.values.asNameMap()[sourceName] ??
          SkillLevelSource.teacherSet,
      masteryPercent: (e['mastery_percent'] as num?)?.toDouble() ??
          (e['masteryPercent'] as num?)?.toDouble() ??
          0,
      updatedAt: DateTime.tryParse(e['updated_at']?.toString() ?? ''),
    );
  }

  static Map<String, dynamic> skillLevelUpsert({
    required String studentUuid,
    required String skillKey,
    required SkillTier tier,
    SkillLevelSource source = SkillLevelSource.teacherSet,
  }) {
    return {
      'student_id': studentUuid,
      'skill': SkillKeys.areaFor(skillKey).name,
      'skill_key': skillKey,
      'tier': tier.name,
      'source': source.name,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  static EducationQuestion? questionFromActivityPayload(
    Map<String, dynamic> activity,
  ) {
    final payload = Map<String, dynamic>.from(
      (activity['payload'] as Map?) ?? const {},
    );
    final skillName = activity['skill'] as String? ?? '';
    final skill =
        SkillArea.values.asNameMap()[skillName] ?? SkillArea.mathematics;
    final tierName = activity['difficulty'] as String? ?? 'easy';
    final difficulty =
        SkillTier.values.asNameMap()[tierName] ?? SkillTier.easy;
    final answer = payload['correctAnswer'] as String?;
    if (answer == null || answer.isEmpty) return null;
    return EducationQuestion(
      id: activity['id']?.toString() ?? '',
      category: activity['category'] as String? ?? '',
      skill: skill,
      difficulty: difficulty,
      instruction: payload['instruction'] as String? ?? '',
      questionText: payload['questionText'] as String? ??
          (activity['title'] as String? ?? ''),
      choices: List<String>.from(payload['choices'] as List? ?? const []),
      correctAnswer: answer,
      explanation: payload['explanation'] as String?,
    );
  }

  static Map<String, dynamic> attemptAnswerInsert({
    required String studentUuid,
    required String skill,
    required String category,
    required String difficulty,
    required String questionId,
    required String givenAnswer,
    required bool correct,
    required DateTime attemptedAt,
    String? sessionId,
    int? durationMs,
    double? deviationScore,
  }) {
    return {
      'student_id': studentUuid,
      if (sessionId != null) 'session_id': sessionId,
      'skill': skill,
      'category': category,
      'difficulty': difficulty,
      'question_id': questionId,
      'given_answer': givenAnswer,
      'correct': correct,
      'attempted_at': attemptedAt.toIso8601String(),
      if (durationMs != null) 'duration_ms': durationMs,
      if (deviationScore != null) 'deviation_score': deviationScore,
    };
  }

  static Map<String, dynamic> sessionInsert({
    required String studentUuid,
    required String skill,
    required String category,
    required String difficulty,
    required DateTime startedAt,
    required DateTime finishedAt,
    required int correctCount,
    required int wrongCount,
    required int attemptCount,
    required double score,
    required int durationMs,
    String? activityId,
  }) {
    return {
      'student_id': studentUuid,
      if (activityId != null) 'activity_id': activityId,
      'skill': skill,
      'category': category,
      'difficulty': difficulty,
      'started_at': startedAt.toIso8601String(),
      'finished_at': finishedAt.toIso8601String(),
      'correct_count': correctCount,
      'wrong_count': wrongCount,
      'attempt_count': attemptCount,
      'score': score,
      'duration_ms': durationMs,
    };
  }
}
