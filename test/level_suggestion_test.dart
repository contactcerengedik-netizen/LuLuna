import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luluna/data/models/skill_keys.dart';
import 'package:luluna/data/models/skill_level.dart';
import 'package:luluna/features/education/data/student_skill_level_repository.dart';
import 'package:luluna/features/education/domain/activity_models.dart';
import 'package:luluna/features/education/domain/level_suggestion.dart';
import 'package:luluna/features/mathematics/data/math_categories.dart';
import 'package:luluna/features/mathematics/data/math_question_generator.dart';
import 'package:luluna/features/language/data/language_categories.dart';
import 'package:luluna/features/language/data/language_question_generator.dart';
import 'package:luluna/features/education/domain/activity_engine.dart';

void main() {
  group('SkillKeys', () {
    test('kategori eşlemesi', () {
      expect(SkillKeys.fromCategory('addition'), SkillKeys.addition);
      expect(SkillKeys.fromCategory('five_w1h'), SkillKeys.fiveW1h);
      expect(SkillKeys.fromCategory('antonyms'), SkillKeys.antonyms);
    });
  });

  group('LevelSuggestionEngine', () {
    const engine = LevelSuggestionEngine(minSamples: 5, windowSize: 10);

    ActivityAttempt attempt({
      required bool correct,
      required String category,
      int minutesAgo = 0,
    }) {
      return ActivityAttempt(
        id: 'a-$minutesAgo-$correct',
        studentId: 's1',
        skill: 'mathematics',
        category: category,
        difficulty: 'easy',
        questionId: 'q',
        givenAnswer: '1',
        correct: correct,
        attemptedAt: DateTime.now().subtract(Duration(minutes: minutesAgo)),
      );
    }

    test('yetersiz örnek → seviye değişmez', () {
      final attempts = [
        for (var i = 0; i < 3; i++)
          attempt(correct: true, category: 'addition', minutesAgo: i),
      ];
      final s = engine.suggestForSkill(
        attempts: attempts,
        studentId: 's1',
        skillKey: SkillKeys.addition,
        currentLevel: SkillTier.easy,
      );
      expect(s.suggestedLevel, SkillTier.easy);
      expect(s.differsFromCurrent, isFalse);
    });

    test('yüksek başarı → üst seviye önerir', () {
      final attempts = [
        for (var i = 0; i < 10; i++)
          attempt(correct: true, category: 'addition', minutesAgo: i),
      ];
      final s = engine.suggestForSkill(
        attempts: attempts,
        studentId: 's1',
        skillKey: SkillKeys.addition,
        currentLevel: SkillTier.easy,
      );
      expect(s.suggestedLevel, SkillTier.medium);
      expect(s.differsFromCurrent, isTrue);
      expect(s.successRate, 1.0);
    });

    test('düşük başarı → alt seviye önerir', () {
      final attempts = [
        for (var i = 0; i < 10; i++)
          attempt(correct: false, category: 'addition', minutesAgo: i),
      ];
      final s = engine.suggestForSkill(
        attempts: attempts,
        studentId: 's1',
        skillKey: SkillKeys.addition,
        currentLevel: SkillTier.medium,
      );
      expect(s.suggestedLevel, SkillTier.easy);
    });
  });

  group('StudentSkillLevelRepository', () {
    test('öğretmen seviyesi kaydeder', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = StudentSkillLevelRepository(prefs);
      await repo.setTeacherLevel(
        studentId: 's1',
        skillKey: SkillKeys.addition,
        tier: SkillTier.hard,
      );
      expect(repo.tierFor('s1', SkillKeys.addition), SkillTier.hard);
      expect(
        repo.forStudent('s1').single.source,
        SkillLevelSource.teacherSet,
      );
    });
  });

  group('MVP generators', () {
    test('matematik MVP kategorileri', () {
      expect(MathCategories.mvp.map((e) => e.id), [
        'number_recognition',
        'addition',
        'subtraction',
        'multiplication',
        'division',
        'fractions',
      ]);
      final gen = MathQuestionGenerator();
      for (final c in MathCategories.mvp) {
        final qs = gen.generate(
          category: c.id,
          difficulty: SkillTier.easy,
          count: 2,
        );
        expect(qs, hasLength(2));
        expect(qs.first.isCorrect(qs.first.correctAnswer), isTrue);
      }
    });

    test('toplama medium metadata a/b', () {
      final q = MathQuestionGenerator()
          .generate(
            category: 'addition',
            difficulty: SkillTier.medium,
            count: 1,
          )
          .single;
      final a = q.metadata['a'] as int;
      final b = q.metadata['b'] as int;
      expect(q.isCorrect('${a + b}'), isTrue);
    });

    test('türkçe MVP kategorileri', () {
      expect(LanguageCategories.mvp.map((e) => e.id), [
        'five_w1h',
        'concepts',
        'antonyms',
        'synonyms',
        'homophones',
        'alphabetical',
        'word_ordering',
      ]);
      final gen = LanguageQuestionGenerator();
      for (final c in LanguageCategories.mvp) {
        final qs = gen.generate(
          category: c.id,
          difficulty: SkillTier.easy,
          count: 1,
        );
        expect(qs.single.isCorrect(qs.single.correctAnswer), isTrue);
      }
    });
  });

  group('ActivityEngine scoring', () {
    test('oturum skoru', () {
      final qs = MathQuestionGenerator().generate(
        category: 'addition',
        difficulty: SkillTier.easy,
        count: 2,
      );
      final engine = ActivityEngine(studentId: 's1', questions: qs);
      for (final q in qs) {
        final a = q.metadata['a'] as int;
        final b = q.metadata['b'] as int;
        engine.submit('${a + b}');
      }
      final result = engine.result();
      expect(result.correctCount, 2);
      expect(result.scorePercent, 100);
    });
  });
}
