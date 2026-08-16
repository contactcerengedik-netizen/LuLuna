/// Aktivite denemesi — analytics (PHASE 7) için temel kayıt.
class ActivityAttempt {
  const ActivityAttempt({
    required this.id,
    required this.studentId,
    required this.skill,
    required this.category,
    required this.difficulty,
    required this.questionId,
    required this.givenAnswer,
    required this.correct,
    required this.attemptedAt,
    this.durationMs,
    this.deviationScore,
  });

  final String id;
  final String studentId;
  final String skill;
  final String category;
  final String difficulty;
  final String questionId;
  final String givenAnswer;
  final bool correct;
  final DateTime attemptedAt;
  final int? durationMs;

  /// Path takip sapması (px) — motor beceriler (Faz 11).
  final double? deviationScore;

  Map<String, dynamic> toMap() => {
        'id': id,
        'studentId': studentId,
        'skill': skill,
        'category': category,
        'difficulty': difficulty,
        'questionId': questionId,
        'givenAnswer': givenAnswer,
        'correct': correct,
        'attemptedAt': attemptedAt.toIso8601String(),
        'durationMs': durationMs,
        'deviationScore': deviationScore,
      };

  factory ActivityAttempt.fromMap(Map<String, dynamic> map) {
    return ActivityAttempt(
      id: map['id'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      skill: map['skill'] as String? ?? '',
      category: map['category'] as String? ?? '',
      difficulty: map['difficulty'] as String? ?? '',
      questionId: map['questionId'] as String? ?? '',
      givenAnswer: map['givenAnswer'] as String? ?? '',
      correct: map['correct'] as bool? ?? false,
      attemptedAt:
          DateTime.tryParse(map['attemptedAt'] as String? ?? '') ??
              DateTime.now(),
      durationMs: map['durationMs'] as int?,
      deviationScore: (map['deviationScore'] as num?)?.toDouble(),
    );
  }
}

class ActivitySessionResult {
  const ActivitySessionResult({
    required this.skill,
    required this.category,
    required this.difficulty,
    required this.total,
    required this.correctCount,
    required this.wrongCount,
    required this.attempts,
    required this.finishedAt,
  });

  final String skill;
  final String category;
  final String difficulty;
  final int total;
  final int correctCount;
  final int wrongCount;
  final List<ActivityAttempt> attempts;
  final DateTime finishedAt;

  double get scorePercent =>
      total == 0 ? 0 : (correctCount / total) * 100;
}

/// Modül kategori tanımı.
class ActivityCategoryDef {
  const ActivityCategoryDef({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
  });

  final String id;
  final String title;
  final String description;
  /// Material icon anahtarı (UI map eder).
  final String iconName;
}
