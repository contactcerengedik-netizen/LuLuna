import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'puzzle_image_splitter.dart';

/// Programatik puzzle: görsel N hücreye bölünür, sürükle-bırak + snap.
class PuzzlePiece {
  const PuzzlePiece({
    required this.id,
    required this.correctIndex,
    required this.row,
    required this.col,
    required this.srcRect,
  });

  final int id;
  final int correctIndex;
  final int row;
  final int col;
  final Rect srcRect;
}

enum PuzzlePlaceResult {
  /// Doğru slota oturdu.
  snapped,
  /// Yanlış / geçersiz — tepsiye döner.
  rejected,
  /// Slot dolu.
  occupied,
}

class PuzzleBoard {
  PuzzleBoard({
    required this.pieceCount,
    required this.rows,
    required this.cols,
    required List<int> slotOrder,
    List<PuzzleSlice>? slices,
  })  : _slots = List<int?>.filled(pieceCount, null),
        _tray = List<int>.from(slotOrder),
        _slices = slices ??
            PuzzleImageSplitter.split(
              rows: rows,
              cols: cols,
              pieceCount: pieceCount,
            ) {
    assert(rows * cols >= pieceCount);
  }

  factory PuzzleBoard.forPieceCount(int pieceCount, {Random? random}) {
    final (rows, cols) = layoutFor(pieceCount);
    final order = List<int>.generate(pieceCount, (i) => i)
      ..shuffle(random ?? Random(3));
    return PuzzleBoard(
      pieceCount: pieceCount,
      rows: rows,
      cols: cols,
      slotOrder: order,
    );
  }

  /// MVP: 3 / 5; mimari: 10 (2×5).
  static (int rows, int cols) layoutFor(int pieceCount) {
    return switch (pieceCount) {
      3 => (1, 3),
      4 => (2, 2),
      5 => (1, 5),
      6 => (2, 3),
      8 => (2, 4),
      9 => (3, 3),
      10 => (2, 5),
      _ => (
          sqrt(pieceCount).ceil(),
          (pieceCount / sqrt(pieceCount).ceil()).ceil(),
        ),
    };
  }

  /// Parça sayısı → seviye (hub / öğretmen önerisi).
  static SkillTierHint tierForPieceCount(int n) => switch (n) {
        <= 3 => SkillTierHint.easy,
        <= 5 => SkillTierHint.medium,
        _ => SkillTierHint.hard,
      };

  final int pieceCount;
  final int rows;
  final int cols;
  final List<PuzzleSlice> _slices;
  final List<int?> _slots;
  final List<int> _tray;

  List<int?> get slots => List.unmodifiable(_slots);
  List<int> get tray => List.unmodifiable(_tray);
  List<PuzzleSlice> get slices => List.unmodifiable(_slices);

  bool get isComplete =>
      _slots.length == pieceCount &&
      List.generate(pieceCount, (i) => i).every((i) => _slots[i] == i);

  int placedCount() => _slots.whereType<int>().length;

  PuzzleSlice sliceFor(int pieceId) => _slices[pieceId];

  void returnToTray(int pieceId) {
    for (var i = 0; i < _slots.length; i++) {
      if (_slots[i] == pieceId) _slots[i] = null;
    }
    if (!_tray.contains(pieceId)) _tray.add(pieceId);
  }

  /// Yalnızca doğru slota snap (özel eğitim: net hedef).
  PuzzlePlaceResult placeCorrectOnly(int pieceId, int slotIndex) {
    if (slotIndex < 0 || slotIndex >= pieceCount) {
      return PuzzlePlaceResult.rejected;
    }
    if (_slots[slotIndex] != null && _slots[slotIndex] != pieceId) {
      return PuzzlePlaceResult.occupied;
    }
    if (pieceId != slotIndex) {
      returnToTray(pieceId);
      return PuzzlePlaceResult.rejected;
    }
    returnToTray(pieceId);
    _tray.remove(pieceId);
    _slots[slotIndex] = pieceId;
    return PuzzlePlaceResult.snapped;
  }

  /// Eski davranış: herhangi boş slota yerleştir (test / esnek mod).
  bool place(int pieceId, int slotIndex) {
    if (slotIndex < 0 || slotIndex >= pieceCount) return false;
    if (_slots[slotIndex] != null) return false;
    returnToTray(pieceId);
    _tray.remove(pieceId);
    _slots[slotIndex] = pieceId;
    return pieceId == slotIndex;
  }

  /// Ekran konumuna en yakın slot (normalize board rect).
  int? nearestSlot(Offset local, Size boardSize, {double snapRatio = 0.45}) {
    if (boardSize.width <= 0 || boardSize.height <= 0) return null;
    final cellW = boardSize.width / cols;
    final cellH = boardSize.height / rows;
    final col = (local.dx / cellW).floor().clamp(0, cols - 1);
    final row = (local.dy / cellH).floor().clamp(0, rows - 1);
    final index = row * cols + col;
    if (index >= pieceCount) return null;
    final center = Offset((col + 0.5) * cellW, (row + 0.5) * cellH);
    final maxDist = Offset(cellW, cellH).distance * snapRatio;
    if ((local - center).distance <= maxDist) return index;
    if (local.dx >= col * cellW &&
        local.dx <= (col + 1) * cellW &&
        local.dy >= row * cellH &&
        local.dy <= (row + 1) * cellH) {
      return index;
    }
    return null;
  }

  @visibleForTesting
  void debugForceComplete() {
    for (var i = 0; i < pieceCount; i++) {
      _slots[i] = i;
    }
    _tray.clear();
  }

  List<PuzzlePiece> piecesMeta() {
    return [
      for (final s in _slices)
        PuzzlePiece(
          id: s.id,
          correctIndex: s.id,
          row: s.row,
          col: s.col,
          srcRect: s.srcRect,
        ),
    ];
  }
}

/// Domain katmanında SkillTier bağımlılığı yok — hub eşlemesi için.
enum SkillTierHint { easy, medium, hard }
