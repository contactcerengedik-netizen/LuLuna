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
import 'widgets/question_player.dart';

class ActivitySessionScreen extends ConsumerStatefulWidget {
  const ActivitySessionScreen({
    super.key,
    required this.skill,
    required this.category,
    required this.difficulty,
    required this.title,
    required this.exitRoute,
    this.count = 5,
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
      ref.read(activitySessionProvider.notifier).start(
            ActivityLaunchArgs(
              skill: widget.skill,
              category: widget.category,
              difficulty: widget.difficulty,
              count: widget.count,
              assignmentId: widget.assignmentId,
            ),
          );
    });
  }

  Future<void> _onAnswer(String answer) async {
    if (_busy) return;
    setState(() => _busy = true);
    final eval =
        await ref.read(activitySessionProvider.notifier).submit(answer);
    if (!mounted) return;
    setState(() => _busy = false);
    if (eval == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          eval.correct
              ? 'Tebrikler! ${eval.explanation ?? ''}'.trim()
              : 'Tekrar deneyelim. ${eval.explanation ?? ''}'.trim(),
        ),
        backgroundColor:
            eval.correct ? LulunaColors.secondary : LulunaColors.error,
        duration: Duration(milliseconds: eval.correct ? 900 : 1400),
      ),
    );
    if (!eval.correct) {
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
        body: session == null
            ? const Center(child: CircularProgressIndicator())
            : session.finished && session.result != null
                ? _ResultBody(
                    result: session.result!,
                    voiceOn: accessibility.voiceInstructions,
                    onDone: () {
                      ref.read(activitySessionProvider.notifier).reset();
                      context.go(widget.exitRoute);
                    },
                    onRetry: () {
                      ref.read(activitySessionProvider.notifier).start(
                            ActivityLaunchArgs(
                              skill: widget.skill,
                              category: widget.category,
                              difficulty: widget.difficulty,
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
