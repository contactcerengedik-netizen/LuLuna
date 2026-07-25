import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/env.dart';
import '../../data/models/assistant_log.dart';
import '../../data/providers.dart';

/// Yapay zekanın gözlem ve müdahalelerinin mesajlaşma ekranı gibi aktığı
/// canlı akış. Alttaki giriş alanı, ESP32 kamerası bağlanana kadar
/// gözlemleri elle simüle etmeyi sağlar (uçtan uca pipeline testi).
class LiveAssistantScreen extends ConsumerStatefulWidget {
  const LiveAssistantScreen({super.key});

  @override
  ConsumerState<LiveAssistantScreen> createState() =>
      _LiveAssistantScreenState();
}

class _LiveAssistantScreenState extends ConsumerState<LiveAssistantScreen> {
  final _controller = TextEditingController();
  var _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendObservation() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      await ref.read(assistantRepositoryProvider).processObservation(text);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(assistantLogsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Canlı Asistan Akışı'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Chip(
                visualDensity: VisualDensity.compact,
                avatar: Icon(
                  Env.hasGeminiKey ? Icons.auto_awesome : Icons.science,
                  size: 16,
                ),
                label: Text(
                  Env.hasGeminiKey ? 'Gemini' : 'Demo modu',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: logs.when(
              data: (items) => items.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, index) =>
                          _LogBubble(log: items[index]),
                    ),
              loading: () => const _EmptyState(),
              error: (error, _) => Center(child: Text('Akış hatası: $error')),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              color: scheme.surfaceContainerLow,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Gözlem simüle et: "Önde büyük bir köpek…"',
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendObservation(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _sendObservation,
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          const Text('Asistan akışı bekleniyor…'),
        ],
      ),
    );
  }
}

class _LogBubble extends StatelessWidget {
  const _LogBubble({required this.log});

  final AssistantLog log;

  static final _timeFormat = DateFormat.Hms();

  (IconData, String) get _typeInfo => switch (log.type) {
    LogType.observation => (Icons.remove_red_eye_outlined, 'Gözlem'),
    LogType.intervention => (Icons.record_voice_over, 'Yönlendirme'),
    LogType.praise => (Icons.stars, 'Pekiştireç'),
    LogType.system => (Icons.settings_suggest, 'Sistem'),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, label) = _typeInfo;
    final isIntervention = log.type == LogType.intervention;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isIntervention
                ? scheme.primaryContainer
                : scheme.surfaceContainerHigh,
            child: Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isIntervention
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        _timeFormat.format(log.timestamp),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(log.message),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
