import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../app/widgets/luluna_ui.dart';
import '../../../core/path_tracing/path_tracing_engine.dart';
import '../../../data/models/skill_level.dart';
import '../../../data/providers.dart';
import '../../education/domain/activity_models.dart';
import '../../education/presentation/activity_session_controller.dart';
import '../domain/tracing_analyzer.dart';

class TracingHubScreen extends StatelessWidget {
  const TracingHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: const Text('Çizgi / Motor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/student'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Seviye seç',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Düz çizgiden kelimeye — parmağını kaldırmadan takip et.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: LulunaColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          for (final kind in TracingActivityKind.values) ...[
            EducationBigTile(
              title: kind.label,
              leading: const EducationModuleIcon(icon: Icons.gesture),
              onTap: () => context.push('/student/tracing/${kind.name}'),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class TracingPlayScreen extends ConsumerStatefulWidget {
  const TracingPlayScreen({
    super.key,
    required this.kind,
    this.glyph,
    this.word = 'ALI',
  });

  final TracingActivityKind kind;
  final String? glyph;
  final String word;

  @override
  ConsumerState<TracingPlayScreen> createState() => _TracingPlayScreenState();
}

class _TracingPlayScreenState extends ConsumerState<TracingPlayScreen> {
  PathTracingEngine? _engine;
  Path? _guidePath;
  PathTracingResult? _result;
  Size _canvasSize = Size.zero;
  late final DateTime _startedAt;
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
  }

  void _ensureGuide(Size size) {
    if (_canvasSize == size && _engine != null) return;
    _canvasSize = size;
    _guidePath = TracingGuides.forKind(
      widget.kind,
      size,
      glyph: widget.glyph,
      word: widget.word,
    );
    final samples = PathTracingEngine.samplePath(_guidePath!);
    _engine = PathTracingEngine(targetPath: samples);
  }

  void _evaluate() {
    final engine = _engine;
    if (engine == null) return;
    final result = widget.kind == TracingActivityKind.freeDraw
        ? PathTracingResult(
            coverage: engine.stroke.length > 8 ? 1 : 0,
            deviationScore: 0,
            completed: engine.stroke.length > 8,
          )
        : engine.evaluate();
    setState(() => _result = result);
    if (result.completed && !_recorded) {
      _recorded = true;
      _record(result);
    }
  }

  Future<void> _record(PathTracingResult result) async {
    final profile = ref.read(currentStudentProfileProvider).asData?.value;
    final studentId =
        profile?.id ?? ref.read(authStateProvider)?.userId ?? 'demo-student';
    final now = DateTime.now();
    final attempt = ActivityAttempt(
      id: 'trace_${now.millisecondsSinceEpoch}',
      studentId: studentId,
      skill: SkillArea.tracing.name,
      category: widget.kind.name,
      difficulty: SkillTier.easy.name,
      questionId: 'trace-${widget.kind.name}-${widget.glyph ?? widget.word}',
      givenAnswer: 'stroke',
      correct: result.completed,
      attemptedAt: now,
      durationMs: now.difference(_startedAt).inMilliseconds,
      deviationScore: result.deviationScore,
    );
    await ref.read(activityAttemptRepositoryProvider).append(attempt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: Text(widget.kind.label),
        actions: [
          IconButton(
            tooltip: 'Temizle',
            onPressed: () => setState(() {
              _engine?.clear();
              _result = null;
              _recorded = false;
            }),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.kind == TracingActivityKind.freeDraw
                    ? 'Serbest çiz. Bitince Kontrol et.’e bas.'
                    : 'Kesik çizgiyi parmağınla takip et (parmak kaldırma yok).',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: LulunaColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final size = Size(c.maxWidth, c.maxHeight);
                    _ensureGuide(size);
                    return Container(
                      decoration: BoxDecoration(
                        color: LulunaColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: LulunaColors.outlineVariant),
                      ),
                      child: GestureDetector(
                        onPanStart: (d) {
                          setState(() {
                            _engine?.onPanStart(d.localPosition);
                            _result = null;
                            _recorded = false;
                          });
                        },
                        onPanUpdate: (d) {
                          setState(
                            () => _engine?.onPanUpdate(d.localPosition),
                          );
                        },
                        onPanEnd: (_) => _evaluate(),
                        child: CustomPaint(
                          painter: _TracingPainter(
                            guide: _guidePath,
                            stroke: _engine?.stroke ?? const [],
                            dots: widget.kind ==
                                TracingActivityKind.connectDots,
                            showGuide:
                                widget.kind != TracingActivityKind.freeDraw,
                          ),
                          size: size,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (_result != null)
                LulunaCard(
                  color: _result!.completed
                      ? LulunaColors.secondaryContainer
                      : LulunaColors.surfaceContainer,
                  child: Text(
                    _result!.completed
                        ? 'Tamam! Sapma: '
                            '${_result!.deviationScore.toStringAsFixed(1)} px'
                        : 'Biraz daha çizgiye yaklaş. '
                            'Sapma: ${_result!.deviationScore.toStringAsFixed(1)} px',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              const SizedBox(height: 12),
              LulunaPrimaryButton(
                label: 'Kontrol et',
                onPressed: (_engine?.stroke.isEmpty ?? true) ? null : _evaluate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TracingPainter extends CustomPainter {
  _TracingPainter({
    required this.guide,
    required this.stroke,
    required this.dots,
    required this.showGuide,
  });

  final Path? guide;
  final List<Offset> stroke;
  final bool dots;
  final bool showGuide;

  @override
  void paint(Canvas canvas, Size size) {
    if (showGuide && guide != null) {
      final guidePaint = Paint()
        ..color = LulunaColors.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      for (final metric in guide!.computeMetrics()) {
        var on = true;
        for (var d = 0.0; d < metric.length; d += 10) {
          if (on) {
            final extract =
                metric.extractPath(d, (d + 6).clamp(0, metric.length));
            canvas.drawPath(extract, guidePaint);
          }
          on = !on;
        }
      }
      if (dots) {
        final dotPaint = Paint()..color = LulunaColors.primary;
        for (final m in guide!.computeMetrics()) {
          for (var d = 0.0; d <= m.length; d += m.length / 3) {
            final t = m.getTangentForOffset(d.clamp(0, m.length));
            if (t != null) {
              canvas.drawCircle(t.position, 8, dotPaint);
            }
          }
        }
      }
    }

    if (stroke.length > 1) {
      final strokePaint = Paint()
        ..color = LulunaColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TracingPainter oldDelegate) => true;
}
