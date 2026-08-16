import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../core/speech/platform_speech_recognition.dart';
import '../../../data/models/skill_level.dart';
import '../../../data/providers.dart';
import '../../dialogue/domain/dialogue_models.dart';
import '../../dialogue/presentation/dialogue_runner_widget.dart';
import '../../education/domain/activity_models.dart';
import '../../education/presentation/activity_session_controller.dart';
import '../data/social_dialogue_catalog.dart';

final speechRecognitionProvider = Provider<SpeechRecognitionService>((ref) {
  return PlatformSpeechRecognitionService(
    fallback: MockSpeechRecognitionService(scripted: const ['elma', 'su', 'üzgün']),
  );
});

class SocialSpeechHubScreen extends StatelessWidget {
  const SocialSpeechHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: const Text('Konuşma / Sosyal'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/student'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Diyalog seç',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aynı diyalog motoru — telaffuz, iletişim, duygu.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: LulunaColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          for (final m in SocialSpeechModule.values) ...[
            EducationBigTile(
              title: m.label,
              subtitle: m.subtitle,
              leading: EducationModuleIcon(
                icon: switch (m) {
                  SocialSpeechModule.pronunciation => Icons.record_voice_over,
                  SocialSpeechModule.communication => Icons.chat_bubble_outline,
                  SocialSpeechModule.emotion => Icons.sentiment_satisfied_alt,
                },
              ),
              onTap: () => context.push('/student/speech/${m.name}'),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class SocialSpeechPlayScreen extends ConsumerStatefulWidget {
  const SocialSpeechPlayScreen({super.key, required this.module});

  final SocialSpeechModule module;

  @override
  ConsumerState<SocialSpeechPlayScreen> createState() =>
      _SocialSpeechPlayScreenState();
}

class _SocialSpeechPlayScreenState
    extends ConsumerState<SocialSpeechPlayScreen> {
  late Dialogue _dialogue;
  late final DateTime _startedAt;
  var _recorded = false;
  Key _runnerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _dialogue = widget.module.dialogue();
  }

  Future<void> _onComplete() async {
    if (_recorded) return;
    _recorded = true;
    final profile = ref.read(currentStudentProfileProvider).asData?.value;
    final studentId =
        profile?.id ?? ref.read(authStateProvider)?.userId ?? 'demo-student';
    final now = DateTime.now();
    await ref.read(activityAttemptRepositoryProvider).append(
          ActivityAttempt(
            id: 'speech_${now.millisecondsSinceEpoch}',
            studentId: studentId,
            skill: SkillArea.communication.name,
            category: widget.module.name,
            difficulty: _dialogue.level,
            questionId: _dialogue.id,
            givenAnswer: 'dialogue_complete',
            correct: true,
            attemptedAt: now,
            durationMs: now.difference(_startedAt).inMilliseconds,
          ),
        );
  }

  void _restart() {
    setState(() {
      _recorded = false;
      _dialogue = widget.module.dialogue();
      _runnerKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stt = ref.watch(speechRecognitionProvider);
    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: Text(widget.module.label),
        actions: [
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
          child: DialogueRunnerWidget(
            key: _runnerKey,
            dialogue: _dialogue,
            speech: stt,
            onComplete: _onComplete,
          ),
        ),
      ),
    );
  }
}
