import '../../education/domain/activity_models.dart';

/// Oturum özeti (PHASE 7 analytics event).
class ActivitySessionEvent {
  const ActivitySessionEvent({
    required this.id,
    required this.studentId,
    required this.activityId,
    required this.skill,
    required this.category,
    required this.difficulty,
    required this.startedAt,
    required this.finishedAt,
    required this.correctCount,
    required this.wrongCount,
    required this.attemptCount,
    required this.score,
    required this.durationMs,
  });

  final String id;
  final String studentId;
  final String activityId;
  final String skill;
  final String category;
  final String difficulty;
  final DateTime startedAt;
  final DateTime finishedAt;
  final int correctCount;
  final int wrongCount;
  final int attemptCount;
  final double score;
  final int durationMs;

  Map<String, dynamic> toMap() => {
        'id': id,
        'studentId': studentId,
        'activityId': activityId,
        'skill': skill,
        'category': category,
        'difficulty': difficulty,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt.toIso8601String(),
        'correctCount': correctCount,
        'wrongCount': wrongCount,
        'attemptCount': attemptCount,
        'score': score,
        'durationMs': durationMs,
      };

  factory ActivitySessionEvent.fromMap(Map<String, dynamic> map) {
    return ActivitySessionEvent(
      id: map['id'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      activityId: map['activityId'] as String? ?? '',
      skill: map['skill'] as String? ?? '',
      category: map['category'] as String? ?? '',
      difficulty: map['difficulty'] as String? ?? '',
      startedAt:
          DateTime.tryParse(map['startedAt'] as String? ?? '') ?? DateTime.now(),
      finishedAt: DateTime.tryParse(map['finishedAt'] as String? ?? '') ??
          DateTime.now(),
      correctCount: map['correctCount'] as int? ?? 0,
      wrongCount: map['wrongCount'] as int? ?? 0,
      attemptCount: map['attemptCount'] as int? ?? 0,
      score: (map['score'] as num?)?.toDouble() ?? 0,
      durationMs: map['durationMs'] as int? ?? 0,
    );
  }

  factory ActivitySessionEvent.fromResult({
    required String id,
    required String studentId,
    required String activityId,
    required ActivitySessionResult result,
    required DateTime startedAt,
  }) {
    final finished = result.finishedAt;
    return ActivitySessionEvent(
      id: id,
      studentId: studentId,
      activityId: activityId,
      skill: result.skill,
      category: result.category,
      difficulty: result.difficulty,
      startedAt: startedAt,
      finishedAt: finished,
      correctCount: result.correctCount,
      wrongCount: result.wrongCount,
      attemptCount: result.attempts.length,
      score: result.scorePercent,
      durationMs: finished.difference(startedAt).inMilliseconds,
    );
  }
}

class CategoryPerformance {
  const CategoryPerformance({
    required this.categoryId,
    required this.label,
    required this.correct,
    required this.wrong,
  });

  final String categoryId;
  final String label;
  final int correct;
  final int wrong;

  int get attempts => correct + wrong;
  double get successRate => attempts == 0 ? 0 : correct / attempts;
  double get errorRate => attempts == 0 ? 0 : wrong / attempts;
}

class StudentAnalytics {
  const StudentAnalytics({
    required this.studentId,
    required this.sessions,
    required this.attempts,
    required this.byCategory,
    this.bySkillKey = const [],
    this.byUnifiedArea = const [],
  });

  final String studentId;
  final List<ActivitySessionEvent> sessions;
  final List<ActivityAttempt> attempts;
  final List<CategoryPerformance> byCategory;
  /// skill_key (toplama, 5n1k, …) bazlı özet.
  final List<CategoryPerformance> bySkillKey;
  /// v3 15 öğrenme alanı (Faz 17).
  final List<CategoryPerformance> byUnifiedArea;

  int get completedActivities => sessions.length;

  double get successRate {
    final total = attempts.length;
    if (total == 0) return 0;
    final ok = attempts.where((e) => e.correct).length;
    return ok / total;
  }

  double get errorRate => attempts.isEmpty ? 0 : 1 - successRate;
}

class StudentReport {
  const StudentReport({
    required this.studentId,
    required this.studentName,
    required this.dateRangeStart,
    required this.dateRangeEnd,
    required this.completedActivities,
    required this.skillScores,
    required this.successRate,
    required this.errorRate,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.teacherNotes = '',
  });

  final String studentId;
  final String studentName;
  final DateTime dateRangeStart;
  final DateTime dateRangeEnd;
  final int completedActivities;
  final List<CategoryPerformance> skillScores;
  final double successRate;
  final double errorRate;
  final int correctCount;
  final int wrongCount;
  final String teacherNotes;

  StudentReport copyWith({String? teacherNotes}) {
    return StudentReport(
      studentId: studentId,
      studentName: studentName,
      dateRangeStart: dateRangeStart,
      dateRangeEnd: dateRangeEnd,
      completedActivities: completedActivities,
      skillScores: skillScores,
      successRate: successRate,
      errorRate: errorRate,
      correctCount: correctCount,
      wrongCount: wrongCount,
      teacherNotes: teacherNotes ?? this.teacherNotes,
    );
  }

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'studentName': studentName,
        'dateRangeStart': dateRangeStart.toIso8601String(),
        'dateRangeEnd': dateRangeEnd.toIso8601String(),
        'completedActivities': completedActivities,
        'successRate': successRate,
        'errorRate': errorRate,
        'correctCount': correctCount,
        'wrongCount': wrongCount,
        'teacherNotes': teacherNotes,
        'skillScores': [
          for (final s in skillScores)
            {
              'categoryId': s.categoryId,
              'label': s.label,
              'correct': s.correct,
              'wrong': s.wrong,
            },
        ],
      };
}
