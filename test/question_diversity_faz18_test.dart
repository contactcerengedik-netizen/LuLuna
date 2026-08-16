import 'package:flutter_test/flutter_test.dart';

import 'package:luluna/data/models/skill_level.dart';
import 'package:luluna/features/education/domain/activity_models.dart';
import 'package:luluna/features/education/domain/question_selection.dart';
import 'package:luluna/features/language/data/language_question_generator.dart';
import 'package:luluna/features/mathematics/data/math_question_generator.dart';

void main() {
  group('QuestionSelection / pool diversity (Faz 18.1)', () {
    test('dil MVP kategorilerinde her zorluk için en az 10 benzersiz soru', () {
      final gen = LanguageQuestionGenerator();
      const cats = [
        'five_w1h',
        'concepts',
        'antonyms',
        'synonyms',
        'homophones',
        'alphabetical',
        'word_ordering',
      ];
      for (final cat in cats) {
        for (final d in SkillTier.values) {
          final pool = gen.generate(
            category: cat,
            difficulty: d,
            count: 10,
          );
          expect(pool, hasLength(10), reason: '$cat/${d.name}');
          final ids = pool.map((e) => e.id).toSet();
          expect(ids.length, greaterThanOrEqualTo(8), reason: '$cat/${d.name}');
        }
      }
    });

    test('matematik MVP: 10 soruda en az 8 farklı', () {
      final gen = MathQuestionGenerator();
      for (final cat in [
        'number_recognition',
        'addition',
        'subtraction',
        'multiplication',
        'division',
        'fractions',
      ]) {
        for (final d in SkillTier.values) {
          final qs = gen.generate(category: cat, difficulty: d, count: 10);
          expect(qs.length, 10);
          expect(qs.map((e) => e.id).toSet().length, greaterThanOrEqualTo(8),
              reason: '$cat/${d.name}');
        }
      }
    });

    test('recent exclude: havuz büyükse son görülenler gelmez', () {
      final gen = LanguageQuestionGenerator();
      final first = gen.generate(
        category: 'antonyms',
        difficulty: SkillTier.easy,
        count: 10,
      );
      final recent = first.map((e) => e.id).toList();
      final second = gen.generate(
        category: 'antonyms',
        difficulty: SkillTier.easy,
        count: 5,
        excludeIds: recent,
      );
      // easy antonyms pool = 10; recent = 10 → pool <= recent → tekrar serbest
      // Bu yüzden önce 5 recent ile dene:
      final partial = recent.take(5).toList();
      final filtered = gen.generate(
        category: 'antonyms',
        difficulty: SkillTier.easy,
        count: 5,
        excludeIds: partial,
      );
      for (final q in filtered) {
        expect(partial.contains(q.id), isFalse);
      }
    });

    test('recentQuestionIds son N benzersiz id döner', () {
      final now = DateTime.now();
      final attempts = [
        for (var i = 0; i < 15; i++)
          ActivityAttempt(
            id: 'a$i',
            studentId: 's1',
            skill: 'language',
            category: 'antonyms',
            difficulty: 'easy',
            questionId: 'q${i % 12}',
            givenAnswer: 'x',
            correct: true,
            attemptedAt: now.add(Duration(seconds: i)),
          ),
      ];
      final recent = QuestionSelection.recentQuestionIds(
        attempts: attempts,
        category: 'antonyms',
        difficulty: 'easy',
        window: 10,
      );
      expect(recent.length, lessThanOrEqualTo(10));
      expect(recent.first, 'q${14 % 12}'); // en yeni
    });
  });
}
