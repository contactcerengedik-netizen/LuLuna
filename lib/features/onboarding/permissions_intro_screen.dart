import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/navigation.dart';
import '../../app/theme.dart';
import '../../app/widgets/luluna_ui.dart';
import '../../data/providers.dart';

/// Onboarding sonrası yumuşak izin karşılama ekranı.
class PermissionsIntroScreen extends ConsumerStatefulWidget {
  const PermissionsIntroScreen({super.key});

  @override
  ConsumerState<PermissionsIntroScreen> createState() =>
      _PermissionsIntroScreenState();
}

class _PermissionsIntroScreenState
    extends ConsumerState<PermissionsIntroScreen> {
  var _busy = false;
  String? _status;

  Future<void> _request() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    final snap = await ref.read(permissionsServiceProvider).requestAll();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = [
        if (snap.microphone.isGranted) 'Mikrofon',
        if (snap.notification.isGranted) 'Bildirim',
        if (snap.bluetooth.isGranted) 'Bluetooth',
      ].isEmpty
          ? 'İzinler verilmedi; Ayarlar’dan sonra açabilirsiniz.'
          : 'Verildi: ${[
              if (snap.microphone.isGranted) 'Mikrofon',
              if (snap.notification.isGranted) 'Bildirim',
              if (snap.bluetooth.isGranted) 'Bluetooth',
            ].join(', ')}';
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) _continueFlow();
  }

  Future<void> _skip() async {
    await ref.read(permissionsServiceProvider).markIntroSeen();
    if (mounted) _continueFlow();
  }

  void _continueFlow() {
    // Router: rol/profil/eşleşme durumuna göre doğru yere yönlendirir.
    context.go('/onboarding/role');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: lulunaAppBar(
        context,
        title: 'Cihaz İzinleri',
        fallbackLocation: '/auth',
        onBack: () async {
          await ref.read(authStateProvider.notifier).signOut();
          if (context.mounted) context.go('/auth');
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: LulunaColors.tertiary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.shield,
                        size: 64,
                        color: LulunaColors.primaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Luluna’nın çalışması için',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bluetooth (kemik iletimli ses), bildirimler (arka plan '
                    'izleme) ve mikrofon (veli kriz kaydı) izinlerine '
                    'ihtiyacımız var. Bunları şimdi açıklayıcı şekilde '
                    'isteyeceğiz.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: LulunaColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const _PermRow(
                    icon: Icons.mic,
                    title: 'Mikrofon',
                    subtitle: 'Kriz anı için veli ses kaydı',
                  ),
                  const SizedBox(height: 16),
                  const _PermRow(
                    icon: Icons.notifications,
                    title: 'Bildirimler',
                    subtitle: 'Ön plan servisi ve durum uyarıları',
                  ),
                  const SizedBox(height: 16),
                  const _PermRow(
                    icon: Icons.bluetooth,
                    title: 'Bluetooth',
                    subtitle: 'Gözlük / kemik iletimli kulaklık',
                  ),
                  if (_status != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _status!,
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 32),
                  Center(
                    child: Container(
                      width: 64,
                      height: 4,
                      decoration: BoxDecoration(
                        color: LulunaColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LulunaPrimaryButton(
                    label: 'İzinleri ver',
                    busy: _busy,
                    onPressed: _busy ? null : _request,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy ? null : _skip,
                    child: const Text('Şimdilik geç'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  const _PermRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return LulunaCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          LulunaIconBadge(
            icon: icon,
            size: 48,
            backgroundColor:
                LulunaColors.primaryContainer.withValues(alpha: 0.1),
            foregroundColor: LulunaColors.primaryContainer,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: LulunaColors.primary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
