import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:luluna/core/canvas/canvas_engine.dart';
import 'package:luluna/features/puzzle/domain/puzzle_board.dart';
import 'package:luluna/features/tracing/domain/tracing_analyzer.dart';

void main() {
  group('PuzzleBoard', () {
    test('layout 3/5/10', () {
      expect(PuzzleBoard.layoutFor(3), (1, 3));
      expect(PuzzleBoard.layoutFor(5), (1, 5));
      expect(PuzzleBoard.layoutFor(10), (2, 5));
    });

    test('doğru yere snap ile tamamlanır', () {
      final board = PuzzleBoard.forPieceCount(3, random: null);
      // Deterministic: place each piece in correct slot from tray copy
      final tray = [...board.tray];
      for (final id in tray) {
        expect(board.place(id, id), isTrue);
      }
      expect(board.isComplete, isTrue);
    });

    test('yanlış slot complete etmez', () {
      final board = PuzzleBoard(
        pieceCount: 3,
        rows: 1,
        cols: 3,
        slotOrder: const [0, 1, 2],
      );
      board.place(0, 1);
      expect(board.isComplete, isFalse);
      expect(board.slots[1], 0);
    });

    test('nearestSlot hücre içinde index döner', () {
      final board = PuzzleBoard.forPieceCount(3);
      final size = const Size(300, 100);
      expect(board.nearestSlot(const Offset(50, 50), size), 0);
      expect(board.nearestSlot(const Offset(150, 50), size), 1);
      expect(board.nearestSlot(const Offset(250, 50), size), 2);
    });
  });

  group('TracingPathAnalyzer', () {
    test('kılavuza yakın stroke tamamlar', () {
      const analyzer = TracingPathAnalyzer(tolerance: 20);
      final guide = [
        for (var i = 0; i <= 10; i++) Offset(i * 10.0, 50),
      ];
      final stroke = [
        for (var i = 0; i <= 10; i++) Offset(i * 10.0, 52),
      ];
      final r = analyzer.analyze(guide: guide, stroke: stroke);
      expect(r.completed, isTrue);
      expect(r.coverage, greaterThan(0.9));
    });

    test('uzak stroke tamamlamaz', () {
      const analyzer = TracingPathAnalyzer(tolerance: 15);
      final guide = [const Offset(0, 0), const Offset(100, 0)];
      final stroke = [const Offset(0, 80), const Offset(100, 80)];
      final r = analyzer.analyze(guide: guide, stroke: stroke);
      expect(r.completed, isFalse);
    });
  });

  group('CanvasEngine', () {
    test('undo clear stroke', () {
      final doc = CanvasEngine();
      doc.beginStroke(
        point: const Offset(1, 1),
        color: const Color(0xFFFF0000),
        width: 20,
        erase: false,
      );
      doc.appendPoint(const Offset(2, 2));
      expect(doc.strokes, hasLength(1));
      expect(doc.undo(), isTrue);
      expect(doc.strokes, isEmpty);
      expect(doc.redo(), isTrue);
      expect(doc.strokes, hasLength(1));
      doc.clear();
      expect(doc.strokes, isEmpty);
    });
  });
}
