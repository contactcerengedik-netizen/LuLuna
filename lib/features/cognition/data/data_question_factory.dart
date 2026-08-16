import '../../../data/models/data_question.dart';
import '../../../data/models/skill_level.dart';
import '../../education/domain/activity_models.dart';

/// DataQuestion üretici — mümkünse gerçek attempt özeti kullanır.
abstract final class DataQuestionFactory {
  /// Öğrenci denemelerinden skill bazlı sayım; yetersizse örnek veri.
  static DataQuestion build({
    required SkillTier tier,
    List<ActivityAttempt> attempts = const [],
    int index = 0,
  }) {
    final fromReal = _fromAttempts(attempts, tier, index);
    if (fromReal != null) return fromReal;
    return _samples(tier)[index % _samples(tier).length];
  }

  static DataQuestion? _fromAttempts(
    List<ActivityAttempt> attempts,
    SkillTier tier,
    int index,
  ) {
    if (attempts.length < 3) return null;
    final counts = <String, int>{};
    for (final a in attempts) {
      final key = _labelSkill(a.skill);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    if (counts.length < 2) return null;

    // En fazla 4 etiket
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final dataset = {
      for (final e in entries.take(4)) e.key: e.value,
    };
    final display = switch (tier) {
      SkillTier.easy => DataDisplayAs.tally,
      SkillTier.medium => DataDisplayAs.table,
      SkillTier.hard => DataDisplayAs.barChart,
    };
    return _questionFromDataset(
      id: 'data-live-$index',
      dataset: dataset,
      displayAs: display,
      tier: tier,
      fromAttempts: true,
      index: index,
    );
  }

  static String _labelSkill(String skill) {
    const map = {
      'mathematics': 'Matematik',
      'language': 'Türkçe',
      'puzzle': 'Puzzle',
      'tracing': 'Çizgi',
      'coloring': 'Boyama',
      'visualPerception': 'Eşleştirme',
    };
    return map[skill] ?? skill;
  }

  static DataQuestion _questionFromDataset({
    required String id,
    required Map<String, int> dataset,
    required DataDisplayAs displayAs,
    required SkillTier tier,
    required bool fromAttempts,
    required int index,
  }) {
    final entries = dataset.entries.toList();
    final maxE = entries.reduce((a, b) => a.value >= b.value ? a : b);
    final minE = entries.reduce((a, b) => a.value <= b.value ? a : b);
    final diff = maxE.value - minE.value;

    final type = switch ((tier, index % 3)) {
      (SkillTier.easy, _) => DataQuestionType.max,
      (SkillTier.medium, 0) => DataQuestionType.max,
      (SkillTier.medium, _) => DataQuestionType.min,
      (SkillTier.hard, 0) => DataQuestionType.difference,
      (SkillTier.hard, _) => DataQuestionType.count,
    };

    return switch (type) {
      DataQuestionType.max => DataQuestion(
          id: id,
          instruction: 'Veriye bak.',
          dataset: dataset,
          displayAs: displayAs,
          questionType: type,
          questionText: 'En çok hangisi?',
          choices: dataset.keys.toList(),
          correctAnswer: maxE.key,
          fromAttempts: fromAttempts,
        ),
      DataQuestionType.min => DataQuestion(
          id: '$id-min',
          instruction: 'Veriye bak.',
          dataset: dataset,
          displayAs: displayAs,
          questionType: type,
          questionText: 'En az hangisi?',
          choices: dataset.keys.toList(),
          correctAnswer: minE.key,
          fromAttempts: fromAttempts,
        ),
      DataQuestionType.difference => DataQuestion(
          id: '$id-diff',
          instruction: 'Veriye bak.',
          dataset: dataset,
          displayAs: displayAs,
          questionType: type,
          questionText:
              '${maxE.key} ile ${minE.key} arasında kaç fark var?',
          choices: _around(diff),
          correctAnswer: '$diff',
          fromAttempts: fromAttempts,
        ),
      DataQuestionType.count => DataQuestion(
          id: '$id-count',
          instruction: 'Veriye bak.',
          dataset: dataset,
          displayAs: displayAs,
          questionType: type,
          questionText: '${maxE.key} kaç tane?',
          choices: _around(maxE.value),
          correctAnswer: '${maxE.value}',
          fromAttempts: fromAttempts,
        ),
    };
  }

  static List<String> _around(int n) {
    final set = <int>{n, n + 1, (n - 1).clamp(0, 999), n + 2};
    return set.map((e) => '$e').toList();
  }

  static List<DataQuestion> _samples(SkillTier tier) {
    const fruit = {'Elma': 5, 'Armut': 3, 'Muz': 7, 'Üzüm': 2};
    final display = switch (tier) {
      SkillTier.easy => DataDisplayAs.tally,
      SkillTier.medium => DataDisplayAs.table,
      SkillTier.hard => DataDisplayAs.barChart,
    };
    return [
      _questionFromDataset(
        id: 'data-sample-${tier.name}',
        dataset: fruit,
        displayAs: display,
        tier: tier,
        fromAttempts: false,
        index: 0,
      ),
      _questionFromDataset(
        id: 'data-sample-${tier.name}-b',
        dataset: const {'Ayşe': 4, 'Mehmet': 6, 'Zeynep': 2},
        displayAs: display,
        tier: tier,
        fromAttempts: false,
        index: 1,
      ),
    ];
  }
}
