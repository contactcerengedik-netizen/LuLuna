import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../app/widgets/luluna_ui.dart';
import '../../../core/memory/memory_engine.dart';
import '../../../data/models/skill_level.dart';
import '../../../data/providers.dart';
import '../../education/domain/activity_models.dart';
import '../../education/presentation/activity_session_controller.dart';

enum MemoryMode {
  match('Kart eşleştirme'),
  flash('Kısa süreli bellek');

  const MemoryMode(this.label);
  final String label;
}

class MemoryHubScreen extends StatelessWidget {
  const MemoryHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: const Text('Hafıza / Dikkat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/student'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Bir oyun seç',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Eşleştir veya kısa bakıp hatırla.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: LulunaColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          for (final mode in MemoryMode.values) ...[
            EducationBigTile(
              title: mode.label,
              leading: EducationModuleIcon(
                icon: mode == MemoryMode.match
                    ? Icons.grid_view
                    : Icons.visibility_outlined,
              ),
              onTap: () => context.push('/student/memory/${mode.name}'),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class MemoryPlayScreen extends ConsumerStatefulWidget {
  const MemoryPlayScreen({super.key, required this.mode});

  final MemoryMode mode;

  @override
  ConsumerState<MemoryPlayScreen> createState() => _MemoryPlayScreenState();
}

class _MemoryPlayScreenState extends ConsumerState<MemoryPlayScreen> {
  late MemoryEngine _engine;
  late SkillTier _tier;
  late final DateTime _startedAt;
  bool _recorded = false;
  String? _feedback;
  List<MemoryCardFace> _flashChoices = const [];
  int? _pendingA;
  int? _pendingB;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _tier = SkillTier.easy;
    _engine = MemoryEngine(
      faces: MemoryEngine.defaultPool(),
      pairCount: _pairCountFor(_tier),
      displayDurationMs: _durationFor(_tier),
    );
    if (widget.mode == MemoryMode.flash) {
      _startFlash();
    }
  }

  int _pairCountFor(SkillTier t) => switch (t) {
        SkillTier.easy => 3,
        SkillTier.medium => 4,
        SkillTier.hard => 6,
      };

  int _durationFor(SkillTier t) => switch (t) {
        SkillTier.easy => 4000,
        SkillTier.medium => 3000,
        SkillTier.hard => 2000,
      };

  int _flashCountFor(SkillTier t) => switch (t) {
        SkillTier.easy => 2,
        SkillTier.medium => 3,
        SkillTier.hard => 4,
      };

  void _startFlash() {
    _engine.startFlash(
      pool: MemoryEngine.defaultPool(),
      count: _flashCountFor(_tier),
    );
    _flashChoices = const [];
    _feedback = null;
    Future<void>.delayed(
      Duration(milliseconds: _engine.displayDurationMs),
      () {
        if (!mounted) return;
        setState(() {
          _engine.endFlashReveal();
          _flashChoices = _engine.flashChoices();
        });
      },
    );
  }

  void _restart() {
    setState(() {
      _recorded = false;
      _feedback = null;
      _pendingA = null;
      _pendingB = null;
      _engine.reset(
        faces: MemoryEngine.defaultPool(),
        pairCount: _pairCountFor(_tier),
        displayDurationMs: _durationFor(_tier),
      );
      if (widget.mode == MemoryMode.flash) {
        _startFlash();
      }
    });
  }

  Future<void> _persist({
    required String questionId,
    required bool correct,
    required String answer,
  }) async {
    if (_recorded) return;
    _recorded = true;
    final profile = ref.read(currentStudentProfileProvider).asData?.value;
    final studentId =
        profile?.id ?? ref.read(authStateProvider)?.userId ?? 'demo-student';
    final now = DateTime.now();
    await ref.read(activityAttemptRepositoryProvider).append(
          ActivityAttempt(
            id: 'mem_${now.millisecondsSinceEpoch}',
            studentId: studentId,
            skill: SkillArea.visualPerception.name,
            category: widget.mode.name,
            difficulty: _tier.name,
            questionId: questionId,
            givenAnswer: answer,
            correct: correct,
            attemptedAt: now,
            durationMs: now.difference(_startedAt).inMilliseconds,
            deviationScore: _engine.averageReactionMs,
          ),
        );
  }

  Future<void> _onFlip(int index) async {
    final result = _engine.flip(index);
    setState(() {});
    if (result == null) return;

    if (!result.matched) {
      // Find the two open unmatched cards
      final open = [
        for (var i = 0; i < _engine.cards.length; i++)
          if (_engine.cards[i].faceUp && !_engine.cards[i].matched) i,
      ];
      if (open.length >= 2) {
        _pendingA = open[0];
        _pendingB = open[1];
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        setState(() {
          _engine.closeMismatched(_pendingA!, _pendingB!);
          _pendingA = null;
          _pendingB = null;
          _feedback = 'Eşleşmedi — tepki ${result.reactionMs} ms';
        });
      }
      return;
    }

    setState(() {
      _feedback = result.boardComplete
          ? 'Tamam! Ort. tepki: '
              '${_engine.averageReactionMs?.toStringAsFixed(0) ?? '-'} ms'
          : 'Eşleşti! (${result.reactionMs} ms)';
    });
    if (result.boardComplete) {
      await _persist(
        questionId: 'match-${_engine.pairCount}',
        correct: true,
        answer: 'complete',
      );
    }
  }

  Future<void> _onFlashAnswer(MemoryCardFace face) async {
    final result = _engine.answerFlash(face.pairId);
    setState(() {
      _feedback = result.correct
          ? 'Doğru! Tepki ${result.reactionMs} ms'
          : 'Yanlış. Doğrusu: ${_engine.flashTarget?.label}';
    });
    if (result.correct) {
      await _persist(
        questionId: 'flash-${_engine.flashTarget?.pairId}',
        correct: true,
        answer: face.pairId,
      );
    }
  }

  IconData _icon(String name) => switch (name) {
        'apple' => Icons.apple,
        'sports_soccer' => Icons.sports_soccer,
        'pets' => Icons.pets,
        'wb_sunny' => Icons.wb_sunny_outlined,
        'star' => Icons.star_outline,
        'menu_book' => Icons.menu_book_outlined,
        'directions_car' => Icons.directions_car_outlined,
        'water' => Icons.water_drop_outlined,
        _ => Icons.circle_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: Text(widget.mode.label),
        actions: [
          PopupMenuButton<SkillTier>(
            initialValue: _tier,
            onSelected: (t) {
              _tier = t;
              _restart();
            },
            itemBuilder: (_) => [
              for (final t in SkillTier.values)
                PopupMenuItem(value: t, child: Text(t.label)),
            ],
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: _restart,
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
                widget.mode == MemoryMode.match
                    ? 'Kartları çevir, eşleri bul. '
                        '(${_engine.pairCount} çift)'
                    : _engine.flashRevealing
                        ? 'Bak ve hatırla… (${_engine.displayDurationMs ~/ 1000} sn)'
                        : 'Hangisini gördün?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: LulunaColors.primary,
                    ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: widget.mode == MemoryMode.match
                    ? _matchGrid()
                    : _flashBody(),
              ),
              if (_feedback != null) ...[
                const SizedBox(height: 8),
                LulunaCard(
                  color: _feedback!.startsWith('Tamam') ||
                          _feedback!.startsWith('Doğru') ||
                          _feedback!.startsWith('Eşleşti')
                      ? LulunaColors.secondaryContainer
                      : LulunaColors.surfaceContainer,
                  child: Text(
                    _feedback!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
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

  Widget _matchGrid() {
    final n = _engine.cards.length;
    final cols = n <= 6 ? 3 : 4;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: n,
      itemBuilder: (context, i) {
        final card = _engine.cards[i];
        final show = card.faceUp || card.matched;
        return Material(
          color: show
              ? LulunaColors.secondaryContainer
              : LulunaColors.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: card.matched || _engine.inputLocked
                ? null
                : () => _onFlip(i),
            child: Center(
              child: show
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_icon(card.face.iconName), size: 36),
                        const SizedBox(height: 4),
                        Text(
                          card.face.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    )
                  : const Icon(Icons.help_outline, size: 36),
            ),
          ),
        );
      },
    );
  }

  Widget _flashBody() {
    if (_engine.flashRevealing) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.center,
        children: [
          for (final f in _engine.flashShown)
            Container(
              width: 100,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LulunaColors.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(_icon(f.iconName), size: 40),
                  const SizedBox(height: 8),
                  Text(
                    f.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    return ListView(
      children: [
        for (final f in _flashChoices) ...[
          EducationBigTile(
            title: f.label,
            leading: Icon(_icon(f.iconName)),
            onTap: () => _onFlashAnswer(f),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
