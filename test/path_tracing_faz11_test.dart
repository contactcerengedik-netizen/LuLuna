import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:luluna/core/path_tracing/glyph_paths.dart';
import 'package:luluna/core/path_tracing/path_tracing_engine.dart';
import 'package:luluna/features/tracing/domain/tracing_analyzer.dart';

void main() {
  group('PathTracingEngine', () {
    test('tam örtüşmede düşük sapma + completed', () {
      final target = [
        const Offset(0, 0),
        const Offset(50, 0),
        const Offset(100, 0),
      ];
      final engine = PathTracingEngine(targetPath: target, tolerance: 10);
      engine.onPanStart(const Offset(0, 0));
      engine.onPanUpdate(const Offset(50, 0));
      engine.onPanUpdate(const Offset(100, 0));
      final r = engine.evaluate();
      expect(r.deviationScore, lessThan(1));
      expect(r.completed, isTrue);
      expect(r.coverage, 1);
    });

    test('uzak stroke yüksek deviationScore', () {
      final target = [
        const Offset(0, 0),
        const Offset(100, 0),
      ];
      final engine = PathTracingEngine(targetPath: target, tolerance: 10);
      engine.onPanStart(const Offset(0, 80));
      engine.onPanUpdate(const Offset(100, 80));
      final r = engine.evaluate();
      expect(r.deviationScore, greaterThan(50));
      expect(r.completed, isFalse);
    });
  });

  group('GlyphPaths', () {
    test('A–Z ve 0–9 tanımlı', () {
      for (var i = 0; i < 26; i++) {
        final upper = String.fromCharCode(65 + i);
        final lower = String.fromCharCode(97 + i);
        expect(GlyphPaths.forChar(upper), isNotNull, reason: upper);
        expect(GlyphPaths.forChar(lower), isNotNull, reason: lower);
      }
      for (var d = 0; d <= 9; d++) {
        expect(GlyphPaths.forChar('$d'), isNotNull);
      }
    });

    test('kelime path örneklenir', () {
      const size = Size(300, 120);
      final path = GlyphPaths.pathForWord('CEREN', size);
      final samples = PathTracingEngine.samplePath(path);
      expect(samples.length, greaterThan(20));
    });
  });

  group('TracingGuides', () {
    test('seviyeler path üretir', () {
      const size = Size(280, 280);
      for (final kind in TracingActivityKind.values) {
        if (kind == TracingActivityKind.freeDraw) continue;
        final samples = TracingGuides.sampleForKind(kind, size);
        expect(samples, isNotEmpty, reason: kind.name);
      }
    });
  });
}
