import 'package:flutter_test/flutter_test.dart';

import 'package:luluna/data/models/data_question.dart';
import 'package:luluna/data/models/pattern_question.dart';
import 'package:luluna/data/models/skill_level.dart';
import 'package:luluna/features/cognition/data/data_question_factory.dart';
import 'package:luluna/features/cognition/data/pattern_catalog.dart';
import 'package:luluna/features/education/domain/activity_models.dart';

void main() {
  group('PatternQuestion', () {
    test('complete missing token', () {
      final q = PatternCatalog.patternFor(SkillTier.easy);
      expect(q.displayPattern.contains('?'), isTrue);
      expect(q.isCorrect(q.correctAnswer), isTrue);
      expect(q.isCorrect('___'), isFalse);
    });

    test('odd one out', () {
      final q = PatternCatalog.oddOneOut();
      expect(q.kind, PatternKind.oddOneOut);
      expect(q.isCorrect(q.correctAnswer), isTrue);
    });

    test('event order sequence', () {
      final seq = PatternCatalog.eventOrder();
      expect(seq.isCorrectSequence(seq.correctItems), isTrue);
      expect(seq.isCorrectSequence(seq.items), seq.items == seq.correctItems);
    });

    test('toMap roundtrip', () {
      final q = PatternCatalog.patternFor(SkillTier.hard);
      final again = PatternQuestion.fromMap(q.toMap());
      expect(again.id, q.id);
      expect(again.correctAnswer, q.correctAnswer);
    });
  });

  group('DataQuestion', () {
    test('sample max question', () {
      final q = DataQuestionFactory.build(tier: SkillTier.easy);
      expect(q.dataset, isNotEmpty);
      expect(q.isCorrect(q.correctAnswer), isTrue);
      expect(q.displayAs, DataDisplayAs.tally);
    });

    test('hard uses bar chart', () {
      final q = DataQuestionFactory.build(tier: SkillTier.hard);
      expect(q.displayAs, DataDisplayAs.barChart);
    });

    test('attempts özetinden üretir', () {
      final now = DateTime.now();
      final attempts = [
        for (var i = 0; i < 3; i++)
          ActivityAttempt(
            id: 'a$i',
            studentId: 's1',
            skill: 'mathematics',
            category: 'addition',
            difficulty: 'easy',
            questionId: 'q$i',
            givenAnswer: '1',
            correct: true,
            attemptedAt: now,
          ),
        for (var i = 0; i < 5; i++)
          ActivityAttempt(
            id: 'b$i',
            studentId: 's1',
            skill: 'language',
            category: 'antonyms',
            difficulty: 'easy',
            questionId: 'q$i',
            givenAnswer: '1',
            correct: true,
            attemptedAt: now,
          ),
      ];
      final q = DataQuestionFactory.build(
        tier: SkillTier.medium,
        attempts: attempts,
      );
      expect(q.fromAttempts, isTrue);
      expect(q.dataset.containsKey('Türkçe'), isTrue);
      expect(q.correctAnswer, 'Türkçe');
    });

    test('toMap roundtrip', () {
      final q = DataQuestionFactory.build(tier: SkillTier.medium, index: 1);
      final again = DataQuestion.fromMap(q.toMap());
      expect(again.id, q.id);
      expect(again.dataset, q.dataset);
    });
  });
}
