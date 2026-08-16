import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luluna/features/education/data/activity_attempt_repository.dart';
import 'package:luluna/features/education/domain/activity_models.dart';
import 'package:luluna/features/puzzle/domain/puzzle_board.dart';
import 'package:luluna/features/puzzle/domain/puzzle_image_splitter.dart';

void main() {
  group('PuzzleImageSplitter', () {
    test('3 parça 1×3 dilimleri', () {
      final slices = PuzzleImageSplitter.split(
        rows: 1,
        cols: 3,
        pieceCount: 3,
      );
      expect(slices, hasLength(3));
      expect(slices[0].srcRect, const Rect.fromLTWH(0, 0, 1 / 3, 1));
      expect(slices[2].col, 2);
      final px = PuzzleImageSplitter.toSourcePixels(
        slices[1].srcRect,
        const Size(300, 100),
      );
      expect(px.left, closeTo(100, 0.01));
      expect(px.width, closeTo(100, 0.01));
    });

    test('10 parça 2×5', () {
      final slices = PuzzleImageSplitter.split(
        rows: 2,
        cols: 5,
        pieceCount: 10,
      );
      expect(slices, hasLength(10));
      expect(slices[5].row, 1);
      expect(slices[5].col, 0);
    });
  });

  group('PuzzleBoard', () {
    test('layoutFor MVP ve 10', () {
      expect(PuzzleBoard.layoutFor(3), (1, 3));
      expect(PuzzleBoard.layoutFor(5), (1, 5));
      expect(PuzzleBoard.layoutFor(10), (2, 5));
    });

    test('yalnızca doğru slot snap', () {
      final board = PuzzleBoard.forPieceCount(3, random: null);
      // Tray karışık olabilir; parça 0 yanlış slota.
      final wrong = board.placeCorrectOnly(0, 1);
      expect(wrong, PuzzlePlaceResult.rejected);
      expect(board.slots.every((e) => e == null), isTrue);

      expect(board.placeCorrectOnly(0, 0), PuzzlePlaceResult.snapped);
      expect(board.slots[0], 0);
      expect(board.placeCorrectOnly(1, 1), PuzzlePlaceResult.snapped);
      expect(board.placeCorrectOnly(2, 2), PuzzlePlaceResult.snapped);
      expect(board.isComplete, isTrue);
    });

    test('nearestSlot hücre içinde döner', () {
      final board = PuzzleBoard.forPieceCount(3);
      const size = Size(300, 100);
      expect(board.nearestSlot(const Offset(50, 50), size), 0);
      expect(board.nearestSlot(const Offset(150, 50), size), 1);
      expect(board.nearestSlot(const Offset(250, 50), size), 2);
    });

    test('debugForceComplete', () {
      final board = PuzzleBoard.forPieceCount(5);
      board.debugForceComplete();
      expect(board.isComplete, isTrue);
      expect(board.tray, isEmpty);
    });
  });

  group('puzzle attempt kaydı', () {
    test('tamamlanınca activity_attempts', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = ActivityAttemptRepository(prefs);
      await repo.append(
        ActivityAttempt(
          id: 'p1',
          studentId: 's1',
          skill: 'puzzle',
          category: 'puzzle',
          difficulty: 'easy',
          questionId: 'puzzle-3',
          givenAnswer: 'complete',
          correct: true,
          attemptedAt: DateTime.now(),
        ),
      );
      expect(repo.forStudent('s1').single.category, 'puzzle');
    });
  });
}
