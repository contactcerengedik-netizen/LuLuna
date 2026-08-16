import 'package:flutter/material.dart';

/// Gerçek fırça stroke motoru (v3 Faz 12).
/// Flood-fill yok — pan ile stroke; undo; opsiyonel [clipMask].
class CanvasStroke {
  CanvasStroke({
    required List<Offset> points,
    required this.color,
    required this.width,
    this.isEraser = false,
  }) : points = List<Offset>.from(points);

  final List<Offset> points;
  final Color color;
  final double width;
  final bool isEraser;
}

class CanvasEngine {
  CanvasEngine({this.clipMask});

  Path? clipMask;
  final List<CanvasStroke> _strokes = [];
  final List<CanvasStroke> _redo = [];

  List<CanvasStroke> get strokes => List.unmodifiable(_strokes);

  void beginStroke({
    required Offset point,
    required Color color,
    required double width,
    bool erase = false,
  }) {
    _redo.clear();
    _strokes.add(
      CanvasStroke(
        points: [point],
        color: color,
        width: width,
        isEraser: erase,
      ),
    );
  }

  void appendPoint(Offset point) {
    if (_strokes.isEmpty) return;
    _strokes.last.points.add(point);
  }

  bool undo() {
    if (_strokes.isEmpty) return false;
    _redo.add(_strokes.removeLast());
    return true;
  }

  bool redo() {
    if (_redo.isEmpty) return false;
    _strokes.add(_redo.removeLast());
    return true;
  }

  void clear() {
    _strokes.clear();
    _redo.clear();
  }

  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Stroke'ları çizer; [clipMask] varsa yalnızca mask içinde görünür.
  void paintTo(Canvas canvas, Size size, {Color background = Colors.white}) {
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    if (clipMask != null) {
      canvas.clipPath(clipMask!);
    }

    for (final s in _strokes) {
      if (s.points.isEmpty) continue;
      final paint = Paint()
        ..color = s.isEraser ? background : s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (s.points.length == 1) {
        canvas.drawCircle(
          s.points.first,
          s.width / 2,
          paint..style = PaintingStyle.fill,
        );
        continue;
      }
      final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      for (final p in s.points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }
}

/// Sade palet — düşük bilişsel yük.
abstract final class CanvasPalette {
  static const colors = <Color>[
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFDD835),
    Color(0xFF8E24AA),
    Color(0xFF00434B),
    Color(0xFFFFFFFF),
    Color(0xFF212121),
  ];

  static const brushWidths = <double>[18, 28, 40];

  /// AI/mock outline — basit ev + güneş path (clip mask kaynağı).
  static Path sampleClipMask(Size size) {
    final house = Path()
      ..moveTo(size.width * 0.25, size.height * 0.55)
      ..lineTo(size.width * 0.25, size.height * 0.75)
      ..lineTo(size.width * 0.75, size.height * 0.75)
      ..lineTo(size.width * 0.75, size.height * 0.55)
      ..lineTo(size.width * 0.5, size.height * 0.35)
      ..close();
    final sun = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.7, size.height * 0.25),
          radius: size.shortestSide * 0.08,
        ),
      );
    return Path()
      ..addPath(house, Offset.zero)
      ..addPath(sun, Offset.zero);
  }
}
