import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../data/models/education_question.dart';
import '../../../../data/models/skill_level.dart';
import '../../domain/scene_visual_spec.dart';

/// Soru bağlamına özel eğitici görsel (AI http/data URL veya mock sahne).
class EducationQuestionVisual extends StatelessWidget {
  const EducationQuestionVisual({
    super.key,
    required this.question,
    this.mode = EducationVisualMode.question,
  });

  final EducationQuestion question;
  final EducationVisualMode mode;

  @override
  Widget build(BuildContext context) {
    final url = mode == EducationVisualMode.solution
        ? (question.solutionImageUrl ?? question.imageUrl)
        : question.imageUrl;

    Widget child;
    if (url != null && url.startsWith('data:image')) {
      try {
        final b64 = url.split(',').last;
        child = Image.memory(
          base64Decode(b64),
          fit: BoxFit.contain,
          gaplessPlayback: true,
        );
      } catch (e) {
        debugPrint('[EducationVisual] base64 decode hata: $e');
        child = const _VisualUnavailable(message: 'Görsel yüklenemedi');
      }
    } else if (url != null &&
        url.isNotEmpty &&
        !url.startsWith('mock:') &&
        (url.startsWith('http') || url.startsWith('assets/'))) {
      child = url.startsWith('assets/')
          ? Image.asset(url, fit: BoxFit.contain)
          : Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Görsel yükleniyor…'),
                    ],
                  ),
                );
              },
              errorBuilder: (context, error, stack) {
                debugPrint('[EducationVisual] network hata: $error');
                return const _VisualUnavailable(
                  message:
                      'Günlük görsel üretim kotası doldu veya görsel '
                      'hazır değil.',
                );
              },
            );
    } else {
      child = const _VisualUnavailable(
        message:
            'Görsel henüz hazır değil. Kota dolduysa yarın tekrar deneyin.',
      );
    }

    final caption = SceneVisualSpec.fromMap(
      question.metadata['sceneVisual'] is Map
          ? Map<String, dynamic>.from(question.metadata['sceneVisual'] as Map)
          : null,
    ).caption;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6F8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LulunaColors.secondary, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: child,
            ),
          ),
        ),
        if (caption != null && caption.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            mode == EducationVisualMode.solution
                ? 'Görsel çözüm: $caption'
                : caption,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LulunaColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    );
  }
}

enum EducationVisualMode { question, solution }

/// Gerçek görsel yokken soyut şekil ÇİZME — gri durum paneli.
class _VisualUnavailable extends StatelessWidget {
  const _VisualUnavailable({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE8EAED),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EducationalScenePainter extends CustomPainter {
  EducationalScenePainter({required this.question, required this.mode});

  final EducationQuestion question;
  final EducationVisualMode mode;

  @override
  void paint(Canvas canvas, Size size) {
    final raw = question.metadata['sceneVisual'];
    final spec = SceneVisualSpec.fromMap(
      raw is Map ? Map<String, dynamic>.from(raw) : null,
    );

    // Fallback: eski a/b metadata → abstract_dots
    if (spec.template == 'abstract_dots' &&
        question.metadata['a'] != null &&
        question.metadata['b'] != null) {
      _paintDotsOp(canvas, size);
      return;
    }

    switch (spec.template) {
      case 'fridge_eggs':
        _paintFridgeEggs(canvas, size, spec);
      case 'park_ball':
        _paintParkBalls(canvas, size, spec);
      case 'kitchen_apples':
        _paintApples(canvas, size, spec);
      case 'shelf_books':
        _paintBooks(canvas, size, spec);
      case 'plate_food':
        _paintCookies(canvas, size, spec);
      case 'beach':
        _paintBeach(canvas, size, spec);
      case 'classroom':
        _paintClassroom(canvas, size, spec);
      case 'market':
        _paintMarket(canvas, size, spec);
      case 'garden':
        _paintGarden(canvas, size, spec);
      case 'bedtime':
        _paintToys(canvas, size, spec);
      case 'scene_5n1k':
        _paintFiveW1h(canvas, size, spec);
      case 'fraction_bars':
        _paintFraction(canvas, size);
      default:
        if (question.skill == SkillArea.language) {
          _paintLanguageFallback(canvas, size, spec);
        } else {
          _paintDotsOp(canvas, size);
        }
    }

    if (mode == EducationVisualMode.solution) {
      _paintSolutionBadge(canvas, size);
    }
  }

  void _bg(Canvas canvas, Size size, Color top, Color bottom) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ).createShader(Offset.zero & size),
    );
  }

  void _drawChild(Canvas canvas, Offset head, {Color shirt = const Color(0xFF00434B)}) {
    canvas.drawCircle(head, 14, Paint()..color = const Color(0xFFFFCC80));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(head.dx, head.dy + 32), width: 26, height: 36),
        const Radius.circular(8),
      ),
      Paint()..color = shirt,
    );
  }

  void _drawEggs(Canvas canvas, Offset origin, int count, {double gap = 16}) {
    for (var i = 0; i < count.clamp(0, 12); i++) {
      final cx = origin.dx + (i % 4) * gap;
      final cy = origin.dy + (i ~/ 4) * (gap + 2);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: 12, height: 16),
        Paint()..color = const Color(0xFFFFF8E7),
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: 12, height: 16),
        Paint()
          ..color = const Color(0xFFBCAAA4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _paintFridgeEggs(Canvas canvas, Size size, SceneVisualSpec spec) {
    _bg(canvas, size, const Color(0xFFE3F2FD), const Color(0xFFFFF3E0));
    // floor
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.78, size.width, size.height * 0.22),
      Paint()..color = const Color(0xFFD7CCC8),
    );
    // fridge
    final fridge = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.55, size.height * 0.18, size.width * 0.35,
          size.height * 0.58),
      const Radius.circular(10),
    );
    canvas.drawRRect(fridge, Paint()..color = const Color(0xFF90A4AE));
    canvas.drawRRect(
      fridge,
      Paint()
        ..color = const Color(0xFF455A64)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final inFridge = spec.counts['fridge'] ?? spec.counts.values.firstOrNull ?? 3;
    final inHand = spec.counts['hand'] ?? spec.counts.values.skip(1).firstOrNull ?? 2;
    _drawEggs(canvas, Offset(size.width * 0.62, size.height * 0.32), inFridge);
    _drawChild(canvas, Offset(size.width * 0.22, size.height * 0.42));
    // hand eggs near child
    _drawEggs(canvas, Offset(size.width * 0.32, size.height * 0.55), inHand, gap: 14);
    // arrow toward fridge
    final arrow = Paint()
      ..color = const Color(0xFF00434B)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.38, size.height * 0.5),
      Offset(size.width * 0.52, size.height * 0.45),
      arrow,
    );
  }

  void _paintParkBalls(Canvas canvas, Size size, SceneVisualSpec spec) {
    _bg(canvas, size, const Color(0xFF81D4FA), const Color(0xFFA5D6A7));
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.18),
      22,
      Paint()..color = const Color(0xFFFFF176),
    );
    final g = spec.counts['ground'] ?? 3;
    final bag = spec.counts['bag'] ?? 2;
    _drawChild(canvas, Offset(size.width * 0.2, size.height * 0.4),
        shirt: const Color(0xFF1565C0));
    for (var i = 0; i < g.clamp(0, 10); i++) {
      canvas.drawCircle(
        Offset(size.width * 0.45 + (i % 5) * 22, size.height * 0.7 + (i ~/ 5) * 18),
        10,
        Paint()..color = const Color(0xFFE53935),
      );
    }
    // bag
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.12, size.height * 0.62, 50, 40),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF6D4C41),
    );
    for (var i = 0; i < bag.clamp(0, 6); i++) {
      canvas.drawCircle(
        Offset(size.width * 0.18 + i * 12, size.height * 0.68),
        7,
        Paint()..color = const Color(0xFF1E88E5),
      );
    }
  }

  void _paintApples(Canvas canvas, Size size, SceneVisualSpec spec) {
    _bg(canvas, size, const Color(0xFFFFF8E1), const Color(0xFFE8F5E9));
    final basket = spec.counts['basket'] ?? 3;
    final table = spec.counts['table'] ?? 2;
    _drawChild(canvas, Offset(size.width * 0.2, size.height * 0.38),
        shirt: const Color(0xFFC62828));
    // basket
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.65, size.height * 0.55),
        width: 90,
        height: 50,
      ),
      Paint()..color = const Color(0xFF8D6E63),
    );
    for (var i = 0; i < basket.clamp(0, 10); i++) {
      canvas.drawCircle(
        Offset(size.width * 0.55 + (i % 4) * 18, size.height * 0.48 + (i ~/ 4) * 14),
        10,
        Paint()..color = const Color(0xFFE53935),
      );
    }
    for (var i = 0; i < table.clamp(0, 8); i++) {
      canvas.drawCircle(
        Offset(size.width * 0.35 + i * 16, size.height * 0.72),
        9,
        Paint()..color = const Color(0xFF43A047),
      );
    }
  }

  void _paintBooks(Canvas canvas, Size size, SceneVisualSpec spec) {
    _bg(canvas, size, const Color(0xFFEFEBE9), const Color(0xFFFFF3E0));
    final shelf = spec.counts['shelf'] ?? 3;
    final hand = spec.counts['hand'] ?? 1;
    _drawChild(canvas, Offset(size.width * 0.2, size.height * 0.4));
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.45, size.height * 0.25, size.width * 0.45,
          size.height * 0.5),
      Paint()..color = const Color(0xFF5D4037),
    );
    for (var i = 0; i < shelf.clamp(0, 10); i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * 0.5 + (i % 5) * 18,
          size.height * 0.32 + (i ~/ 5) * 40,
          14,
          32,
        ),
        Paint()
          ..color = Color.lerp(
                const Color(0xFF1E88E5),
                const Color(0xFFE53935),
                i / 10,
              ) ??
              Colors.blue,
      );
    }
    for (var i = 0; i < hand.clamp(0, 5); i++) {
      canvas.drawRect(
        Rect.fromLTWH(size.width * 0.28 + i * 12, size.height * 0.55, 10, 28),
        Paint()..color = const Color(0xFF00897B),
      );
    }
  }

  void _paintCookies(Canvas canvas, Size size, SceneVisualSpec spec) {
    _bg(canvas, size, const Color(0xFFFFFDE7), const Color(0xFFFFE0B2));
    final plate = spec.counts['plate'] ?? 3;
    final box = spec.counts['box'] ?? 2;
    _drawChild(canvas, Offset(size.width * 0.18, size.height * 0.4),
        shirt: const Color(0xFF6A1B9A));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.65, size.height * 0.55),
        width: 100,
        height: 60,
      ),
      Paint()..color = const Color(0xFFEEEEEE),
    );
    for (var i = 0; i < plate.clamp(0, 10); i++) {
      canvas.drawCircle(
        Offset(size.width * 0.55 + (i % 4) * 18, size.height * 0.5 + (i ~/ 4) * 16),
        9,
        Paint()..color = const Color(0xFFD7A86E),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.28, size.height * 0.6, 55, 40),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF8D6E63),
    );
    for (var i = 0; i < box.clamp(0, 6); i++) {
      canvas.drawCircle(
        Offset(size.width * 0.34 + i * 10, size.height * 0.68),
        6,
        Paint()..color = const Color(0xFFBCAAA4),
      );
    }
  }

  void _paintBeach(Canvas canvas, Size size, SceneVisualSpec spec) {
    _bg(canvas, size, const Color(0xFF81D4FA), const Color(0xFFFFE082));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.2),
      Paint()..color = const Color(0xFF4FC3F7),
    );
    final sand = spec.counts['sand'] ?? 3;
    final bucket = spec.counts['bucket'] ?? 2;
    _drawChild(canvas, Offset(size.width * 0.2, size.height * 0.4),
        shirt: const Color(0xFF00838F));
    for (var i = 0; i < sand.clamp(0, 10); i++) {
      _drawStar(
        canvas,
        Offset(size.width * 0.45 + (i % 5) * 22, size.height * 0.72 + (i ~/ 5) * 16),
        8,
        const Color(0xFFFF8A65),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.12, size.height * 0.62, 40, 35),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFE53935),
    );
    for (var i = 0; i < bucket.clamp(0, 5); i++) {
      _drawStar(
        canvas,
        Offset(size.width * 0.16 + i * 10, size.height * 0.68),
        5,
        const Color(0xFFFFCC80),
      );
    }
  }

  void _paintClassroom(Canvas canvas, Size size, SceneVisualSpec spec) {
    _bg(canvas, size, const Color(0xFFE8EAF6), const Color(0xFFC5CAE9));
    final box = spec.counts['box'] ?? 3;
    final desk = spec.counts['desk'] ?? 2;
    _drawChild(canvas, Offset(size.width * 0.2, size.height * 0.4));
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.45, size.height * 0.45, 100, 50),
      Paint()..color = const Color(0xFF8D6E63),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.28, 60, 40),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF90CAF9),
    );
    for (var i = 0; i < box.clamp(0, 10); i++) {
      canvas.drawLine(
        Offset(size.width * 0.58 + (i % 5) * 10, size.height * 0.32),
        Offset(size.width * 0.58 + (i % 5) * 10, size.height * 0.48),
        Paint()
          ..color = const Color(0xFFFFB300)
          ..strokeWidth = 3,
      );
    }
    for (var i = 0; i < desk.clamp(0, 6); i++) {
      canvas.drawLine(
        Offset(size.width * 0.48 + i * 12, size.height * 0.52),
        Offset(size.width * 0.48 + i * 12, size.height * 0.68),
        Paint()
          ..color = const Color(0xFF5C6BC0)
          ..strokeWidth = 3,
      );
    }
  }

  void _paintMarket(Canvas canvas, Size size, SceneVisualSpec spec) {
    _bg(canvas, size, const Color(0xFFFFF3E0), const Color(0xFFFFECB3));
    final bag = spec.counts['bag'] ?? 3;
    final cart = spec.counts['cart'] ?? 2;
    _drawChild(canvas, Offset(size.width * 0.2, size.height * 0.4),
        shirt: const Color(0xFF2E7D32));
    for (var i = 0; i < bag.clamp(0, 10); i++) {
      canvas.drawCircle(
        Offset(size.width * 0.5 + (i % 4) * 18, size.height * 0.45 + (i ~/ 4) * 16),
        10,
        Paint()..color = const Color(0xFFFF7043),
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.6, 80, 45),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF78909C),
    );
    for (var i = 0; i < cart.clamp(0, 6); i++) {
      canvas.drawCircle(
        Offset(size.width * 0.62 + i * 12, size.height * 0.7),
        7,
        Paint()..color = const Color(0xFFFFCA28),
      );
    }
  }

  void _paintGarden(Canvas canvas, Size size, SceneVisualSpec spec) {
    _bg(canvas, size, const Color(0xFFB3E5FC), const Color(0xFFA5D6A7));
    final pot = spec.counts['pot'] ?? 3;
    final ground = spec.counts['ground'] ?? 2;
    _drawChild(canvas, Offset(size.width * 0.2, size.height * 0.4),
        shirt: const Color(0xFF558B2F));
    for (var i = 0; i < pot.clamp(0, 8); i++) {
      final x = size.width * 0.5 + (i % 4) * 28;
      final y = size.height * 0.55 + (i ~/ 4) * 30;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, 20, 16),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF8D6E63),
      );
      canvas.drawCircle(
        Offset(x + 10, y - 6),
        8,
        Paint()..color = const Color(0xFFE91E63),
      );
    }
    for (var i = 0; i < ground.clamp(0, 6); i++) {
      canvas.drawCircle(
        Offset(size.width * 0.35 + i * 16, size.height * 0.75),
        7,
        Paint()..color = const Color(0xFFAB47BC),
      );
    }
  }

  void _paintToys(Canvas canvas, Size size, SceneVisualSpec spec) {
    _bg(canvas, size, const Color(0xFFE1BEE7), const Color(0xFFD1C4E9));
    final box = spec.counts['box'] ?? 3;
    final floor = spec.counts['floor'] ?? 2;
    _drawChild(canvas, Offset(size.width * 0.2, size.height * 0.4),
        shirt: const Color(0xFF4527A0));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.5, size.height * 0.45, 90, 55),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFFFF8A65),
    );
    for (var i = 0; i < box.clamp(0, 8); i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.55 + (i % 3) * 22,
            size.height * 0.5 + (i ~/ 3) * 16,
            16,
            12,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF42A5F5),
      );
    }
    for (var i = 0; i < floor.clamp(0, 6); i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.3 + i * 18, size.height * 0.72, 14, 10),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFF66BB6A),
      );
    }
  }

  void _paintFiveW1h(Canvas canvas, Size size, SceneVisualSpec spec) {
    final setting = spec.setting ?? 'park';
    switch (setting) {
      case 'deniz' || 'beach':
        _bg(canvas, size, const Color(0xFF81D4FA), const Color(0xFFFFE082));
        canvas.drawRect(
          Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.25),
          Paint()..color = const Color(0xFF29B6F6),
        );
      case 'park':
        _bg(canvas, size, const Color(0xFF81D4FA), const Color(0xFFA5D6A7));
      case 'ev' || 'home':
        _bg(canvas, size, const Color(0xFFFFE0B2), const Color(0xFFFFF3E0));
      case 'okul' || 'school':
        _bg(canvas, size, const Color(0xFFC5CAE9), const Color(0xFFE8EAF6));
      case 'bahçe' || 'garden':
        _bg(canvas, size, const Color(0xFFB3E5FC), const Color(0xFFA5D6A7));
      case 'market':
        _bg(canvas, size, const Color(0xFFFFF3E0), const Color(0xFFFFECB3));
      default:
        _bg(canvas, size, const Color(0xFFE0F7FA), const Color(0xFFB2EBF2));
    }
    _drawChild(canvas, Offset(size.width * 0.35, size.height * 0.4));
    // object hint
    final obj = spec.objects.isNotEmpty ? spec.objects.first : 'top';
    if (obj.contains('top') || obj.contains('ball')) {
      canvas.drawCircle(
        Offset(size.width * 0.55, size.height * 0.65),
        18,
        Paint()..color = const Color(0xFFE53935),
      );
    } else if (obj.contains('kitap') || obj.contains('book')) {
      canvas.drawRect(
        Rect.fromLTWH(size.width * 0.5, size.height * 0.55, 40, 50),
        Paint()..color = const Color(0xFF1E88E5),
      );
    } else if (obj.contains('bisiklet')) {
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.65),
        16,
        Paint()
          ..color = const Color(0xFF455A64)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      canvas.drawCircle(
        Offset(size.width * 0.65, size.height * 0.65),
        16,
        Paint()
          ..color = const Color(0xFF455A64)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    } else if (obj.contains('çiçek')) {
      canvas.drawCircle(
        Offset(size.width * 0.55, size.height * 0.62),
        14,
        Paint()..color = const Color(0xFFE91E63),
      );
      canvas.drawRect(
        Rect.fromLTWH(size.width * 0.53, size.height * 0.72, 8, 18),
        Paint()..color = const Color(0xFF66BB6A),
      );
    } else if (obj.contains('köpek')) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.58, size.height * 0.68),
          width: 44,
          height: 28,
        ),
        Paint()..color = const Color(0xFF8D6E63),
      );
    } else if (obj.contains('ekmek') || obj.contains('yemek')) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.58, size.height * 0.65),
          width: 40,
          height: 24,
        ),
        Paint()..color = const Color(0xFFD7A86E),
      );
    } else if (obj.contains('kum') || obj.contains('kale')) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.48, size.height * 0.55, 50, 40),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFFFFE082),
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(size.width * 0.5, size.height * 0.55, 45, 35),
          const Radius.circular(8),
        ),
        Paint()..color = const Color(0xFF8DD2DF),
      );
    }
    // caption labels as chips
    final tp = TextPainter(
      text: TextSpan(
        text: spec.caption ?? spec.character ?? '',
        style: const TextStyle(
          color: Color(0xFF00434B),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.9);
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height * 0.88));
  }

  void _paintFraction(Canvas canvas, Size size) {
    _bg(canvas, size, const Color(0xFFE8F5E9), const Color(0xFFC8E6C9));
    final whole = (question.metadata['whole'] as num?)?.toInt() ?? 4;
    final shaded = (question.metadata['shaded'] as num?)?.toInt() ?? 2;
    final pad = size.width * 0.1;
    final barW = (size.width - pad * 2) / whole;
    final top = size.height * 0.35;
    final h = size.height * 0.3;
    for (var i = 0; i < whole; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(pad + i * barW + 3, top, barW - 6, h),
          const Radius.circular(8),
        ),
        Paint()
          ..color = i < shaded
              ? const Color(0xFF1E88E5)
              : const Color(0xFFCFD8DC),
      );
    }
  }

  void _paintLanguageFallback(Canvas canvas, Size size, SceneVisualSpec spec) {
    _bg(canvas, size, const Color(0xFFE0F2F1), const Color(0xFFB2DFDB));
    _drawChild(canvas, Offset(size.width * 0.5, size.height * 0.4));
    final label = spec.caption ?? question.correctAnswer;
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFF00434B),
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.9);
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height * 0.75));
  }

  void _paintDotsOp(Canvas canvas, Size size) {
    _bg(canvas, size, const Color(0xFFE8F6F8), const Color(0xFFD7E8EA));
    final a = (question.metadata['a'] as num?)?.toInt() ?? 2;
    final b = (question.metadata['b'] as num?)?.toInt() ?? 2;
    _paintDotRow(canvas, size, a.clamp(0, 12), const Color(0xFFE53935), 0.28);
    final tp = TextPainter(
      text: TextSpan(
        text: mode == EducationVisualMode.solution
            ? '+  →  ${a + b}'
            : '+',
        style: const TextStyle(
          color: Color(0xFF00434B),
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height * 0.45));
    final show = mode == EducationVisualMode.solution ? a + b : b;
    _paintDotRow(
      canvas,
      size,
      show.clamp(0, 16),
      mode == EducationVisualMode.solution
          ? const Color(0xFF43A047)
          : const Color(0xFF1E88E5),
      0.68,
    );
  }

  void _paintDotRow(
    Canvas canvas,
    Size size,
    int count,
    Color color,
    double yFactor,
  ) {
    if (count <= 0) return;
    final cy = size.height * yFactor;
    final r = (size.width / (count + 4)).clamp(6.0, 14.0);
    for (var i = 0; i < count; i++) {
      final cx = count == 1
          ? size.width / 2
          : size.width * 0.12 + (size.width * 0.76) * i / (count - 1);
      canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color);
    }
  }

  void _paintSolutionBadge(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: const TextSpan(
        text: '✓',
        style: TextStyle(
          color: Color(0xFF2E7D32),
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width - 12, 8));
  }

  void _drawStar(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? r : r * 0.45;
      final p = Offset(c.dx + rad * math.cos(a), c.dy + rad * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant EducationalScenePainter oldDelegate) =>
      oldDelegate.question.id != question.id || oldDelegate.mode != mode;
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
