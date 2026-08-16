import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/luluna_ui.dart';
import '../domain/dialogue_models.dart';

/// Turn turn diyalog UI — konuşma / iletişim / duygu (Faz 15).
class DialogueRunnerWidget extends StatefulWidget {
  const DialogueRunnerWidget({
    super.key,
    required this.dialogue,
    this.speech,
    this.onComplete,
  });

  final Dialogue dialogue;
  final SpeechRecognitionService? speech;
  final VoidCallback? onComplete;

  @override
  State<DialogueRunnerWidget> createState() => _DialogueRunnerWidgetState();
}

class _DialogueRunnerWidgetState extends State<DialogueRunnerWidget> {
  late DialogueRunnerEngine _engine;
  String? _feedback;
  String? _lastTranscript;
  var _listening = false;
  var _completedNotified = false;

  @override
  void initState() {
    super.initState();
    _engine = DialogueRunnerEngine(widget.dialogue)..skipNone();
  }

  @override
  void didUpdateWidget(covariant DialogueRunnerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dialogue.id != widget.dialogue.id) {
      _engine = DialogueRunnerEngine(widget.dialogue)..skipNone();
      _feedback = null;
      _lastTranscript = null;
      _completedNotified = false;
    }
  }

  void _maybeComplete() {
    if (_engine.isComplete && !_completedNotified) {
      _completedNotified = true;
      widget.onComplete?.call();
    }
  }

  Future<void> _onSpeech() async {
    final keywords = _engine.current.expectedKeywords;
    final speech = widget.speech ??
        MockSpeechRecognitionService(
          scripted: keywords.isNotEmpty ? keywords : const ['elma'],
        );
    setState(() => _listening = true);
    final text = await speech.listenOnce();
    if (!mounted) return;
    final eval = _engine.submitSpeech(text);
    setState(() {
      _listening = false;
      _lastTranscript = text;
      _feedback = eval.feedback;
      if (eval.advance) _engine.skipNone();
    });
    _maybeComplete();
  }

  void _onChoice(String choice) {
    final eval = _engine.submitChoice(choice);
    setState(() {
      _feedback = eval.feedback;
      if (eval.advance) _engine.skipNone();
    });
    _maybeComplete();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (_engine.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeComplete());
      return EducationDoneCard(topic: widget.dialogue.topic);
    }
    final turn = _engine.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (turn.imageUrl != null)
          Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: LulunaColors.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  turn.imageUrl!.contains('sad') ||
                          turn.imageUrl!.contains('emotion')
                      ? Icons.sentiment_dissatisfied_outlined
                      : Icons.image_outlined,
                  size: 40,
                  color: LulunaColors.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  turn.imageUrl!.contains('sad')
                      ? 'Üzgün yüz'
                      : 'Sahne görseli',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Text(
          turn.text,
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        if (turn.responseType == DialogueResponseType.freeSpeech) ...[
          LulunaPrimaryButton(
            label: _listening ? 'Dinleniyor…' : 'Mikrofonla söyle',
            busy: _listening,
            icon: Icons.mic,
            onPressed: _listening ? null : _onSpeech,
          ),
          if (_lastTranscript != null) ...[
            const SizedBox(height: 8),
            Text(
              'Algılanan: “$_lastTranscript”',
              style: textTheme.bodyMedium?.copyWith(
                color: LulunaColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
        if (turn.responseType == DialogueResponseType.choice)
          for (final c in turn.choices) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () => _onChoice(c),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(c, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        if (_feedback != null) ...[
          const SizedBox(height: 12),
          Text(
            _feedback!,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}

class EducationDoneCard extends StatelessWidget {
  const EducationDoneCard({super.key, required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context) {
    return LulunaCard(
      color: LulunaColors.secondaryContainer,
      child: Text(
        'Tebrikler! “$topic” diyaloğu bitti.',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
