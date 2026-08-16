import 'package:flutter/material.dart';

import '../domain/ai_content_models.dart';

/// Structured JSON'dan türetilen sade mock sahne (gerçek API yokken önizleme).
class AiMockScenePreview extends StatelessWidget {
  const AiMockScenePreview({super.key, required this.activity});

  final TeacherAiActivity activity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6F8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8DD2DF), width: 2),
            ),
            child: CustomPaint(
              painter: _ScenePainter(activity.structured),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          activity.image.description ?? 'Mock görsel önizleme',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (activity.scenePlan != null) ...[
          const SizedBox(height: 8),
          Text(
            'Sahne planı: ${activity.scenePlan!.elements.join(' · ')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.structured);

  final StructuredActivity structured;

  @override
  void paint(Canvas canvas, Size size) {
    final ground = Paint()..color = const Color(0xFFD7E8EA);
    canvas.drawRect(Offset.zero & size, ground);

    // Buzdolabı
    final fridge = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.55, size.height * 0.2, size.width * 0.32,
          size.height * 0.55),
      const Radius.circular(8),
    );
    canvas.drawRRect(fridge, Paint()..color = const Color(0xFF4A5556));
    canvas.drawRRect(
      fridge,
      Paint()
        ..color = const Color(0xFF00434B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    var eggIndex = 0;
    for (final o in structured.objects) {
      final count = o['count'] is int
          ? o['count'] as int
          : int.tryParse('${o['count']}') ?? 1;
      final loc = '${o['location'] ?? ''}';
      for (var i = 0; i < count.clamp(0, 12); i++) {
        final inFridge = loc.contains('fridge') || loc.contains('buz');
        final cx = inFridge
            ? size.width * 0.62 + (i % 3) * 18.0
            : size.width * 0.22 + (i % 3) * 20.0;
        final cy = inFridge
            ? size.height * 0.35 + (i ~/ 3) * 18.0
            : size.height * 0.55 + (i ~/ 3) * 16.0;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy), width: 14, height: 18),
          Paint()..color = const Color(0xFFF5F0E1),
        );
        eggIndex++;
      }
    }
    if (eggIndex == 0) {
      canvas.drawCircle(
        Offset(size.width * 0.35, size.height * 0.5),
        28,
        Paint()..color = const Color(0xFF8DD2DF),
      );
    }

    // Ayşe (basit figür)
    if (structured.characters.isNotEmpty) {
      final head = Offset(size.width * 0.22, size.height * 0.32);
      canvas.drawCircle(head, 16, Paint()..color = const Color(0xFF026F77));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(head.dx, head.dy + 36),
            width: 28,
            height: 40,
          ),
          const Radius.circular(8),
        ),
        Paint()..color = const Color(0xFF00434B),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) =>
      oldDelegate.structured != structured;
}
