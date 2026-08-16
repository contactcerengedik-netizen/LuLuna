import 'package:flutter_test/flutter_test.dart';

import 'package:luluna/data/models/skill_keys.dart';
import 'package:luluna/data/models/skill_level.dart';
import 'package:luluna/features/mathematics/data/math_categories.dart';
import 'package:luluna/features/mathematics/data/math_question_generator.dart';

void main() {
  group('Math Faz 10', () {
    final gen = MathQuestionGenerator(random: null);

    test('hub dört işlem + kesir', () {
      expect(
        MathCategories.mvp.map((e) => e.id),
        containsAll([
          'addition',
          'subtraction',
          'multiplication',
          'division',
          'fractions',
        ]),
      );
    });

    test('çarpma / bölme / kesir üretir ve operationType set', () {
      for (final entry in {
        'multiplication': 'multiply',
        'division': 'divide',
        'fractions': 'fraction_basic',
      }.entries) {
        for (final tier in SkillTier.values) {
          final qs = gen.generate(
            category: entry.key,
            difficulty: tier,
            count: 2,
          );
          expect(qs, hasLength(2), reason: '${entry.key}/${tier.name}');
          expect(qs.first.metadata['operationType'], entry.value);
          expect(qs.first.isCorrect(qs.first.correctAnswer), isTrue);
        }
      }
    });

    test('çarpma easy a*b doğrulanır', () {
      final q = gen
          .generate(
            category: 'multiplication',
            difficulty: SkillTier.easy,
            count: 1,
          )
          .single;
      final a = q.metadata['a'] as int;
      final b = q.metadata['b'] as int;
      expect(q.isCorrect('${a * b}'), isTrue);
      expect(q.isCorrect('${a * b + 1}'), isFalse);
    });

    test('bölme kalanlı değil', () {
      final q = gen
          .generate(
            category: 'division',
            difficulty: SkillTier.medium,
            count: 1,
          )
          .single;
      final a = q.metadata['a'] as int;
      final b = q.metadata['b'] as int;
      expect(a % b, 0);
      expect(q.isCorrect('${a ~/ b}'), isTrue);
    });

    test('skill_key eşlemesi', () {
      expect(SkillKeys.fromCategory('multiplication'), SkillKeys.multiplication);
      expect(SkillKeys.fromCategory('division'), SkillKeys.division);
      expect(SkillKeys.fromCategory('fractions'), SkillKeys.fractions);
    });
  });
}
