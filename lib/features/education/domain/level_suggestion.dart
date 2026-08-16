import '../../../data/models/skill_keys.dart';
import '../../../data/models/skill_level.dart';
import 'activity_models.dart';

/// Seviye önerisi sonucu — otomatik uygulanmaz; öğretmen görür/onaylar.
class LevelSuggestion {
  const LevelSuggestion({
    required this.skillKey,
    required this.currentLevel,
    required this.suggestedLevel,
    required this.sampleSize,
    required this.successRate,
    required this.reason,
  });

  final String skillKey;
  final SkillTier currentLevel;
  final SkillTier suggestedLevel;
  final int sampleSize;
  final double successRate;
  final String reason;

  bool get differsFromCurrent => suggestedLevel != currentLevel;
}

/// Basit eşik kuralı (prompt §6): son N denemede başarı > %80 → üst seviye.
class LevelSuggestionEngine {
  const LevelSuggestionEngine({
    this.windowSize = 10,
    this.upgradeThreshold = 0.80,
    this.downgradeThreshold = 0.40,
    this.minSamples = 5,
  });

  final int windowSize;
  final double upgradeThreshold;
  final double downgradeThreshold;
  final int minSamples;

  /// [currentBySkillKey] onaylı seviyeler; yoksa easy varsayılır.
  List<LevelSuggestion> suggestAll({
    required List<ActivityAttempt> attempts,
    required String studentId,
    Map<String, SkillTier> currentBySkillKey = const {},
    Iterable<String> skillKeys = SkillKeys.mvp,
  }) {
    return [
      for (final key in skillKeys)
        suggestForSkill(
          attempts: attempts,
          studentId: studentId,
          skillKey: key,
          currentLevel: currentBySkillKey[key] ?? SkillTier.easy,
        ),
    ];
  }

  LevelSuggestion suggestForSkill({
    required List<ActivityAttempt> attempts,
    required String studentId,
    required String skillKey,
    SkillTier currentLevel = SkillTier.easy,
  }) {
    final relevant = attempts
        .where((a) => a.studentId == studentId)
        .where((a) => SkillKeys.fromCategory(a.category) == skillKey)
        .toList()
      ..sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));

    final window = relevant.take(windowSize).toList();
    if (window.length < minSamples) {
      return LevelSuggestion(
        skillKey: skillKey,
        currentLevel: currentLevel,
        suggestedLevel: currentLevel,
        sampleSize: window.length,
        successRate: window.isEmpty
            ? 0
            : window.where((e) => e.correct).length / window.length,
        reason: 'En az $minSamples deneme gerekli (şu an ${window.length}).',
      );
    }

    final correct = window.where((e) => e.correct).length;
    final rate = correct / window.length;
    var suggested = currentLevel;
    late final String reason;

    if (rate >= upgradeThreshold && currentLevel != SkillTier.hard) {
      suggested = _nextUp(currentLevel);
      reason =
          'Son ${window.length} denemede başarı %${(rate * 100).round()} '
          '(≥ %${(upgradeThreshold * 100).round()}) → üst seviye önerildi.';
    } else if (rate <= downgradeThreshold && currentLevel != SkillTier.easy) {
      suggested = _nextDown(currentLevel);
      reason =
          'Son ${window.length} denemede başarı %${(rate * 100).round()} '
          '(≤ %${(downgradeThreshold * 100).round()}) → alt seviye önerildi.';
    } else {
      reason =
          'Son ${window.length} denemede başarı %${(rate * 100).round()} — '
          'mevcut seviye uygun.';
    }

    return LevelSuggestion(
      skillKey: skillKey,
      currentLevel: currentLevel,
      suggestedLevel: suggested,
      sampleSize: window.length,
      successRate: rate,
      reason: reason,
    );
  }

  static SkillTier _nextUp(SkillTier t) => switch (t) {
        SkillTier.easy => SkillTier.medium,
        SkillTier.medium => SkillTier.hard,
        SkillTier.hard => SkillTier.hard,
      };

  static SkillTier _nextDown(SkillTier t) => switch (t) {
        SkillTier.hard => SkillTier.medium,
        SkillTier.medium => SkillTier.easy,
        SkillTier.easy => SkillTier.easy,
      };
}
