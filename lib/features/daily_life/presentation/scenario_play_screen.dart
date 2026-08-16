import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../data/providers.dart';
import '../data/scenario_catalog.dart';
import '../domain/scenario_engine.dart';
import '../domain/scenario_models.dart';

class ScenarioPlayScreen extends ConsumerStatefulWidget {
  const ScenarioPlayScreen({super.key, required this.scenarioId});

  final String scenarioId;

  @override
  ConsumerState<ScenarioPlayScreen> createState() => _ScenarioPlayScreenState();
}

class _ScenarioPlayScreenState extends ConsumerState<ScenarioPlayScreen> {
  ScenarioEngine? _engine;
  String? _feedback;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    final scenario = ScenarioCatalog.byId(widget.scenarioId) ??
        ScenarioCatalog.restaurant;
    _engine = ScenarioEngine(scenario);
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakNpc());
  }

  Future<void> _speakNpc() async {
    final engine = _engine;
    if (engine == null || !mounted) return;
    final step = engine.current;
    if (step.type == ScenarioStepType.npcSpeak ||
        step.type == ScenarioStepType.complete) {
      final text = step.text;
      if (text.isEmpty) return;
      try {
        await ref.read(speechServiceProvider).speak(text);
      } catch (_) {}
    }
  }

  Future<void> _onContinue() async {
    final engine = _engine;
    if (engine == null || _busy) return;
    setState(() {
      _busy = true;
      _feedback = null;
    });
    engine.continueNarration();
    setState(() => _busy = false);
    await _speakNpc();
    setState(() {});
  }

  Future<void> _onChoice(String id) async {
    final engine = _engine;
    if (engine == null || _busy) return;
    setState(() => _busy = true);
    final result = engine.submitChoice(id);
    setState(() {
      _feedback = result.message;
      _busy = false;
    });
    if (result.accepted) {
      await _speakNpc();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = _engine;
    if (engine == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final scenario = engine.scenario;
    final step = engine.current;
    final accessibility = ref.watch(educationAccessibilityProvider);

    return EducationAccessibilityScope(
      textScale: accessibility.textScaleFactor,
      highContrast: accessibility.highContrast,
      child: Scaffold(
        backgroundColor: LulunaColors.surface,
        appBar: AppBar(
          title: Text(scenario.title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              ref.read(speechServiceProvider).stop();
              context.go('/student/daily-life');
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: engine.isComplete || step.type == ScenarioStepType.complete
                ? _CompleteView(
                    text: step.type == ScenarioStepType.complete
                        ? step.text
                        : 'Senaryo tamam!',
                    wrongTries: engine.wrongTries,
                    onHome: () {
                      ref.read(speechServiceProvider).stop();
                      context.go('/student/daily-life');
                    },
                    onRetry: () {
                      setState(() {
                        _engine = ScenarioEngine(scenario);
                        _feedback = null;
                      });
                      _speakNpc();
                    },
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Adım ${engine.index + 1} / ${engine.total}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (engine.index + 1) / engine.total,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 20),
                      _NpcBubble(step: step, npcRole: scenario.npcRole),
                      if (_feedback != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _feedback!,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _feedback == 'Doğru!'
                                ? LulunaColors.secondary
                                : LulunaColors.error,
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (step.type == ScenarioStepType.npcSpeak)
                        EducationBigTile(
                          title: 'Devam',
                          leading: const EducationModuleIcon(
                            icon: Icons.arrow_forward,
                          ),
                          onTap: _busy ? () {} : _onContinue,
                        )
                      else ...[
                        for (final c in step.choices) ...[
                          EducationBigTile(
                            title: c.label,
                            trailing: step.type ==
                                    ScenarioStepType.paymentChoice
                                ? const Icon(Icons.payments_outlined, size: 28)
                                : const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 28,
                                  ),
                            onTap: _busy ? () {} : () => _onChoice(c.id),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _NpcBubble extends StatelessWidget {
  const _NpcBubble({required this.step, required this.npcRole});

  final ScenarioStep step;
  final String npcRole;

  @override
  Widget build(BuildContext context) {
    final isNpc = step.type == ScenarioStepType.npcSpeak ||
        step.type == ScenarioStepType.complete;
    final speaker = step.speaker ?? (isNpc ? npcRole : 'Sen');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isNpc
            ? LulunaColors.secondaryContainer
            : LulunaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LulunaColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            speaker,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: LulunaColors.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            step.text,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }
}

class _CompleteView extends StatelessWidget {
  const _CompleteView({
    required this.text,
    required this.wrongTries,
    required this.onHome,
    required this.onRetry,
  });

  final String text;
  final int wrongTries;
  final VoidCallback onHome;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EducationStatusPanel(
          title: 'Bravo!',
          body: '$text\nYanlış deneme: $wrongTries',
          icon: Icons.celebration_outlined,
        ),
        const Spacer(),
        EducationBigTile(title: 'Tekrar oyna', onTap: onRetry),
        const SizedBox(height: 12),
        EducationBigTile(title: 'Senaryolara dön', onTap: onHome),
      ],
    );
  }
}
