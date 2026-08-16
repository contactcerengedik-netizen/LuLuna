import 'package:flutter_test/flutter_test.dart';

import 'package:luluna/data/models/skill_level.dart';
import 'package:luluna/features/language/data/language_question_generator.dart';
import 'package:luluna/features/mathematics/data/math_question_generator.dart';

void main() {
  group('Soru görselleri ve çeşitlilik', () {
    final math = MathQuestionGenerator(random: null);
    final lang = LanguageQuestionGenerator(random: null);

    test('her seviyede 10 toplama sorusu, farklı hikâye şablonları', () {
      for (final tier in SkillTier.values) {
        final qs = math.generate(
          category: 'addition',
          difficulty: tier,
          count: 10,
        );
        expect(qs, hasLength(10), reason: 'addition/$tier');
        final templates = <String>{};
        for (final q in qs) {
          final scene = q.metadata['sceneVisual'] as Map?;
          expect(scene, isNotNull, reason: q.id);
          expect(scene!['template'], isNot(equals('abstract_dots')));
          templates.add('${scene['template']}');
        }
        expect(
          templates.length,
          greaterThanOrEqualTo(5),
          reason: 'addition/$tier çeşitlilik',
        );
        expect(
          qs.map((q) => q.questionText).toSet(),
          hasLength(10),
          reason: 'addition/$tier benzersiz metin',
        );
      }
    });

    test('çıkarma sorularında da sahne görseli var', () {
      final qs = math.generate(
        category: 'subtraction',
        difficulty: SkillTier.medium,
        count: 10,
      );
      expect(qs, hasLength(10));
      for (final q in qs) {
        expect(q.metadata['sceneVisual'], isA<Map>());
      }
    });

    test('5N1K görselli kart sırası — seviye başı 10', () {
      for (final tier in SkillTier.values) {
        final qs = lang.generate(
          category: 'five_w1h',
          difficulty: tier,
          count: 10,
        );
        expect(qs, hasLength(10), reason: '5n1k/$tier');
        for (final q in qs) {
          expect(q.metadata['type'], 'sequence');
          expect(q.metadata['visualCards'], isTrue);
          expect(q.metadata['cardIcons'], isA<Map>());
          expect(q.metadata['sceneVisual'], isA<Map>());
          final cards = (q.metadata['items'] as List?)?.length ?? 0;
          final expected = switch (tier) {
            SkillTier.easy => 3,
            SkillTier.medium => 4,
            SkillTier.hard => 5,
          };
          expect(cards, expected, reason: q.id);
        }
      }
    });

    test('olay/kelime sıralama görselli kart', () {
      for (final cat in ['event_ordering', 'word_ordering']) {
        final qs = lang.generate(
          category: cat,
          difficulty: SkillTier.easy,
          count: 10,
        );
        expect(qs, hasLength(10), reason: cat);
        expect(qs.every((q) => q.metadata['visualCards'] == true), isTrue);
        expect(qs.every((q) => q.metadata['cardIcons'] is Map), isTrue);
      }
    });
  });
}
