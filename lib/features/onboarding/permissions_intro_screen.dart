import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/navigation.dart';
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.shield_moon_outlined, size: 72, color: scheme.primary),
              const SizedBox(height: 20),
              Text(
                'Luluna’nın çalışması için',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Bluetooth (kemik iletimli ses), bildirimler (arka plan '
                'izleme) ve mikrofon (veli kriz kaydı) izinlerine ihtiyacımız '
                'var. Bunları şimdi açıklayıcı şekilde isteyeceğiz.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              const _PermRow(
                icon: Icons.mic_outlined,
                title: 'Mikrofon',
                subtitle: 'Kriz anı için veli ses kaydı',
              ),
              const _PermRow(
                icon: Icons.notifications_outlined,
                title: 'Bildirimler',
                subtitle: 'Ön plan servisi ve durum uyarıları',
              ),
              const _PermRow(
                icon: Icons.bluetooth,
                title: 'Bluetooth',
                subtitle: 'Gözlük / kemik iletimli kulaklık',
              ),
              if (_status != null) ...[
                const SizedBox(height: 12),
                Text(_status!, textAlign: TextAlign.center),
              ],
              const Spacer(),
              FilledButton(
                onPressed: _busy ? null : _request,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('İzinleri ver'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : _skip,
                child: const Text('Şimdilik geç'),
              ),
            ],
          ),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(icon),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
