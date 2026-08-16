import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../app/widgets/luluna_ui.dart';
import '../../../core/routine/routine_engine.dart';
import '../../../data/models/skill_level.dart';
import '../../../data/providers.dart';
import '../../education/domain/activity_models.dart';
import '../../education/presentation/activity_session_controller.dart';

class RoutinePlayScreen extends ConsumerStatefulWidget {
  const RoutinePlayScreen({super.key});

  @override
  ConsumerState<RoutinePlayScreen> createState() => _RoutinePlayScreenState();
}

class _RoutinePlayScreenState extends ConsumerState<RoutinePlayScreen> {
  late RoutineEngine _engine;
  Timer? _timer;
  var _secondsLeft = 0;
  late final DateTime _startedAt;
  var _recorded = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _engine = RoutineEngine(
      title: 'Sabah rutini',
      steps: RoutineEngine.morningSample(),
    );
    _armTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _armTimer() {
    _timer?.cancel();
    _secondsLeft = (_engine.current.estimatedMinutes * 15).clamp(10, 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) _secondsLeft--;
      });
    });
  }

  Future<void> _completeStep() async {
    final done = _engine.completeCurrent();
    if (!done) return;
    setState(() {});
    if (_engine.isComplete) {
      _timer?.cancel();
      await _record();
    } else {
      _armTimer();
      try {
        await ref.read(speechServiceProvider).speak(_engine.current.label);
      } catch (_) {}
    }
  }

  Future<void> _record() async {
    if (_recorded) return;
    _recorded = true;
    final profile = ref.read(currentStudentProfileProvider).asData?.value;
    final studentId =
        profile?.id ?? ref.read(authStateProvider)?.userId ?? 'demo-student';
    final now = DateTime.now();
    await ref.read(activityAttemptRepositoryProvider).append(
          ActivityAttempt(
            id: 'routine_${now.millisecondsSinceEpoch}',
            studentId: studentId,
            skill: SkillArea.dailyLife.name,
            category: 'routine',
            difficulty: SkillTier.easy.name,
            questionId: 'morning-routine',
            givenAnswer: 'complete',
            correct: true,
            attemptedAt: now,
            durationMs: now.difference(_startedAt).inMilliseconds,
          ),
        );
  }

  IconData _icon(String name) => switch (name) {
        'bedtime' => Icons.bedtime_outlined,
        'cleaning_services' => Icons.cleaning_services_outlined,
        'checkroom' => Icons.checkroom_outlined,
        'backpack' => Icons.backpack_outlined,
        _ => Icons.circle_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final pair = _engine.firstThen;
    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: Text(_engine.title),
        actions: [
          IconButton(
            tooltip: 'Sıfırla',
            onPressed: () {
              setState(() {
                _engine.reset();
                _recorded = false;
                _armTimer();
              });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _engine.isComplete
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const EducationStatusPanel(
                      title: 'Rutin bitti!',
                      body: 'Tüm adımları tamamladın.',
                      icon: Icons.celebration_outlined,
                    ),
                    const Spacer(),
                    LulunaPrimaryButton(
                      label: 'Ana sayfa',
                      onPressed: () => context.go('/student'),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      value: _engine.progress,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kalan ~${_engine.remainingMinutes} dk · '
                      'Zamanlayıcı: $_secondsLeft sn',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'First → Then',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: LulunaColors.primary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _FirstThenCard(
                              title: 'ŞİMDİ',
                              step: pair.first,
                              icon: _icon(pair.first.iconName),
                              highlight: true,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.arrow_forward, size: 32),
                          ),
                          Expanded(
                            child: pair.then == null
                                ? const _FirstThenCard(
                                    title: 'SONRA',
                                    emptyLabel: 'Bitti',
                                    highlight: false,
                                  )
                                : _FirstThenCard(
                                    title: 'SONRA',
                                    step: pair.then,
                                    icon: _icon(pair.then!.iconName),
                                    highlight: false,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 72,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final s in _engine.steps)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(
                                avatar: Icon(
                                  _engine.isStepDone(s.id)
                                      ? Icons.check_circle
                                      : _icon(s.iconName),
                                  size: 18,
                                ),
                                label: Text(s.label),
                              ),
                            ),
                        ],
                      ),
                    ),
                    LulunaPrimaryButton(
                      label: 'Adımı tamamla',
                      onPressed: _completeStep,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _FirstThenCard extends StatelessWidget {
  const _FirstThenCard({
    required this.title,
    this.step,
    this.icon,
    this.emptyLabel,
    required this.highlight,
  });

  final String title;
  final RoutineStep? step;
  final IconData? icon;
  final String? emptyLabel;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight
            ? LulunaColors.secondaryContainer
            : LulunaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight ? LulunaColors.primary : LulunaColors.outlineVariant,
          width: highlight ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: LulunaColors.primary,
                ),
          ),
          const SizedBox(height: 16),
          if (step != null) ...[
            Icon(icon ?? Icons.circle, size: 48),
            const SizedBox(height: 12),
            Text(
              step!.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ] else
            Text(
              emptyLabel ?? '—',
              style: Theme.of(context).textTheme.titleMedium,
            ),
        ],
      ),
    );
  }
}
