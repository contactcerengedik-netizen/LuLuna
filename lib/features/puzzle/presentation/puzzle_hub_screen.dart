import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../app/widgets/luluna_ui.dart';
import '../../../data/models/skill_keys.dart';
import '../../../data/models/skill_level.dart';
import '../../../data/providers.dart';
import '../../education/domain/activity_models.dart';
import '../../education/presentation/activity_session_controller.dart';
import '../domain/puzzle_board.dart';
import 'puzzle_widgets.dart';

class PuzzleHubScreen extends ConsumerWidget {
  const PuzzleHubScreen({super.key});

  /// MVP: 3–5; mimari hazır: 10.
  static const options = <(int pieces, String label, String subtitle)>[
    (3, '3 parça', 'Kolay'),
    (5, '5 parça', 'Orta'),
    (10, '10 parça', 'Zor'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentStudentProfileProvider).asData?.value;
    final studentId =
        profile?.id ?? ref.watch(authStateProvider)?.userId ?? 'demo-student';
    final approved =
        ref.watch(approvedSkillTiersProvider(studentId))[SkillKeys.puzzle] ??
            SkillTier.easy;
    final suggestedPieces = switch (approved) {
      SkillTier.easy => 3,
      SkillTier.medium => 5,
      SkillTier.hard => 10,
    };

    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: const Text('Puzzle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/student'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Parça sayısı seç',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Parçaları sürükleyip doğru yere bırak. '
            'Onaylı seviye: ${approved.label} ($suggestedPieces parça).',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LulunaColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          for (final (n, title, subtitle) in options) ...[
            EducationBigTile(
              title: title,
              subtitle: n == suggestedPieces ? '$subtitle · Onaylı' : subtitle,
              leading:
                  const EducationModuleIcon(icon: Icons.extension_outlined),
              onTap: () => context.push('/student/puzzle/$n'),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class PuzzlePlayScreen extends ConsumerStatefulWidget {
  const PuzzlePlayScreen({super.key, required this.pieceCount});

  final int pieceCount;

  @override
  ConsumerState<PuzzlePlayScreen> createState() => _PuzzlePlayScreenState();
}

class _PuzzlePlayScreenState extends ConsumerState<PuzzlePlayScreen> {
  late PuzzleBoard _board;
  int? _dragging;
  var _celebrate = false;
  var _wrongHint = false;
  var _recorded = false;
  late final DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _board = PuzzleBoard.forPieceCount(widget.pieceCount);
  }

  Future<void> _onDrop(int pieceId, Offset local, Size boardSize) async {
    final slot = _board.nearestSlot(local, boardSize);
    setState(() {
      _dragging = null;
      _wrongHint = false;
      if (slot == null) {
        _board.returnToTray(pieceId);
        return;
      }
      final result = _board.placeCorrectOnly(pieceId, slot);
      if (result == PuzzlePlaceResult.snapped) {
        if (_board.isComplete) {
          _celebrate = true;
        }
      } else {
        _board.returnToTray(pieceId);
        _wrongHint = true;
      }
    });
    if (_celebrate && !_recorded) {
      _recorded = true;
      await _recordCompletion(correct: true);
    }
  }

  Future<void> _recordCompletion({required bool correct}) async {
    final profile = ref.read(currentStudentProfileProvider).asData?.value;
    final studentId =
        profile?.id ?? ref.read(authStateProvider)?.userId ?? 'demo-student';
    final now = DateTime.now();
    final attempt = ActivityAttempt(
      id: 'puzzle_${now.millisecondsSinceEpoch}',
      studentId: studentId,
      skill: SkillArea.puzzle.name,
      category: 'puzzle',
      difficulty: PuzzleBoard.tierForPieceCount(widget.pieceCount).name,
      questionId: 'puzzle-${widget.pieceCount}',
      givenAnswer: 'complete',
      correct: correct,
      attemptedAt: now,
      durationMs: now.difference(_startedAt).inMilliseconds,
    );
    await ref.read(activityAttemptRepositoryProvider).append(attempt);
    ref.read(skillLevelRefreshProvider.notifier).bump();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: Text('${widget.pieceCount} parça'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: () => setState(() {
              _board = PuzzleBoard.forPieceCount(widget.pieceCount);
              _celebrate = false;
              _wrongHint = false;
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
                'Yerleştirilen: ${_board.placedCount()} / ${widget.pieceCount}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 3,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Kaynak sahne oranı (4:3) — hücreleri kare/dar sıkıştırmadan koru.
                    final maxW = constraints.maxWidth;
                    final maxH = constraints.maxHeight;
                    var boardW = maxW;
                    var boardH = boardW * 3 / 4;
                    if (boardH > maxH) {
                      boardH = maxH;
                      boardW = boardH * 4 / 3;
                    }
                    final boardSize = Size(boardW, boardH);
                    return Center(
                      child: SizedBox(
                        width: boardW,
                        height: boardH,
                        child: DragTarget<int>(
                      onWillAcceptWithDetails: (_) => true,
                      onAcceptWithDetails: (details) {
                        final box = context.findRenderObject() as RenderBox?;
                        if (box == null) return;
                        final local = box.globalToLocal(details.offset);
                        _onDrop(details.data, local, boardSize);
                      },
                      builder: (context, candidate, rejected) {
                        return Container(
                          decoration: BoxDecoration(
                            color: LulunaColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: candidate.isNotEmpty
                                  ? LulunaColors.secondary
                                  : LulunaColors.outlineVariant,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CustomPaint(
                              painter: _PuzzleBoardPainter(
                                board: _board,
                                highlight: candidate.isNotEmpty,
                              ),
                              child: Stack(
                                children: [
                                  for (var i = 0; i < _board.pieceCount; i++)
                                    if (_board.slots[i] != null)
                                      _placedPiece(
                                        pieceId: _board.slots[i]!,
                                        slot: i,
                                        boardSize: boardSize,
                                      ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Parçalar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: Builder(
                  builder: (context) {
                    const boardAspect = 4 / 3;
                    final cellAspect =
                        boardAspect * (_board.rows / _board.cols);
                    const pieceH = 80.0;
                    final pieceW = pieceH * cellAspect;
                    return ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final id in _board.tray)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Draggable<int>(
                              data: id,
                              onDragStarted: () =>
                                  setState(() => _dragging = id),
                              onDraggableCanceled: (_, _) =>
                                  setState(() => _dragging = null),
                              feedback: SizedBox(
                                width: pieceW,
                                height: pieceH,
                                child: PuzzlePieceFace(
                                  srcRect: _board.sliceFor(id).srcRect,
                                  label: '${id + 1}',
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: SizedBox(
                                  width: pieceW,
                                  height: pieceH,
                                  child: PuzzlePieceFace(
                                    srcRect: _board.sliceFor(id).srcRect,
                                    label: '${id + 1}',
                                  ),
                                ),
                              ),
                              child: SizedBox(
                                width: pieceW,
                                height: pieceH,
                                child: Opacity(
                                  opacity: _dragging == id ? 0.85 : 1,
                                  child: PuzzlePieceFace(
                                    srcRect: _board.sliceFor(id).srcRect,
                                    label: '${id + 1}',
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              if (_wrongHint) ...[
                const SizedBox(height: 8),
                Text(
                  'Tekrar deneyelim.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: LulunaColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
              if (_celebrate) ...[
                const SizedBox(height: 12),
                PuzzleCelebrateBanner(
                  child: LulunaCard(
                    color: LulunaColors.secondaryContainer,
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tebrikler!',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _placedPiece({
    required int pieceId,
    required int slot,
    required Size boardSize,
  }) {
    final cellW = boardSize.width / _board.cols;
    final cellH = boardSize.height / _board.rows;
    final row = slot ~/ _board.cols;
    final col = slot % _board.cols;
    return Positioned(
      left: col * cellW + 4,
      top: row * cellH + 4,
      width: cellW - 8,
      height: cellH - 8,
      child: Draggable<int>(
        data: pieceId,
        onDragStarted: () {
          setState(() {
            _board.returnToTray(pieceId);
            _dragging = pieceId;
            _celebrate = false;
            _wrongHint = false;
          });
        },
        feedback: SizedBox(
          width: 72,
          height: 72,
          child: PuzzlePieceFace(
            srcRect: _board.sliceFor(pieceId).srcRect,
            label: '${pieceId + 1}',
          ),
        ),
        childWhenDragging: const SizedBox.shrink(),
        child: PuzzlePieceFace(
          srcRect: _board.sliceFor(pieceId).srcRect,
          label: '${pieceId + 1}',
        ),
      ),
    );
  }
}

class _PuzzleBoardPainter extends CustomPainter {
  _PuzzleBoardPainter({required this.board, required this.highlight});

  final PuzzleBoard board;
  final bool highlight;

  @override
  void paint(Canvas canvas, Size size) {
    // Tam sahne (soluk) — hedef referansı.
    PuzzleScenePainter().paint(canvas, size);
    final dim = Paint()..color = Colors.white.withValues(alpha: 0.55);
    canvas.drawRect(Offset.zero & size, dim);

    final cellW = size.width / board.cols;
    final cellH = size.height / board.rows;
    final grid = Paint()
      ..color = LulunaColors.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final empty = Paint()
      ..color = highlight
          ? LulunaColors.secondaryContainer.withValues(alpha: 0.4)
          : LulunaColors.surfaceContainer.withValues(alpha: 0.65);

    for (var i = 0; i < board.pieceCount; i++) {
      final row = i ~/ board.cols;
      final col = i % board.cols;
      final rect = Rect.fromLTWH(col * cellW, row * cellH, cellW, cellH);
      if (board.slots[i] == null) {
        canvas.drawRect(rect.deflate(3), empty);
      }
      canvas.drawRect(rect.deflate(1), grid);
    }
  }

  @override
  bool shouldRepaint(covariant _PuzzleBoardPainter oldDelegate) => true;
}
