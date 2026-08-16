import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:luluna/core/canvas/canvas_engine.dart';
import 'package:luluna/data/models/categorization_question.dart';
import 'package:luluna/data/models/skill_level.dart';
import 'package:luluna/features/categorization/data/categorization_catalog.dart';

void main() {
  group('CanvasEngine', () {
    test('stroke + undo + redo', () {
      final engine = CanvasEngine();
      engine.beginStroke(
        point: const Offset(10, 10),
        color: Colors.red,
        width: 12,
      );
      engine.appendPoint(const Offset(20, 20));
      expect(engine.strokes, hasLength(1));
      expect(engine.strokes.first.points, hasLength(2));
      expect(engine.undo(), isTrue);
      expect(engine.strokes, isEmpty);
      expect(engine.redo(), isTrue);
      expect(engine.strokes, hasLength(1));
    });

    test('clip mask sample path boş değil', () {
      final path = CanvasPalette.sampleClipMask(const Size(200, 200));
      expect(path.computeMetrics().isEmpty, isFalse);
    });
  });

  group('CategorizationQuestion', () {
    test('isCorrect / score', () {
      final q = CategorizationCatalog.forTier(SkillTier.easy);
      expect(q.isCorrect(q.correctMapping), isTrue);
      expect(q.score(q.correctMapping), q.items.length);
      final wrong = Map<String, String>.from(q.correctMapping);
      wrong[wrong.keys.first] = '??';
      expect(q.isCorrect(wrong), isFalse);
    });

    test('easy görsel, hard kavramsal', () {
      final easy = CategorizationCatalog.forTier(SkillTier.easy);
      final hard = CategorizationCatalog.forTier(SkillTier.hard);
      expect(easy.level, 'easy');
      expect(hard.level, 'hard');
      expect(hard.categories, contains('Yenebilir'));
    });

    test('toMap / fromMap roundtrip', () {
      final q = CategorizationCatalog.forTier(SkillTier.medium);
      final again = CategorizationQuestion.fromMap(q.toMap());
      expect(again.id, q.id);
      expect(again.isCorrect(q.correctMapping), isTrue);
    });
  });
}
