import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Canlı Asistan Akışı'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: LulunaColors.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Env.hasGeminiKey
                          ? Icons.auto_awesome
                          : Icons.flip_camera_ios_outlined,
                      size: 18,
                      color: LulunaColors.onSecondaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      Env.hasGeminiKey ? 'Gemini' : 'Demo modu',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: LulunaColors.onSecondaryContainer,
                          ),
                    ),
                  ],
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
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: LulunaColors.surfaceContainerLow,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Gözlem simüle et: "Önde büyük bir köpek…"',
                        isDense: true,
                        filled: true,
                        fillColor: LulunaColors.surfaceContainerLowest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide(
                            color: LulunaColors.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide(
                            color: LulunaColors.outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(
                            color: LulunaColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendObservation(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: LulunaColors.primaryContainer,
                    shape: const CircleBorder(),
                    elevation: 4,
                    shadowColor:
                        LulunaColors.primaryContainer.withValues(alpha: 0.35),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _sending ? null : _sendObservation,
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: _sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ),
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
          const Icon(
            Icons.smart_toy_outlined,
            size: 48,
            color: LulunaColors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Asistan akışı bekleniyor…',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: LulunaColors.onSurfaceVariant,
                ),
          ),
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
        LogType.observation => (Icons.visibility_outlined, 'Gözlem'),
        LogType.intervention => (Icons.record_voice_over, 'Yönlendirme'),
        LogType.praise => (Icons.stars, 'Pekiştireç'),
        LogType.system => (Icons.settings, 'Sistem'),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, label) = _typeInfo;
    final isIntervention = log.type == LogType.intervention;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isIntervention
                ? LulunaColors.secondaryContainer
                : LulunaColors.surfaceContainerHigh,
            child: Icon(
              icon,
              size: 20,
              color: isIntervention
                  ? LulunaColors.onSecondaryContainer
                  : LulunaColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isIntervention
                    ? LulunaColors.secondaryContainer.withValues(alpha: 0.4)
                    : LulunaColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isIntervention
                      ? LulunaColors.secondaryContainer
                      : LulunaColors.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: isIntervention
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isIntervention
                                  ? LulunaColors.onSecondaryContainer
                                  : LulunaColors.onSurfaceVariant,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        _timeFormat.format(log.timestamp),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isIntervention
                                  ? LulunaColors.onSecondaryContainer
                                      .withValues(alpha: 0.7)
                                  : LulunaColors.outline,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isIntervention
                              ? const Color(0xFF004F55)
                              : LulunaColors.onSurface,
                        ),
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
