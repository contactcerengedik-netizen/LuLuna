import 'dart:ui';

import '../../../core/path_tracing/glyph_paths.dart';
import '../../../core/path_tracing/path_tracing_engine.dart';

/// Seviye: düz → dalgalı → şekil → rakam → büyük harf → küçük harf → kelime → serbest.
enum TracingActivityKind {
  straightLine('Düz çizgi'),
  wavyLine('Dalgalı çizgi'),
  shape('Temel şekil'),
  digit('Rakam'),
  uppercaseLetter('Büyük harf'),
  lowercaseLetter('Küçük harf'),
  word('Kelime'),
  freeDraw('Serbest çizim'),
  connectDots('Nokta birleştirme');

  const TracingActivityKind(this.label);
  final String label;

  /// Geriye uyum: eski route adları.
  static TracingActivityKind fromRoute(String name) {
    return values.asNameMap()[name] ??
        switch (name) {
          'lineFollow' => straightLine,
          'letter' => uppercaseLetter,
          'pattern' => wavyLine,
          _ => straightLine,
        };
  }
}

/// Hedef path üretici — glyph seti + geometrik kılavuzlar.
abstract final class TracingGuides {
  static Path forKind(
    TracingActivityKind kind,
    Size size, {
    String? glyph,
    String word = 'ALI',
  }) {
    return switch (kind) {
      TracingActivityKind.straightLine => _horizontal(size),
      TracingActivityKind.wavyLine => _wavy(size),
      TracingActivityKind.shape => _circle(size),
      TracingActivityKind.digit => _centeredGlyph(glyph ?? '2', size),
      TracingActivityKind.uppercaseLetter =>
        _centeredGlyph((glyph ?? 'A').toUpperCase(), size),
      TracingActivityKind.lowercaseLetter =>
        _centeredGlyph((glyph ?? 'a').toLowerCase(), size),
      TracingActivityKind.word => _centeredWord(word, size),
      TracingActivityKind.freeDraw => Path(),
      TracingActivityKind.connectDots => _connectDots(size),
    };
  }

  static List<Offset> sampleForKind(
    TracingActivityKind kind,
    Size size, {
    String? glyph,
    String word = 'ALI',
  }) {
    final path = forKind(kind, size, glyph: glyph, word: word);
    if (path.computeMetrics().isEmpty) return const [];
    return PathTracingEngine.samplePath(path);
  }

  static Path _centeredGlyph(String ch, Size canvas, {double scale = 0.78}) {
    final cell = Size(canvas.width * scale, canvas.height * scale);
    final origin = Offset(
      (canvas.width - cell.width) / 2,
      (canvas.height - cell.height) / 2,
    );
    final strokes = GlyphPaths.forChar(ch);
    if (strokes == null) return Path();
    return PathTracingEngine.pathFromNormalized(
      strokes,
      canvas,
      origin: origin,
      cell: cell,
    );
  }

  static Path _centeredWord(String word, Size canvas, {double scale = 0.88}) {
    final cell = Size(canvas.width * scale, canvas.height * scale * 0.7);
    final origin = Offset(
      (canvas.width - cell.width) / 2,
      (canvas.height - cell.height) / 2,
    );
    final inner = GlyphPaths.pathForWord(word, cell);
    return Path()..addPath(inner, origin);
  }

  static Path _horizontal(Size size) => Path()
    ..moveTo(size.width * 0.12, size.height * 0.5)
    ..lineTo(size.width * 0.88, size.height * 0.5);

  static Path _wavy(Size size) {
    final w = size.width;
    final h = size.height;
    final p = Path()..moveTo(w * 0.1, h * 0.5);
    p.quadraticBezierTo(w * 0.25, h * 0.25, w * 0.4, h * 0.5);
    p.quadraticBezierTo(w * 0.55, h * 0.75, w * 0.7, h * 0.5);
    p.quadraticBezierTo(w * 0.85, h * 0.25, w * 0.9, h * 0.5);
    return p;
  }

  static Path _circle(Size size) => Path()
    ..addOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.55,
        height: size.height * 0.55,
      ),
    );

  static Path _connectDots(Size size) {
    final pts = <Offset>[
      Offset(size.width * 0.2, size.height * 0.7),
      Offset(size.width * 0.4, size.height * 0.3),
      Offset(size.width * 0.6, size.height * 0.7),
      Offset(size.width * 0.8, size.height * 0.3),
    ];
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final o in pts.skip(1)) {
      p.lineTo(o.dx, o.dy);
    }
    return p;
  }
}

/// Eski analyzer — [PathTracingEngine] üzerine ince sarmalayıcı.
@Deprecated('Use PathTracingEngine')
class TracingPathAnalyzer {
  const TracingPathAnalyzer({this.tolerance = 28});

  final double tolerance;

  PathTracingResult analyze({
    required List<Offset> guide,
    required List<Offset> stroke,
  }) {
    final engine = PathTracingEngine(
      targetPath: guide,
      tolerance: tolerance,
    );
    for (var i = 0; i < stroke.length; i++) {
      if (i == 0) {
        engine.onPanStart(stroke[i]);
      } else {
        engine.onPanUpdate(stroke[i]);
      }
    }
    return engine.evaluate();
  }

  static List<Offset> sampleGuide(Path path, {double step = 6}) =>
      PathTracingEngine.samplePath(path, step: step);
}

typedef TracingResult = PathTracingResult;
