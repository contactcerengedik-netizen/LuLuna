import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../data/models/education_question.dart';
import '../../../data/models/skill_keys.dart';
import '../../../data/models/skill_level.dart';
import '../../education/domain/activity_engine.dart';
import '../../education/presentation/widgets/question_player.dart';
import '../domain/ai_content_models.dart';
import 'ai_content_providers.dart';

class StudentAiActivitiesScreen extends ConsumerWidget {
  const StudentAiActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(publishedAiActivitiesProvider);

    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: const Text('Öğretmen Etkinlikleri'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/student'),
        ),
      ),
      body: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: EducationStatusPanel(
                title: 'Henüz yok',
                body:
                    'Öğretmen AI ile etkinlik oluşturup onayladığında burada görünür.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final a in items) ...[
                  EducationBigTile(
                    title: a.structured.questionText,
                    subtitle: a.structured.instruction,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => StudentAiActivityPlayScreen(activity: a),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class StudentAiActivityPlayScreen extends StatefulWidget {
  const StudentAiActivityPlayScreen({super.key, required this.activity});

  final TeacherAiActivity activity;

  @override
  State<StudentAiActivityPlayScreen> createState() =>
      _StudentAiActivityPlayScreenState();
}

class _StudentAiActivityPlayScreenState
    extends State<StudentAiActivityPlayScreen> {
  late final ActivityEngine _engine;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    final s = widget.activity.structured;
    final imageUrl = widget.activity.image.assetPath;
    final skillKey = widget.activity.skillKey;
    final category = skillKey != null
        ? (SkillKeys.toCategory(skillKey) ?? s.activityType)
        : s.activityType;
    final skill = skillKey != null
        ? SkillKeys.areaFor(skillKey)
        : (s.activityType.startsWith('math')
            ? SkillArea.mathematics
            : SkillArea.language);
    final q = EducationQuestion(
      id: widget.activity.id,
      category: category,
      skill: skill,
      difficulty: s.difficulty,
      instruction: s.instruction,
      questionText: s.questionText,
      imageUrl: imageUrl,
      solutionImageUrl: imageUrl,
      choices: s.choices.isEmpty ? [s.answer] : s.choices,
      correctAnswer: s.answer,
      explanation: s.explanation,
      metadata: {
        'type': 'multipleChoice',
        'source': widget.activity.source,
        if (skillKey != null) 'skillKey': skillKey,
        'sceneVisual': {
          'template': 'scene_5n1k',
          'caption': s.questionText,
          'objects': [
            for (final o in s.objects) '${o['type'] ?? 'nesne'}',
          ],
          'character': s.characters.isNotEmpty
              ? '${s.characters.first['name'] ?? ''}'
              : null,
        },
      },
    );
    _engine = ActivityEngine(studentId: 'student', questions: [q])
      ..markQuestionStarted();
  }

  void _answer(String value) {
    final eval = _engine.submit(value, advanceOnWrong: false);
    setState(() {
      _feedback = eval.correct ? 'Tebrikler!' : 'Tekrar deneyelim.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: const Text('Etkinlik'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.activity.image.description != null)
            EducationStatusPanel(
              title: 'Görsel ipucu',
              body: widget.activity.image.description!,
              icon: Icons.image_outlined,
            ),
          const SizedBox(height: 16),
          if (_engine.isComplete)
            EducationStatusPanel(
              title: 'Bitti',
              body: _feedback ?? 'Etkinlik tamam.',
              icon: Icons.check_circle_outline,
            )
          else
            QuestionPlayer(
              question: _engine.current,
              onAnswer: _answer,
            ),
          if (_feedback != null && !_engine.isComplete) ...[
            const SizedBox(height: 12),
            Text(_feedback!),
          ],
        ],
      ),
    );
  }
}
