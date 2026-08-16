import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/canvas/canvas_engine.dart';

/// Boyama — flood-fill yok; [CanvasEngine] fırça + undo + clip mask.
class ColoringScreen extends StatefulWidget {
  const ColoringScreen({super.key});

  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends State<ColoringScreen> {
  final _engine = CanvasEngine();
  var _color = CanvasPalette.colors.first;
  var _width = CanvasPalette.brushWidths[1];
  var _erase = false;
  Size _lastSize = Size.zero;

  void _ensureMask(Size size) {
    if (_lastSize == size) return;
    _lastSize = size;
    _engine.clipMask = CanvasPalette.sampleClipMask(size);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: const Text('Boyama'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/student'),
        ),
        actions: [
          IconButton(
            tooltip: 'Geri al',
            onPressed: _engine.canUndo
                ? () => setState(() => _engine.undo())
                : null,
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'İleri al',
            onPressed: _engine.canRedo
                ? () => setState(() => _engine.redo())
                : null,
            icon: const Icon(Icons.redo),
          ),
          IconButton(
            tooltip: 'Temizle',
            onPressed: () => setState(() => _engine.clear()),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Parmağınla boya — sürükle. (Dokun-doldur / flood fill yok)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LulunaColors.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LulunaColors.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final size = Size(c.maxWidth, c.maxHeight);
                      _ensureMask(size);
                      return Stack(
                        children: [
                          CustomPaint(
                            painter: _OutlineHintPainter(
                              mask: _engine.clipMask,
                            ),
                            size: size,
                          ),
                          GestureDetector(
                            onPanStart: (d) {
                              setState(() {
                                _engine.beginStroke(
                                  point: d.localPosition,
                                  color: _color,
                                  width: _width,
                                  erase: _erase,
                                );
                              });
                            },
                            onPanUpdate: (d) {
                              setState(
                                () => _engine.appendPoint(d.localPosition),
                              );
                            },
                            child: CustomPaint(
                              painter: _CanvasPainter(engine: _engine),
                              size: size,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final c in CanvasPalette.colors)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _color = c;
                          _erase = false;
                        }),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: !_erase && _color == c
                                  ? LulunaColors.primary
                                  : LulunaColors.outlineVariant,
                              width: !_erase && _color == c ? 3 : 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  for (final w in CanvasPalette.brushWidths)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          onPressed: () => setState(() {
                            _width = w;
                            _erase = false;
                          }),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: !_erase && _width == w
                                ? LulunaColors.secondaryContainer
                                : null,
                          ),
                          child: Text('${w.toInt()}'),
                        ),
                      ),
                    ),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _erase = true),
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            _erase ? LulunaColors.secondaryContainer : null,
                      ),
                      icon: const Icon(Icons.cleaning_services_outlined),
                      label: const Text('Sil'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  _CanvasPainter({required this.engine});

  final CanvasEngine engine;

  @override
  void paint(Canvas canvas, Size size) {
    engine.paintTo(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}

class _OutlineHintPainter extends CustomPainter {
  _OutlineHintPainter({required this.mask});

  final Path? mask;

  @override
  void paint(Canvas canvas, Size size) {
    if (mask == null) return;
    final paint = Paint()
      ..color = LulunaColors.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(mask!, paint);
  }

  @override
  bool shouldRepaint(covariant _OutlineHintPainter oldDelegate) =>
      oldDelegate.mask != mask;
}
