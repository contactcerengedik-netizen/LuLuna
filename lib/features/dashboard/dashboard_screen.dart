import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/achievement_badge.dart';
import '../../data/models/device_status.dart';
import '../../data/providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final deviceStatus = ref.watch(deviceStatusProvider);
    final logs = ref.watch(assistantLogsProvider);
    final badges = ref.watch(badgesProvider);
    final crisisActive = ref.watch(crisisModeProvider).active;
    final online = ref.watch(isOnlineProvider).value ?? true;
    final pendingSync = ref.watch(pendingSyncCountProvider).value ?? 0;
    final childName = appState.profile?.name ?? 'Çocuğunuz';

    return Scaffold(
      appBar: AppBar(title: const Text('Luluna Paneli')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            crisisActive
                ? 'Kriz modu aktif — $childName için sakinleştirici içerik devrede.'
                : 'Merhaba! $childName için her şey yolunda görünüyor.',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _SyncStatusBanner(online: online, pendingCount: pendingSync),
          const SizedBox(height: 12),
          _DeviceStatusCard(status: deviceStatus.value),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: ListTile(
              leading: const Icon(Icons.forum_outlined),
              title: const Text('Son asistan olayı'),
              subtitle: Text(
                logs.value?.firstOrNull?.message ??
                    'Henüz bir olay kaydı yok.',
              ),
            ),
          ),
          const SizedBox(height: 20),
          _BadgesSection(badges: badges),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              minimumSize: const Size.fromHeight(72),
            ),
            onPressed: () => context.push('/crisis'),
            icon: const Icon(Icons.emergency_share, size: 32),
            label: Text(
              crisisActive ? 'KRİZ MODUNA DÖN' : 'ACİL DURUM / KRİZ MODU',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kriz modunda yapay zeka susturulur; velinin kayıtlı sesi veya '
            'sakinleştirici müzik devreye girer.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SyncStatusBanner extends StatelessWidget {
  const _SyncStatusBanner({
    required this.online,
    required this.pendingCount,
  });

  final bool online;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = online
        ? scheme.secondaryContainer
        : scheme.errorContainer;
    final onColor = online
        ? scheme.onSecondaryContainer
        : scheme.onErrorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            color: onColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              online
                  ? (pendingCount == 0
                      ? 'Çevrimiçi — loglar senkron'
                      : 'Çevrimiçi — $pendingCount log bekliyor')
                  : 'Çevrimdışı — loglar SQLite\'ta birikiyor, yedek ses aktif',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: onColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgesSection extends StatelessWidget {
  const _BadgesSection({required this.badges});

  final List<AchievementBadge> badges;

  static final _timeFormat = DateFormat.Hm();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Başarı rozetleri',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (badges.isEmpty)
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            child: const ListTile(
              leading: Icon(Icons.military_tech_outlined),
              title: Text('Henüz rozet yok'),
              subtitle: Text(
                'Çocuk sakin kaldığında asistan "Harikasın!" der ve '
                'buraya bir rozet düşer.',
              ),
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: badges.length.clamp(0, 12),
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final badge = badges[index];
                return Container(
                  width: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.military_tech, color: scheme.tertiary),
                      const Spacer(),
                      Text(
                        badge.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Text(
                        _timeFormat.format(badge.earnedAt),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _DeviceStatusCard extends StatelessWidget {
  const _DeviceStatusCard({this.status});

  final DeviceStatus? status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final connected = status?.isConnected ?? false;
    final battery = status?.batteryPercent ?? 0;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  connected ? Icons.visibility : Icons.visibility_off,
                  color: connected ? scheme.primary : scheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  'Gözlük Modülü',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    status?.connection.label ?? 'Bekleniyor…',
                  ),
                  avatar: Icon(
                    connected ? Icons.wifi : Icons.signal_wifi_off,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.battery_5_bar, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: LinearProgressIndicator(
                    value: battery / 100,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(status?.batteryLabel ?? '%$battery'),
              ],
            ),
            if (connected) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    status?.micAvailable == true
                        ? Icons.mic
                        : Icons.mic_off,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status?.micAvailable == true
                        ? 'Mikrofon hazır'
                        : 'Mikrofon yok / kapalı',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
