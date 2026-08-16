import 'package:flutter_test/flutter_test.dart';

import 'package:luluna/data/models/sequence_question.dart';
import 'package:luluna/data/models/skill_level.dart';
import 'package:luluna/features/language/data/language_categories.dart';
import 'package:luluna/features/language/data/language_question_generator.dart';

void main() {
  group('SequenceQuestion', () {
    test('shuffled + isCorrectSequence', () {
      final seq = SequenceQuestion.shuffled(
        const ['Ali', 'okula', 'gitti'],
        random: null,
      );
      expect(seq.items, hasLength(3));
      expect(seq.isCorrectSequence(seq.correctItems), isTrue);
      expect(seq.isCorrectSequence(seq.items), seq.items == seq.correctItems);
      final encoded = SequenceQuestion.encode(seq.correctItems);
      expect(
        seq.isCorrectSequence(SequenceQuestion.decode(encoded)),
        isTrue,
      );
    });
  });

  group('Language Faz 9', () {
    final gen = LanguageQuestionGenerator(random: null);

    test('hub kategorileri', () {
      expect(
        LanguageCategories.mvp.map((e) => e.id),
        containsAll([
          'five_w1h',
          'concepts',
          'antonyms',
          'synonyms',
          'homophones',
          'alphabetical',
          'word_ordering',
        ]),
      );
    });

    test('kavram / eşses / sıralama üretir', () {
      for (final id in [
        'concepts',
        'homophones',
        'synonyms',
        'antonyms',
        'word_ordering',
        'alphabetical',
      ]) {
        for (final tier in SkillTier.values) {
          final qs = gen.generate(category: id, difficulty: tier, count: 2);
          expect(qs, hasLength(2), reason: '$id/$tier');
          expect(qs.first.isCorrect(qs.first.correctAnswer), isTrue);
        }
      }
    });

    test('word_ordering sequence metadata', () {
      final q = gen
          .generate(
            category: 'word_ordering',
            difficulty: SkillTier.medium,
            count: 1,
          )
          .single;
      expect(q.metadata['type'], 'sequence');
      final seq = SequenceQuestion.fromMap(q.metadata);
      expect(seq.isCorrectSequence(seq.correctItems), isTrue);
      expect(q.isCorrect(q.correctAnswer), isTrue);
    });
  });
}
