import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luluna/data/models/skill_level.dart';
import 'package:luluna/features/education/data/activity_attempt_repository.dart';
import 'package:luluna/features/education/domain/activity_engine.dart';
import 'package:luluna/features/language/data/language_question_generator.dart';
import 'package:luluna/features/mathematics/data/math_categories.dart';
import 'package:luluna/features/mathematics/data/math_question_generator.dart';
import 'package:luluna/features/language/data/language_categories.dart';

void main() {
  group('MathQuestionGenerator', () {
    final gen = MathQuestionGenerator();

    test('tüm kategoriler soru üretir', () {
      for (final c in MathCategories.all) {
        for (final tier in SkillTier.values) {
          final qs = gen.generate(category: c.id, difficulty: tier, count: 3);
          expect(qs, hasLength(3), reason: '${c.id}/${tier.name}');
          expect(qs.first.skill, SkillArea.mathematics);
          expect(qs.first.category, c.id);
        }
      }
    });

    test('toplama cevabı doğru', () {
      final qs = gen.generate(
        category: 'addition',
        difficulty: SkillTier.easy,
        count: 1,
      );
      final q = qs.single;
      final a = q.metadata['a'] as int;
      final b = q.metadata['b'] as int;
      expect(q.isCorrect('${a + b}'), isTrue);
      expect(q.isCorrect('${a + b + 1}'), isFalse);
    });
  });

  group('LanguageQuestionGenerator', () {
    final gen = LanguageQuestionGenerator();

    test('tüm kategoriler soru üretir', () {
      for (final c in LanguageCategories.all) {
        for (final tier in SkillTier.values) {
          final qs = gen.generate(category: c.id, difficulty: tier, count: 2);
          expect(qs, hasLength(2), reason: '${c.id}/${tier.name}');
        }
      }
    });

    test('zıt kavram easy doğru', () {
      final qs = gen.generate(
        category: 'antonyms',
        difficulty: SkillTier.easy,
        count: 1,
      );
      expect(qs.single.isCorrect(qs.single.correctAnswer), isTrue);
    });
  });

  group('ActivityEngine', () {
    test('doğru cevap ilerletir, yanlışta kalır', () {
      final gen = MathQuestionGenerator();
      final qs = gen.generate(
        category: 'addition',
        difficulty: SkillTier.easy,
        count: 2,
      );
      final engine = ActivityEngine(studentId: 's1', questions: qs);
      final q0 = engine.current;
      final wrong = engine.submit('99999');
      expect(wrong.correct, isFalse);
      expect(engine.index, 0);
      final a = q0.metadata['a'] as int;
      final b = q0.metadata['b'] as int;
      final ok = engine.submit('${a + b}');
      expect(ok.correct, isTrue);
      expect(engine.index, 1);
    });
  });

  group('ActivityAttemptRepository', () {
    test('append ve yükle', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = ActivityAttemptRepository(prefs);
      final gen = MathQuestionGenerator();
      final q = gen
          .generate(
            category: 'addition',
            difficulty: SkillTier.easy,
            count: 1,
          )
          .single;
      final engine = ActivityEngine(studentId: 'stu', questions: [q]);
      final a = q.metadata['a'] as int;
      final b = q.metadata['b'] as int;
      final eval = engine.submit('${a + b}');
      await repo.append(eval.attempt);
      expect(repo.forStudent('stu'), hasLength(1));
      expect(repo.forStudent('stu').first.correct, isTrue);
    });
  });
}
