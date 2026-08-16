import '../../../data/models/skill_keys.dart';
import '../../education/domain/activity_models.dart';
import '../../language/data/language_categories.dart';
import '../../mathematics/data/math_categories.dart';
import '../domain/analytics_models.dart';
import 'unified_skill_map.dart';

/// Deneme + oturum kayıtlarından beceri/kategori analitikleri.
class AnalyticsService {
  const AnalyticsService();

  StudentAnalytics build({
    required String studentId,
    required List<ActivityAttempt> attempts,
    required List<ActivitySessionEvent> sessions,
    DateTime? from,
    DateTime? to,
  }) {
    final toExclusive = to == null
        ? null
        : DateTime(to.year, to.month, to.day).add(const Duration(days: 1));

    final filteredAttempts = attempts.where((a) {
      if (!_belongsToStudent(studentId, a.studentId)) return false;
      if (from != null && a.attemptedAt.isBefore(from)) return false;
      if (toExclusive != null && !a.attemptedAt.isBefore(toExclusive)) {
        return false;
      }
      return true;
    }).toList();

    final filteredSessions = sessions.where((s) {
      if (!_belongsToStudent(studentId, s.studentId)) return false;
      if (from != null && s.finishedAt.isBefore(from)) return false;
      if (toExclusive != null && !s.finishedAt.isBefore(toExclusive)) {
        return false;
      }
      return true;
    }).toList();

    final byCat = <String, ({int correct, int wrong})>{};
    final bySkill = <String, ({int correct, int wrong})>{};

    for (final a in filteredAttempts) {
      final cat = byCat[a.category] ?? (correct: 0, wrong: 0);
      byCat[a.category] = a.correct
          ? (correct: cat.correct + 1, wrong: cat.wrong)
          : (correct: cat.correct, wrong: cat.wrong + 1);

      final skillKey = SkillKeys.fromCategory(a.category) ?? a.skill;
      final sk = bySkill[skillKey] ?? (correct: 0, wrong: 0);
      bySkill[skillKey] = a.correct
          ? (correct: sk.correct + 1, wrong: sk.wrong)
          : (correct: sk.correct, wrong: sk.wrong + 1);
    }

    final byCategory = [
      for (final e in byCat.entries)
        CategoryPerformance(
          categoryId: e.key,
          label: categoryLabel(e.key),
          correct: e.value.correct,
          wrong: e.value.wrong,
        ),
    ]..sort((a, b) => b.successRate.compareTo(a.successRate));

    final bySkillKey = [
      for (final e in bySkill.entries)
        CategoryPerformance(
          categoryId: e.key,
          label: skillKeyLabel(e.key),
          correct: e.value.correct,
          wrong: e.value.wrong,
        ),
    ]..sort((a, b) => b.successRate.compareTo(a.successRate));

    final byUnifiedArea = [
      for (final s in UnifiedAnalyticsBuilder.build(filteredAttempts))
        UnifiedAnalyticsBuilder.toCategoryPerformance(s),
    ];

    return StudentAnalytics(
      studentId: studentId,
      sessions: filteredSessions,
      attempts: filteredAttempts,
      byCategory: byCategory,
      bySkillKey: bySkillKey,
      byUnifiedArea: byUnifiedArea,
    );
  }

  StudentReport report({
    required String studentId,
    required String studentName,
    required StudentAnalytics analytics,
    DateTime? from,
    DateTime? to,
    String teacherNotes = '',
  }) {
    final end = to ?? DateTime.now();
    final start = from ?? end.subtract(const Duration(days: 30));
    return StudentReport(
      studentId: studentId,
      studentName: studentName,
      dateRangeStart: start,
      dateRangeEnd: end,
      completedActivities: analytics.completedActivities,
      skillScores: analytics.byUnifiedArea.isNotEmpty
          ? analytics.byUnifiedArea
          : (analytics.bySkillKey.isNotEmpty
              ? analytics.bySkillKey
              : analytics.byCategory),
      successRate: analytics.successRate,
      errorRate: analytics.errorRate,
      teacherNotes: teacherNotes,
      correctCount: analytics.attempts.where((e) => e.correct).length,
      wrongCount: analytics.attempts.where((e) => !e.correct).length,
    );
  }

  static String categoryLabel(String id) {
    final math = MathCategories.byId(id);
    if (math != null) return math.title;
    final lang = LanguageCategories.byId(id);
    if (lang != null) return lang.title;
    return switch (id) {
      'puzzle' => 'Puzzle',
      'math_addition' => 'Toplama (AI)',
      'language_comprehension' => 'Dil (AI)',
      'routine' => 'Rutin',
      'aac' => 'AAC',
      'match' => 'Kart eşleştirme',
      'flash' => 'Kısa süreli bellek',
      'pronunciation' => 'Telaffuz',
      'communication' => 'İletişim',
      'emotion' => 'Duygu / Sosyal',
      'patternComplete' => 'Örüntü',
      'dataRead' => 'Veri okuma',
      'categorization' => 'Eşleştirme',
      _ => skillKeyLabel(id),
    };
  }

  static String skillKeyLabel(String key) {
    final labeled = SkillKeys.label(key);
    if (labeled != key) return labeled;
    return switch (key) {
      'mathematics' => 'Matematik',
      'language' => 'Türkçe',
      'puzzle' => 'Puzzle',
      'tracing' => 'Çizgi',
      'coloring' => 'Boyama',
      'visualPerception' => 'Görsel algı',
      'communication' => 'İletişim',
      'dailyLife' => 'Günlük yaşam',
      _ => key,
    };
  }

  bool _belongsToStudent(String profileId, String attemptStudentId) {
    if (profileId == attemptStudentId) return true;
    if (profileId == 'demo-student-1' &&
        !attemptStudentId.startsWith('demo-student-')) {
      return true;
    }
    return false;
  }
}
