import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/navigation.dart';
import '../../app/theme.dart';
import '../../app/widgets/luluna_ui.dart';
import '../../data/models/user_role.dart';
import '../../data/providers.dart';

/// Onboarding — isteğe bağlı ses / bildirim izinleri.
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
    try {
      final snap = await ref.read(permissionsServiceProvider).requestAll();
      if (!mounted) return;
      final granted = [
        if (snap.microphone.isGranted) 'Mikrofon',
        if (snap.notification.isGranted) 'Bildirim',
      ];
      setState(() {
        _status = granted.isEmpty
            ? 'İzin verilmedi; Ayarlar’dan sonra açabilirsiniz. Devam ediliyor…'
            : 'Verildi: ${granted.join(', ')}';
      });
    } catch (_) {
      // Servis zaten yutar; yine de güvenli tarafta kal.
      await ref.read(permissionsServiceProvider).markIntroSeen();
      if (!mounted) return;
      setState(() {
        _status =
            'İzinler alınamadı; şimdilik geçiliyor. İstediğiniz zaman '
            'Ayarlar’dan açabilirsiniz.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) _continueFlow();
  }

  Future<void> _skip() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(permissionsServiceProvider).markIntroSeen();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted) _continueFlow();
  }

  /// Rol seçim ekranına gitme — o ekran oturumu kapatır.
  /// Rol zaten auth’ta atanır; ana ekrana yönlendir.
  void _continueFlow() {
    final role = ref.read(appStateProvider).role;
    if (role == UserRole.teacher || role == UserRole.admin) {
      context.go('/teacher');
    } else {
      context.go('/student');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: lulunaAppBar(
        context,
        title: 'İzinler',
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
                        Icons.shield_outlined,
                        size: 64,
                        color: LulunaColors.primaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Daha iyi bir deneyim için',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sesli yönerge ve hatırlatmalar için isteğe bağlı izinler. '
                    'Şimdilik geçebilirsiniz.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: LulunaColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const _PermRow(
                    icon: Icons.volume_up_outlined,
                    title: 'Mikrofon / ses',
                    subtitle: 'Sesli yönergeler (isteğe bağlı)',
                  ),
                  const SizedBox(height: 16),
                  const _PermRow(
                    icon: Icons.notifications_outlined,
                    title: 'Bildirimler',
                    subtitle: 'Çalışma hatırlatmaları (isteğe bağlı)',
                  ),
                  if (_status != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _status!,
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall,
                    ),
                  ],
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
        ],
      ),
    );
  }
}
