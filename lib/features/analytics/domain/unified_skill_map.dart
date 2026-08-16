import '../../education/domain/activity_models.dart';
import '../domain/analytics_models.dart';

/// v3 §1 — 15 öğrenme alanı (kavram motoru + içerik modülleri).
enum UnifiedLearningArea {
  listening('Dinleme–Anlama'),
  mathematics('Dört İşlem'),
  turkish('Türkçe'),
  tracing('Çizgi / Motor'),
  coloring('Boyama'),
  matching('Eşleştirme'),
  pattern('Örüntü / Mantık'),
  data('Grafik / Veri'),
  memory('Hafıza / Dikkat'),
  speech('Konuşma / Telaffuz'),
  emotion('Duygu / Sosyal'),
  routine('Günlük Yaşam'),
  aac('AAC'),
  puzzle('Puzzle'),
  concept('Kavram Motoru');

  const UnifiedLearningArea(this.label);
  final String label;

  static const allFifteen = UnifiedLearningArea.values;

  /// activity category / skill → birleşik alan.
  static UnifiedLearningArea? fromAttempt({
    required String category,
    required String skill,
  }) {
    return switch (category) {
      'five_w1h' ||
      'concepts' ||
      'antonyms' ||
      'synonyms' ||
      'homophones' ||
      'alphabetical' ||
      'word_ordering' ||
      'event_ordering' =>
        turkish,
      'number_recognition' ||
      'addition' ||
      'subtraction' ||
      'multiplication' ||
      'division' ||
      'fractions' ||
      'word_problems' ||
      'learn_numbers' ||
      'learn_digits' ||
      'fill_blank' ||
      'rhythmic_counting' ||
      'number_ordering' =>
        mathematics,
      'chart_reading' || 'table_reading' || 'tally' || 'dataRead' => data,
      'patternComplete' || 'oddOne' || 'eventOrder' => pattern,
      'straightLine' ||
      'wavyLine' ||
      'shape' ||
      'digit' ||
      'uppercaseLetter' ||
      'lowercaseLetter' ||
      'word' ||
      'freeDraw' ||
      'connectDots' ||
      'lineFollow' ||
      'letter' ||
      'pattern' =>
        tracing,
      'coloring' => coloring,
      'categorization' => matching,
      'match' || 'flash' => memory,
      'pronunciation' || 'communication' => speech,
      'emotion' => emotion,
      'routine' => routine,
      'aac' => aac,
      'puzzle' => puzzle,
      'listening' || 'language_comprehension' => listening,
      _ => switch (skill) {
          'mathematics' => mathematics,
          'language' => turkish,
          'puzzle' => puzzle,
          'tracing' => tracing,
          'coloring' => coloring,
          'visualPerception' => matching,
          'communication' => speech,
          'dailyLife' => routine,
          _ => null,
        },
    };
  }
}

class UnifiedAreaScore {
  const UnifiedAreaScore({
    required this.area,
    required this.correct,
    required this.wrong,
  });

  final UnifiedLearningArea area;
  final int correct;
  final int wrong;

  int get total => correct + wrong;
  double get successRate => total == 0 ? 0 : correct / total;
  bool get hasData => total > 0;
}

/// 15 alanın tamamını doldurur (veri yoksa 0).
abstract final class UnifiedAnalyticsBuilder {
  static List<UnifiedAreaScore> build(List<ActivityAttempt> attempts) {
    final map = {
      for (final a in UnifiedLearningArea.allFifteen)
        a: (correct: 0, wrong: 0),
    };
    for (final attempt in attempts) {
      final area = UnifiedLearningArea.fromAttempt(
        category: attempt.category,
        skill: attempt.skill,
      );
      if (area == null) continue;
      final cur = map[area]!;
      map[area] = attempt.correct
          ? (correct: cur.correct + 1, wrong: cur.wrong)
          : (correct: cur.correct, wrong: cur.wrong + 1);
    }
    return [
      for (final a in UnifiedLearningArea.allFifteen)
        UnifiedAreaScore(
          area: a,
          correct: map[a]!.correct,
          wrong: map[a]!.wrong,
        ),
    ];
  }

  static CategoryPerformance toCategoryPerformance(UnifiedAreaScore s) {
    return CategoryPerformance(
      categoryId: s.area.name,
      label: s.area.label,
      correct: s.correct,
      wrong: s.wrong,
    );
  }
}
