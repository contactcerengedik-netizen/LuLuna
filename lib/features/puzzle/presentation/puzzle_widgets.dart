import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Tek bir “görsel” — parçalara bölünür (programatik sahne; asset gerekmez).
class PuzzleScenePainter extends CustomPainter {
  PuzzleScenePainter({this.clip});

  /// Normalize clip (0–1). Null ise tüm sahne.
  final Rect? clip;

  @override
  void paint(Canvas canvas, Size size) {
    if (clip != null) {
      // Parça boyutuna göre tam sahneyi ölçekle; clip bölgesini parçaya sığdır (gerdirme yok).
      canvas.save();
      canvas.clipRect(Offset.zero & size);
      final full = Size(
        size.width / clip!.width,
        size.height / clip!.height,
      );
      canvas.translate(-clip!.left * full.width, -clip!.top * full.height);
      _paintScene(canvas, full);
      canvas.restore();
    } else {
      _paintScene(canvas, size);
    }
  }

  void _paintScene(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8DD2DF), Color(0xFFE8F6F8)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final ground = Paint()..color = const Color(0xFF6B8F71);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.62, size.width, size.height * 0.38),
      ground,
    );

    final sun = Paint()..color = const Color(0xFFFFC857);
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.18),
      size.shortestSide * 0.12,
      sun,
    );

    final house = Paint()..color = const Color(0xFF00434B);
    final houseRect = Rect.fromLTWH(
      size.width * 0.28,
      size.height * 0.38,
      size.width * 0.32,
      size.height * 0.28,
    );
    canvas.drawRect(houseRect, house);

    final roof = Path()
      ..moveTo(houseRect.left - 8, houseRect.top)
      ..lineTo(houseRect.center.dx, houseRect.top - size.height * 0.12)
      ..lineTo(houseRect.right + 8, houseRect.top)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF026F77));

    final door = Paint()..color = const Color(0xFF9DF0F8);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(houseRect.center.dx, houseRect.bottom - 18),
        width: houseRect.width * 0.28,
        height: houseRect.height * 0.45,
      ),
      door,
    );

    final trunk = Paint()..color = const Color(0xFF5C4033);
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.48,
        size.width * 0.06,
        size.height * 0.2,
      ),
      trunk,
    );
    final leaves = Paint()..color = const Color(0xFF2E7D4F);
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.45),
      size.shortestSide * 0.1,
      leaves,
    );

    // Hafif ızgara ipucu (dikkat dağıtmaz).
    final guide = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), guide);
    }
  }

  @override
  bool shouldRepaint(covariant PuzzleScenePainter oldDelegate) =>
      oldDelegate.clip != clip;
}

/// Parça yüzeyi: sahneden dilim + büyük numara (okunabilirlik).
class PuzzlePieceFace extends StatelessWidget {
  const PuzzlePieceFace({
    super.key,
    required this.srcRect,
    required this.label,
    this.border = true,
  });

  final Rect srcRect;
  final String label;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CustomPaint(
        painter: PuzzleScenePainter(clip: srcRect),
        child: Container(
          alignment: Alignment.center,
          decoration: border
              ? BoxDecoration(
                  border: Border.all(color: Colors.white70, width: 2),
                  borderRadius: BorderRadius.circular(10),
                )
              : null,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tamamlanınca sade ölçek animasyonu.
class PuzzleCelebrateBanner extends StatefulWidget {
  const PuzzleCelebrateBanner({super.key, required this.child});

  final Widget child;

  @override
  State<PuzzleCelebrateBanner> createState() => _PuzzleCelebrateBannerState();
}

class _PuzzleCelebrateBannerState extends State<PuzzleCelebrateBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutBack,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.85, end: 1).animate(_scale),
      child: FadeTransition(
        opacity: _scale,
        child: widget.child,
      ),
    );
  }
}

double puzzleSnapDistance(Offset a, Offset b) => (a - b).distance;

bool puzzleNearCenter({
  required Offset local,
  required Size cellSize,
  required Offset cellOrigin,
  double ratio = 0.45,
}) {
  final center = cellOrigin + Offset(cellSize.width / 2, cellSize.height / 2);
  final maxDist = math.sqrt(
        cellSize.width * cellSize.width + cellSize.height * cellSize.height,
      ) *
      ratio;
  return puzzleSnapDistance(local, center) <= maxDist;
}
