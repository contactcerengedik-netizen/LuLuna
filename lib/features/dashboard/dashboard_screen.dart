import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../app/widgets/luluna_ui.dart';
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
    final initial = childName.isNotEmpty ? childName[0].toUpperCase() : 'L';

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(Icons.health_and_safety, color: LulunaColors.primary),
            const SizedBox(width: 10),
            Text(
              'Luluna',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: LulunaColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: LulunaColors.secondaryContainer,
              child: Text(
                initial,
                style: const TextStyle(
                  color: LulunaColors.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            crisisActive
                ? 'Kriz modu aktif — $childName için sakinleştirici içerik devrede.'
                : 'Merhaba! $childName için her şey yolunda görünüyor.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: LulunaColors.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            crisisActive
                ? 'Yapay zeka susturuldu; güvenli ses çıkışları aktif.'
                : 'Bugün genel sakinlik seviyesi takip ediliyor.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: LulunaColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          _SyncStatusBanner(online: online, pendingCount: pendingSync),
          const SizedBox(height: 16),
          _DeviceStatusCard(status: deviceStatus.value),
          const SizedBox(height: 16),
          LulunaCard(
            padding: const EdgeInsets.all(16),
            color: LulunaColors.surfaceContainerLow,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: LulunaColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: LulunaColors.primary.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: LulunaColors.primaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Son asistan olayı',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        logs.value?.firstOrNull?.message ??
                            'Henüz bir olay kaydı yok.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: LulunaColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _BadgesSection(badges: badges),
          const SizedBox(height: 28),
          _CrisisButton(
            active: crisisActive,
            onPressed: () => context.push('/crisis'),
          ),
          const SizedBox(height: 12),
          Text(
            'Kriz modunda yapay zeka susturulur; velinin kayıtlı sesi veya '
            'sakinleştirici müzik devreye girer.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: LulunaColors.outline,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CrisisButton extends StatelessWidget {
  const _CrisisButton({required this.active, required this.onPressed});

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: LulunaColors.crisisRed.withValues(alpha: 0.28),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: LulunaColors.crisisRed,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emergency, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  active ? 'KRİZ MODUNA DÖN' : 'ACİL DURUM / KRİZ MODU',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
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
    final bg = online ? LulunaColors.syncBanner : LulunaColors.errorContainer;
    final fg = online
        ? LulunaColors.onSecondaryContainer
        : LulunaColors.onErrorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            color: fg,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              online
                  ? (pendingCount == 0
                      ? 'Çevrimiçi — loglar senkron'
                      : 'Çevrimiçi — $pendingCount log bekliyor')
                  : 'Çevrimdışı — loglar SQLite\'ta birikiyor, yedek ses aktif',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: fg,
                  ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Başarı rozetleri',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 10),
        if (badges.isEmpty)
          LulunaCard(
            color: LulunaColors.surfaceContainerLow,
            child: Row(
              children: [
                LulunaIconBadge(
                  icon: Icons.military_tech_outlined,
                  backgroundColor: LulunaColors.badgeBg,
                  foregroundColor: LulunaColors.badgeFg,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Henüz rozet yok',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Çocuk sakin kaldığında asistan "Harikasın!" der ve '
                        'buraya bir rozet düşer.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: badges.length.clamp(0, 12),
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final badge = badges[index];
                return Container(
                  width: 128,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: LulunaColors.badgeBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.workspace_premium,
                        color: LulunaColors.badgeFg,
                        size: 32,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        badge.title.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: LulunaColors.badgeFg,
                              letterSpacing: 0.8,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _timeFormat.format(badge.earnedAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: LulunaColors.outline,
                              fontSize: 10,
                            ),
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
    final device = status;
    final connected = device?.isConnected ?? false;
    final battery = device?.batteryPercent ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF0F7F8)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LulunaColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: LulunaColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.visibility,
                  color: connected
                      ? LulunaColors.secondary
                      : LulunaColors.outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gözlük Modülü',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Text(
                      connected ? 'Bağlı' : 'Bekleniyor…',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: LulunaColors.outline,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: connected
                      ? LulunaColors.secondaryContainer
                      : LulunaColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      connected ? Icons.wifi : Icons.signal_wifi_off,
                      size: 16,
                      color: connected
                          ? LulunaColors.onSecondaryContainer
                          : LulunaColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      device?.connection.label ?? 'Bekleniyor…',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: connected
                                ? LulunaColors.onSecondaryContainer
                                : LulunaColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.battery_5_bar,
                size: 20,
                color: LulunaColors.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                device?.batteryLabel ?? '%$battery',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const Spacer(),
              Icon(
                (device?.micAvailable ?? false) ? Icons.mic : Icons.mic_off,
                size: 20,
                color: LulunaColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                (device?.micAvailable ?? false) ? 'Hazır' : 'Kapalı',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: LulunaColors.secondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: const Color(0x4D81D4DC)),
                  FractionallySizedBox(
                    widthFactor: (battery / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            LulunaColors.secondary,
                            LulunaColors.primary,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (connected && device != null) ...[
            const SizedBox(height: 14),
            Divider(
              height: 1,
              color: LulunaColors.outlineVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  device.isProvisioningAp
                      ? 'MODE: AP_SETUP'
                      : 'MODE: ${device.wifiMode == 'unknown' ? '—' : device.wifiMode.toUpperCase()}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: LulunaColors.outline,
                      ),
                ),
                Text(
                  'IP: ${device.ip ?? device.hostname ?? '—'}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: LulunaColors.outline,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
