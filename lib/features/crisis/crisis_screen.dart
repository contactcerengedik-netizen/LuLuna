import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/navigation.dart';
import '../../data/models/crisis_state.dart';
import '../../data/providers.dart';

/// Kriz / acil durum modu. AI susturulur; veli sesi veya sakinleştirici
/// müzik çalınır.
class CrisisScreen extends ConsumerStatefulWidget {
  const CrisisScreen({super.key});

  @override
  ConsumerState<CrisisScreen> createState() => _CrisisScreenState();
}

class _CrisisScreenState extends ConsumerState<CrisisScreen> {
  @override
  void initState() {
    super.initState();
    // Ekran açılır açılmaz kriz modunu aktifleştir (AI susturulur).
    Future.microtask(() => ref.read(crisisModeProvider.notifier).activate());
  }

  Future<void> _endCrisis() async {
    await ref.read(crisisModeProvider.notifier).deactivate();
    if (mounted) lulunaGoBack(context);
  }

  @override
  Widget build(BuildContext context) {
    final childName = ref.watch(appStateProvider).profile?.name ?? 'çocuğunuz';
    final crisis = ref.watch(crisisModeProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.primaryContainer,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 0,
        title: const Text('Kriz Modu'),
        leading: IconButton(
          tooltip: 'Geri',
          icon: const Icon(Icons.arrow_back),
          onPressed: _endCrisis,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.self_improvement,
                size: 96,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(height: 24),
              Text(
                'Kriz Modu Aktif',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Yapay zeka susturuldu. $childName için sakinleştirici '
                'içerik seçin.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
              ),
              const SizedBox(height: 40),
              _CrisisOption(
                icon: Icons.record_voice_over,
                title: 'Veli sesi telkinleri',
                subtitle: crisis.playing == CrisisAudioSource.parentVoice
                    ? 'Çalıyor…'
                    : 'Önceden kaydedilmiş sakinleştirici telkin',
                selected: crisis.playing == CrisisAudioSource.parentVoice,
                onTap: () => ref
                    .read(crisisModeProvider.notifier)
                    .playSource(CrisisAudioSource.parentVoice),
              ),
              const SizedBox(height: 12),
              _CrisisOption(
                icon: Icons.music_note,
                title: 'Sakinleştirici müzik',
                subtitle: crisis.playing == CrisisAudioSource.calmingMusic
                    ? 'Döngüde çalıyor…'
                    : 'Yumuşak ambient melodi',
                selected: crisis.playing == CrisisAudioSource.calmingMusic,
                onTap: () => ref
                    .read(crisisModeProvider.notifier)
                    .playSource(CrisisAudioSource.calmingMusic),
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.onPrimaryContainer,
                  foregroundColor: scheme.primaryContainer,
                ),
                onPressed: _endCrisis,
                icon: const Icon(Icons.check_circle),
                label: const Text('Krizi Sonlandır'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrisisOption extends StatelessWidget {
  const _CrisisOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: selected
          ? scheme.surface
          : scheme.surface.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? BorderSide(color: scheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: Icon(icon, color: scheme.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(
          selected ? Icons.pause_circle_filled : Icons.play_circle_outline,
        ),
        onTap: onTap,
      ),
    );
  }
}
