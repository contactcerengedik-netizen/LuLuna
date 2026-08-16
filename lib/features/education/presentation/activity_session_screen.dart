import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../app/widgets/luluna_ui.dart';
import '../../../data/models/skill_level.dart';
import '../../../data/providers.dart';
import '../domain/activity_models.dart';
import 'activity_session_controller.dart';
import 'widgets/education_question_visual.dart';
import 'widgets/question_player.dart';

class ActivitySessionScreen extends ConsumerStatefulWidget {
  const ActivitySessionScreen({
    super.key,
    required this.skill,
    required this.category,
    required this.difficulty,
    required this.title,
    required this.exitRoute,
    this.count = 10,
    this.assignmentId,
  });

  final SkillArea skill;
  final String category;
  final SkillTier difficulty;
  final String title;
  final String exitRoute;
  final int count;
  final String? assignmentId;

  @override
  ConsumerState<ActivitySessionScreen> createState() =>
      _ActivitySessionScreenState();
}

class _ActivitySessionScreenState extends ConsumerState<ActivitySessionScreen> {
  var _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref.read(activitySessionProvider.notifier).start(
              ActivityLaunchArgs(
                skill: widget.skill,
                category: widget.category,
                difficulty: widget.difficulty,
                count: widget.count,
                assignmentId: widget.assignmentId,
              ),
            ),
      );
    });
  }

  Future<void> _onAnswer(String answer) async {
    if (_busy) return;
    setState(() => _busy = true);
    final asked = ref.read(activitySessionProvider)?.current;
    final eval =
        await ref.read(activitySessionProvider.notifier).submit(answer);
    if (!mounted) return;
    setState(() => _busy = false);
    if (eval == null || asked == null) return;

    // Doğru cevapta panel açma — doğrudan sonraki soruya geç.
    if (eval.correct) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tekrar bakalım',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: LulunaColors.error,
                    ),
              ),
              const SizedBox(height: 12),
              EducationQuestionVisual(
                question: asked,
                mode: EducationVisualMode.solution,
              ),
              const SizedBox(height: 12),
              Text(
                eval.explanation ?? 'Doğru cevap: ${asked.correctAnswer}',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        );
      },
    );

    if (mounted) {
      ref.read(activitySessionProvider.notifier).clearFeedback();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(activitySessionProvider);
    final accessibility = ref.watch(educationAccessibilityProvider);

    return EducationAccessibilityScope(
      textScale: accessibility.textScaleFactor,
      highContrast: accessibility.highContrast,
      child: Scaffold(
        backgroundColor: LulunaColors.surface,
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Çık',
            onPressed: () {
              ref.read(activitySessionProvider.notifier).reset();
              context.go(widget.exitRoute);
            },
          ),
        ),
        body: session == null || session.preparing || !session.isReady
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        session?.preparingMessage ??
                            'Sorular ve görseller hazırlanıyor…',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              )
            : session.finished && session.result != null
                ? _ResultBody(
                    result: session.result!,
                    voiceOn: accessibility.voiceInstructions,
                    onDone: () {
                      ref.read(activitySessionProvider.notifier).reset();
                      context.go(widget.exitRoute);
                    },
                    onRetry: () {
                      unawaited(
                        ref.read(activitySessionProvider.notifier).start(
                              ActivityLaunchArgs(
                                skill: widget.skill,
                                category: widget.category,
                                difficulty: widget.difficulty,
                                count: widget.count,
                                assignmentId: widget.assignmentId,
                              ),
                            ),
                      );
                    },
                  )
                : SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Soru ${session.index + 1} / ${session.total}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            SkillTierChip(tier: widget.difficulty),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: session.total == 0
                              ? 0
                              : session.index / session.total,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        if (accessibility.voiceInstructions) ...[
                          const SizedBox(height: 12),
                          const VoiceGuidanceHint(enabled: true),
                        ],
                        const SizedBox(height: 20),
                        QuestionPlayer(
                          key: ValueKey(session.current.id),
                          question: session.current,
                          onAnswer: _onAnswer,
                          enabled: !_busy,
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({
    required this.result,
    required this.voiceOn,
    required this.onDone,
    required this.onRetry,
  });

  final ActivitySessionResult result;
  final bool voiceOn;
  final VoidCallback onDone;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EducationStatusPanel(
            title: 'Bravo!',
            body:
                '${result.correctCount}/${result.total} doğru\n'
                'Yanlış deneme: ${result.wrongCount}\n'
                'Başarı: ${result.scorePercent.toStringAsFixed(0)}%',
            icon: Icons.emoji_events_outlined,
          ),
          if (voiceOn) ...[
            const SizedBox(height: 12),
            const VoiceGuidanceHint(enabled: true),
          ],
          const Spacer(),
          LulunaPrimaryButton(label: 'Tekrar çöz', onPressed: onRetry),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onDone,
            child: const Text('Kategorilere dön'),
          ),
        ],
      ),
    );
  }
}
