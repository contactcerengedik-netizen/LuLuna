import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../app/widgets/luluna_ui.dart';
import '../../../data/models/education_question.dart';
import '../../../data/models/sequence_question.dart';
import '../../../data/models/skill_level.dart';
import '../../../data/providers.dart';
import '../../education/domain/activity_models.dart';
import '../../education/domain/scene_visual_spec.dart';
import '../../education/presentation/activity_session_controller.dart';
import '../../education/presentation/widgets/question_player.dart';
import '../data/routine_sequence_catalog.dart';

/// Rutin sıralama — sürükle-bırak (SequenceQuestion / OrderQuestionView).
class RoutinePlayScreen extends ConsumerStatefulWidget {
  const RoutinePlayScreen({super.key, this.routineId});

  final String? routineId;

  @override
  ConsumerState<RoutinePlayScreen> createState() => _RoutinePlayScreenState();
}

class _RoutinePlayScreenState extends ConsumerState<RoutinePlayScreen> {
  RoutineSequenceActivity? _activity;
  EducationQuestion? _question;
  var _done = false;
  var _recorded = false;
  late final DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final id = widget.routineId ??
        GoRouterState.of(context).uri.queryParameters['id'] ??
        'morning';
    final activity = RoutineSequenceCatalog.byId(id) ??
        RoutineSequenceCatalog.builtins.first;
    final seq = activity.shuffledSequence();
    setState(() {
      _activity = activity;
      _done = false;
      _recorded = false;
      _question = EducationQuestion(
        id: 'routine-seq-${activity.id}',
        category: 'routine_sequencing',
        skill: SkillArea.dailyLife,
        difficulty: SkillTier.easy,
        instruction: 'Adımları doğru sıraya koy (sürükle-bırak).',
        questionText: activity.title,
        imageUrl: 'mock://routine/${activity.id}',
        solutionImageUrl: 'mock://routine/${activity.id}/solution',
        choices: seq.items,
        correctAnswer: SequenceQuestion.encode(seq.correctItems),
        explanation: seq.correctItems.join(' → '),
        metadata: {
          ...seq.toMap(),
          'visualCards': true,
          'cardIcons': {
            for (final s in activity.steps) s.label: s.iconName,
          },
          'sceneVisual': SceneVisualSpec(
            template: 'bedtime',
            caption: activity.title,
            objects: activity.labelsInOrder,
          ).toMap(),
        },
      );
    });
  }

  Future<void> _onAnswer(String answer) async {
    final q = _question;
    final activity = _activity;
    if (q == null || activity == null) return;
    final ok = q.isCorrect(answer);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sıra henüz doğru değil — tekrar dene.')),
      );
      return;
    }
    setState(() => _done = true);
    if (_recorded) return;
    _recorded = true;
    final profile = ref.read(currentStudentProfileProvider).asData?.value;
    final studentId =
        profile?.id ?? ref.read(authStateProvider)?.userId ?? 'demo-student';
    final now = DateTime.now();
    await ref.read(activityAttemptRepositoryProvider).append(
          ActivityAttempt(
            id: 'routine_seq_${now.millisecondsSinceEpoch}',
            studentId: studentId,
            skill: SkillArea.dailyLife.name,
            category: 'routine_sequencing',
            difficulty: SkillTier.easy.name,
            questionId: activity.id,
            givenAnswer: answer,
            correct: true,
            attemptedAt: now,
            durationMs: now.difference(_startedAt).inMilliseconds,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final q = _question;
    final activity = _activity;
    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: Text(activity?.title ?? 'Rutin Sıralama'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/student/daily-life'),
        ),
        actions: [
          IconButton(
            tooltip: 'Karıştır',
            onPressed: _load,
            icon: const Icon(Icons.shuffle),
          ),
        ],
      ),
      body: SafeArea(
        child: q == null
            ? const Center(child: CircularProgressIndicator())
            : _done
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        EducationStatusPanel(
                          title: 'Harika!',
                          body: q.explanation ?? 'Doğru sıra.',
                          icon: Icons.celebration_outlined,
                        ),
                        const Spacer(),
                        LulunaPrimaryButton(
                          label: 'Başka rutin',
                          onPressed: () =>
                              context.go('/student/daily-life'),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Rutin Sıralama',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: LulunaColors.primary,
                                ),
                      ),
                      const SizedBox(height: 12),
                      OrderQuestionView(
                        key: ValueKey(q.id + q.choices.join()),
                        question: q,
                        onAnswer: _onAnswer,
                      ),
                    ],
                  ),
      ),
    );
  }
}
