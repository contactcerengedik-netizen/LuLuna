import 'dart:math' as math;

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

  static const figureLabels = <String>[
    'Ev',
    'Elma',
    'Araba',
    'Güneş',
    'Çiçek',
    'Kedi',
    'Balık',
    'Yıldız',
    'Kalp',
    'Balon',
  ];

  /// En az 10 basit figür anahattı (clip mask).
  static Path outlineFor(int index, Size size) {
    final i = index % figureLabels.length;
    return switch (i) {
      0 => sampleClipMask(size),
      1 => _apple(size),
      2 => _car(size),
      3 => _sunOnly(size),
      4 => _flower(size),
      5 => _cat(size),
      6 => _fish(size),
      7 => _star(size),
      8 => _heart(size),
      _ => _balloon(size),
    };
  }

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

  static Path _apple(Size size) {
    final c = Offset(size.width * 0.5, size.height * 0.55);
    final r = size.shortestSide * 0.28;
    return Path()
      ..addOval(Rect.fromCircle(center: c, radius: r))
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.15, c.dy - r * 1.35)
      ..lineTo(c.dx - r * 0.05, c.dy - r * 0.85);
  }

  static Path _car(Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.15,
        size.height * 0.45,
        size.width * 0.7,
        size.height * 0.22,
      ),
      const Radius.circular(12),
    );
    final cabin = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.32,
        size.width * 0.4,
        size.height * 0.18,
      ),
      const Radius.circular(8),
    );
    final w1 = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.3, size.height * 0.7),
          radius: size.shortestSide * 0.08,
        ),
      );
    final w2 = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.7, size.height * 0.7),
          radius: size.shortestSide * 0.08,
        ),
      );
    return Path()
      ..addRRect(body)
      ..addRRect(cabin)
      ..addPath(w1, Offset.zero)
      ..addPath(w2, Offset.zero);
  }

  static Path _sunOnly(Size size) {
    return Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.5),
          radius: size.shortestSide * 0.28,
        ),
      );
  }

  static Path _flower(Size size) {
    final c = Offset(size.width * 0.5, size.height * 0.48);
    final pr = size.shortestSide * 0.12;
    final path = Path()
      ..addOval(Rect.fromCircle(center: c, radius: pr * 0.7));
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * 3.14159 / 5;
      path.addOval(
        Rect.fromCircle(
          center: Offset(c.dx + pr * 1.4 * math.cos(a), c.dy + pr * 1.4 * math.sin(a)),
          radius: pr,
        ),
      );
    }
    return path;
  }

  static Path _cat(Size size) {
    final head = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.5),
          radius: size.shortestSide * 0.22,
        ),
      );
    final earL = Path()
      ..moveTo(size.width * 0.32, size.height * 0.38)
      ..lineTo(size.width * 0.28, size.height * 0.22)
      ..lineTo(size.width * 0.42, size.height * 0.34)
      ..close();
    final earR = Path()
      ..moveTo(size.width * 0.68, size.height * 0.38)
      ..lineTo(size.width * 0.72, size.height * 0.22)
      ..lineTo(size.width * 0.58, size.height * 0.34)
      ..close();
    return Path()
      ..addPath(head, Offset.zero)
      ..addPath(earL, Offset.zero)
      ..addPath(earR, Offset.zero);
  }

  static Path _fish(Size size) {
    final body = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.45, size.height * 0.5),
          width: size.width * 0.45,
          height: size.height * 0.28,
        ),
      );
    final tail = Path()
      ..moveTo(size.width * 0.65, size.height * 0.5)
      ..lineTo(size.width * 0.85, size.height * 0.35)
      ..lineTo(size.width * 0.85, size.height * 0.65)
      ..close();
    return Path()
      ..addPath(body, Offset.zero)
      ..addPath(tail, Offset.zero);
  }

  static Path _star(Size size) {
    final c = Offset(size.width * 0.5, size.height * 0.5);
    final r = size.shortestSide * 0.3;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -3.14159 / 2 + i * 3.14159 / 5;
      final rad = i.isEven ? r : r * 0.45;
      final p = Offset(c.dx + rad * math.cos(a), c.dy + rad * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  static Path _heart(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, h * 0.72)
      ..cubicTo(w * 0.15, h * 0.5, w * 0.2, h * 0.22, w * 0.5, h * 0.38)
      ..cubicTo(w * 0.8, h * 0.22, w * 0.85, h * 0.5, w * 0.5, h * 0.72)
      ..close();
  }

  static Path _balloon(Size size) {
    final path = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.4),
          radius: size.shortestSide * 0.22,
        ),
      );
    path.moveTo(size.width * 0.5, size.height * 0.62);
    path.lineTo(size.width * 0.5, size.height * 0.82);
    return path;
  }
}
