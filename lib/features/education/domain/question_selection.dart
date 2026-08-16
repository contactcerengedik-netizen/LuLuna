import 'dart:math';

import '../../../data/models/education_question.dart';
import 'activity_models.dart';

/// Son N denemede görülen soruları (mümkünse) tekrar gösterme politikası.
/// Mock ve Supabase yolları aynı fonksiyonu kullanır.
abstract final class QuestionSelection {
  static const recentWindow = 10;
  static const minPoolSize = 10;

  /// Aynı kategori + zorluk için en son görülen benzersiz questionId listesi.
  static List<String> recentQuestionIds({
    required List<ActivityAttempt> attempts,
    required String category,
    required String difficulty,
    int window = recentWindow,
  }) {
    final filtered = attempts
        .where((a) => a.category == category && a.difficulty == difficulty)
        .toList()
      ..sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
    final ids = <String>[];
    for (final a in filtered) {
      if (!ids.contains(a.questionId)) ids.add(a.questionId);
      if (ids.length >= window) break;
    }
    return ids;
  }

  /// Havuz [recentIds] uzunluğundan büyükse recent hariç tutulur; değilse tekrar serbest.
  /// Oturum içinde de mümkün olduğunca benzersiz seçilir.
  static List<EducationQuestion> pickWithoutRecent({
    required List<EducationQuestion> pool,
    required List<String> recentIds,
    required int count,
    Random? random,
  }) {
    if (pool.isEmpty) return const [];
    final rng = random ?? Random();
    final allowRepeatFromRecent = pool.length <= recentIds.length;

    List<EducationQuestion> candidates;
    if (allowRepeatFromRecent) {
      candidates = [...pool];
    } else {
      candidates =
          pool.where((q) => !recentIds.contains(q.id)).toList(growable: false);
      if (candidates.isEmpty) candidates = [...pool];
    }

    final shuffled = [...candidates]..shuffle(rng);
    final result = <EducationQuestion>[];
    final used = <String>{};

    for (final q in shuffled) {
      if (result.length >= count) break;
      if (used.add(q.id)) result.add(q);
    }

    // Havuz yetmezse (küçük pool) döngüyle doldur — kabul: en az 8/10 farklı için pool>=10.
    var i = 0;
    while (result.length < count) {
      result.add(shuffled[i % shuffled.length]);
      i++;
    }
    return result;
  }

  /// Üreticiden büyük havuz alıp recent filtresi uygular.
  static List<EducationQuestion> fromGenerator({
    required List<EducationQuestion> Function(int poolSize) buildPool,
    required List<String> recentIds,
    required int count,
    Random? random,
  }) {
    final poolSize = max(minPoolSize, count * 2);
    final raw = buildPool(poolSize);
    // İçerik kimliğine göre tekilleştir (aynı metin farklı index id’si olmasın).
    final unique = <String, EducationQuestion>{};
    for (final q in raw) {
      unique.putIfAbsent(q.id, () => q);
    }
    return pickWithoutRecent(
      pool: unique.values.toList(),
      recentIds: recentIds,
      count: count,
      random: random,
    );
  }
}
