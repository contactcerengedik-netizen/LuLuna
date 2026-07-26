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
  static const _crisisBg = Color(0xFFBDEEFA);
  static const _crisisDark = Color(0xFF001F26);
  static const _endButton = Color(0xFF022B30);

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

    return Scaffold(
      backgroundColor: _crisisBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: _crisisDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Kriz Modu',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _crisisDark,
                fontWeight: FontWeight.w700,
              ),
        ),
        leading: IconButton(
          tooltip: 'Geri',
          icon: const Icon(Icons.arrow_back, color: _crisisDark),
          onPressed: _endCrisis,
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: MediaQuery.sizeOf(context).height * 0.18,
            left: MediaQuery.sizeOf(context).width * 0.1,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.sizeOf(context).height * 0.22,
            right: MediaQuery.sizeOf(context).width * 0.05,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFA8EEFB).withValues(alpha: 0.35),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _crisisDark.withValues(alpha: 0.05),
                            ),
                            child: const Icon(
                              Icons.self_improvement,
                              size: 84,
                              color: _crisisDark,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Kriz Modu Aktif',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: _crisisDark,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Yapay zeka susturuldu. $childName için '
                            'sakinleştirici içerik seçin.',
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: _crisisDark.withValues(alpha: 0.8),
                                    ),
                          ),
                          const SizedBox(height: 32),
                          _CrisisOption(
                            icon: Icons.record_voice_over,
                            title: 'Veli sesi telkinleri',
                            subtitle:
                                crisis.playing == CrisisAudioSource.parentVoice
                                    ? 'Çalıyor…'
                                    : 'Önceden kaydedilmiş sakinleştirici telkin',
                            selected:
                                crisis.playing == CrisisAudioSource.parentVoice,
                            onTap: () => ref
                                .read(crisisModeProvider.notifier)
                                .playSource(CrisisAudioSource.parentVoice),
                          ),
                          const SizedBox(height: 12),
                          _CrisisOption(
                            icon: Icons.music_note,
                            title: 'Sakinleştirici müzik',
                            subtitle:
                                crisis.playing == CrisisAudioSource.calmingMusic
                                    ? 'Döngüde çalıyor…'
                                    : 'Yumuşak ambient melodi',
                            selected: crisis.playing ==
                                CrisisAudioSource.calmingMusic,
                            onTap: () => ref
                                .read(crisisModeProvider.notifier)
                                .playSource(CrisisAudioSource.calmingMusic),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              '"AI asistanı şu an pasif durumda. Sistem sadece '
                              'güvenli ses çıkışlarına izin veriyor."',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: _crisisDark.withValues(alpha: 0.7),
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _endButton,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _endCrisis,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Krizi Sonlandır'),
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

  static const _crisisDark = Color(0xFF001F26);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: selected ? 0.65 : 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? _crisisDark.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.3),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: _crisisDark,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: _crisisDark,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _crisisDark.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _crisisDark.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(
                  selected ? Icons.pause : Icons.play_arrow,
                  color: _crisisDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
