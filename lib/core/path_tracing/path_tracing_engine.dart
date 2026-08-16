import 'dart:ui';

/// Ortak path takip motoru (v3 Faz 11).
/// Hedef [targetPath] noktaları; kullanıcı [PanUpdate] stroke kaydı; [deviationScore].
class PathTracingEngine {
  PathTracingEngine({
    required List<Offset> targetPath,
    this.tolerance = 28,
    this.coverageThreshold = 0.72,
  }) : targetPath = List.unmodifiable(targetPath);

  final List<Offset> targetPath;
  final double tolerance;
  final double coverageThreshold;

  final List<Offset> _stroke = [];

  List<Offset> get stroke => List.unmodifiable(_stroke);

  void clear() => _stroke.clear();

  void onPanStart(Offset point) {
    _stroke
      ..clear()
      ..add(point);
  }

  void onPanUpdate(Offset point) => _stroke.add(point);

  PathTracingResult evaluate() {
    if (targetPath.isEmpty) {
      return const PathTracingResult(
        coverage: 0,
        deviationScore: 999,
        completed: false,
      );
    }
    if (_stroke.isEmpty) {
      return const PathTracingResult(
        coverage: 0,
        deviationScore: 999,
        completed: false,
      );
    }

    var hit = 0;
    var totalDev = 0.0;
    for (final g in targetPath) {
      var best = double.infinity;
      for (final s in _stroke) {
        final d = (s - g).distance;
        if (d < best) best = d;
      }
      totalDev += best;
      if (best <= tolerance) hit++;
    }

    final coverage = hit / targetPath.length;
    final deviationScore = totalDev / targetPath.length;
    final completed =
        coverage >= coverageThreshold && deviationScore <= tolerance * 1.4;
    return PathTracingResult(
      coverage: coverage,
      deviationScore: deviationScore,
      completed: completed,
    );
  }

  /// [Path] üzerinden eşit aralıklı örnek noktalar.
  static List<Offset> samplePath(Path path, {double step = 6}) {
    final points = <Offset>[];
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += step) {
        final t = m.getTangentForOffset(d);
        if (t != null) points.add(t.position);
      }
    }
    return points;
  }

  /// Normalize (0–1) polylines → ekran boyutu.
  static Path pathFromNormalized(
    List<List<Offset>> strokes,
    Size size, {
    Offset origin = Offset.zero,
    Size? cell,
  }) {
    final cellSize = cell ?? size;
    final p = Path();
    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final first = stroke.first;
      p.moveTo(
        origin.dx + first.dx * cellSize.width,
        origin.dy + first.dy * cellSize.height,
      );
      for (final o in stroke.skip(1)) {
        p.lineTo(
          origin.dx + o.dx * cellSize.width,
          origin.dy + o.dy * cellSize.height,
        );
      }
    }
    return p;
  }
}

class PathTracingResult {
  const PathTracingResult({
    required this.coverage,
    required this.deviationScore,
    required this.completed,
  });

  final double coverage;

  /// Ortalama sapma (px) — activity_attempts / attempt metadata.
  final double deviationScore;
  final bool completed;
}
