import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/user_role.dart';
import '../../data/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final profile = appState.profile;
    final auth = ref.watch(authStateProvider);
    final pairing = ref.watch(pairingStateProvider);
    final isParent = appState.role == UserRole.parent;
    final isTherapist = appState.role == UserRole.therapist;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('Hesap'),
            subtitle: Text(
              auth == null
                  ? '-'
                  : '${auth.email} · ${auth.provider.name}',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Rol'),
            subtitle: Text(appState.role?.label ?? '-'),
          ),
          if (isParent || profile != null)
            ListTile(
              leading: const Icon(Icons.child_care),
              title: const Text('Çocuk profili'),
              subtitle: Text(
                profile == null
                    ? '-'
                    : '${profile.name} · ${profile.triggers.length} tetikleyici '
                          '· ${profile.voiceTone.label} ses tonu',
              ),
              trailing: isParent ? const Icon(Icons.edit) : null,
              onTap: isParent
                  ? () => context.push('/onboarding/profile')
                  : null,
            ),
          if (isParent)
            ListTile(
              leading: const Icon(Icons.qr_code_2),
              title: const Text('Terapist davet kodu'),
              subtitle: Text(
                pairing.myInviteCode == null
                    ? 'Üretip terapistinize verin'
                    : 'Aktif: ${pairing.myInviteCode}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/pairing'),
            ),
          if (isTherapist)
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Hasta eşleşmesi'),
              subtitle: Text(
                pairing.hasTherapistLink
                    ? '${pairing.linkedChildName ?? 'Çocuk'} · ${pairing.linkedCode}'
                    : 'Henüz eşleşme yok',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/pairing'),
            ),
          ListTile(
            leading: const Icon(Icons.terminal),
            title: const Text('System prompt önizleme'),
            subtitle: const Text(
              'Profil verilerinden üretilen AI yönlendirme metni',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/prompt/preview'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_note),
            title: const Text('Terapist kuralları'),
            subtitle: Text(
              appState.therapistRules.isEmpty
                  ? 'Henüz kural yok'
                  : '${appState.therapistRules.rules.length} kural',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/prompt/rules'),
          ),
          if (isParent)
            ListTile(
              leading: const Icon(Icons.sensors),
              title: const Text('Cihaz bağlantısı'),
              subtitle: const Text('ESP32-CAM, BLE ses çıkışı, izleme'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/device'),
            ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Çıkış yap'),
            subtitle: const Text('Oturumu kapatır; KVKK onayı saklanır'),
            onTap: () async {
              await ref.read(authStateProvider.notifier).signOut();
              if (context.mounted) context.go('/auth');
            },
          ),
          ListTile(
            leading: Icon(
              Icons.restart_alt,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Verileri sıfırla',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: const Text(
              'Rol, profil, eşleşme ve kuralları siler (oturum kalır)',
            ),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Emin misiniz?'),
                  content: const Text(
                    'Rol seçimi, çocuk profili, eşleşme ve terapist '
                    'kuralları silinecek.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Vazgeç'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sıfırla'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
              await ref.read(appStateProvider.notifier).reset();
              if (context.mounted) context.go('/onboarding/role');
            },
          ),
        ],
      ),
    );
  }
}
