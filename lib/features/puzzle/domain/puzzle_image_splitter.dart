import 'dart:ui';

/// Herhangi bir görseli (veya programatik sahneyi) ızgaraya böler.
/// Kaynak boyutundan bağımsız normalize dikdörtgenler (0–1).
class PuzzleSlice {
  const PuzzleSlice({
    required this.id,
    required this.row,
    required this.col,
    required this.srcRect,
  });

  final int id;
  final int row;
  final int col;
  /// Kaynak görsel üzerinde normalize alan (0–1).
  final Rect srcRect;
}

abstract final class PuzzleImageSplitter {
  /// [rows]×[cols] ızgaradan ilk [pieceCount] hücreyi soldan sağa, yukarıdan aşağı.
  static List<PuzzleSlice> split({
    required int rows,
    required int cols,
    required int pieceCount,
  }) {
    assert(rows > 0 && cols > 0);
    assert(pieceCount > 0 && pieceCount <= rows * cols);
    final cellW = 1.0 / cols;
    final cellH = 1.0 / rows;
    return [
      for (var i = 0; i < pieceCount; i++)
        PuzzleSlice(
          id: i,
          row: i ~/ cols,
          col: i % cols,
          srcRect: Rect.fromLTWH(
            (i % cols) * cellW,
            (i ~/ cols) * cellH,
            cellW,
            cellH,
          ),
        ),
    ];
  }

  /// Normalize [srcRect] → gerçek piksel/dikdörtgen.
  static Rect toSourcePixels(Rect srcRect, Size imageSize) {
    return Rect.fromLTWH(
      srcRect.left * imageSize.width,
      srcRect.top * imageSize.height,
      srcRect.width * imageSize.width,
      srcRect.height * imageSize.height,
    );
  }
}
