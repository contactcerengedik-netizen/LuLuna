import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../app/widgets/luluna_ui.dart';
import '../../core/env.dart';
import '../../data/models/user_role.dart';
import '../../data/providers.dart';
import '../../data/repositories/auth_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _openPrivacy(BuildContext context) async {
    final uri = Uri.parse(Env.privacyPolicyUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gizlilik sayfası açılamadı: $uri')),
      );
    }
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final data = await ref
          .read(appStateProvider.notifier)
          .exportPersonalData();
      await Clipboard.setData(
        ClipboardData(text: const JsonEncoder.withIndent('  ').convert(data)),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veri özeti panoya kopyalandı (JSON)')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Dışa aktarma başarısız: $e')));
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı sil?'),
        content: const Text(
          'Hesabınız, KVKK kaydınız, eşleşmeleriniz ve buluttaki '
          'asistan loglarınız kalıcı olarak silinir. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hesabı sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(appStateProvider.notifier).reset();
      await ref.read(authStateProvider.notifier).deleteAccount();
      if (context.mounted) context.go('/auth');
    } on AuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hesap silinemedi: $e')));
      }
    }
  }

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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const LulunaSectionLabel('Hesap ve Rol'),
          LulunaSettingsGroup(
            children: [
              LulunaSettingsTile(
                icon: Icons.account_circle_outlined,
                title: 'Hesap',
                subtitle:
                    auth == null ? '-' : '${auth.email} · ${auth.provider.name}',
              ),
              LulunaSettingsTile(
                icon: Icons.badge_outlined,
                title: 'Rol',
                subtitle: appState.role?.label ?? '-',
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (isParent) ...[
            const LulunaSectionLabel('Ebeveyn Kontrolleri'),
            LulunaSettingsGroup(
              children: [
                LulunaSettingsTile(
                  icon: Icons.face,
                  title: 'Çocuk profili',
                  subtitle: profile == null
                      ? '-'
                      : '${profile.name} · ${profile.triggers.length} tetikleyici '
                            '· ${profile.voiceTone.label} ses tonu',
                  trailing: const Icon(
                    Icons.edit,
                    color: LulunaColors.outline,
                    size: 20,
                  ),
                  iconBackground: LulunaColors.primaryContainer,
                  iconColor: Colors.white,
                  onTap: () => context.push('/onboarding/profile'),
                ),
                LulunaSettingsTile(
                  icon: Icons.qr_code_2,
                  title: 'Terapist davet kodu',
                  subtitle: pairing.myInviteCode == null
                      ? 'Üretip terapistinize verin'
                      : 'Aktif: ${pairing.myInviteCode}',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: LulunaColors.outline,
                  ),
                  iconBackground: LulunaColors.primaryContainer,
                  iconColor: Colors.white,
                  onTap: () => context.push('/pairing'),
                ),
                LulunaSettingsTile(
                  icon: Icons.sensors,
                  title: 'Cihaz bağlantısı',
                  subtitle: 'ESP32-CAM, BLE ses çıkışı, izleme',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: LulunaColors.outline,
                  ),
                  iconBackground: LulunaColors.primaryContainer,
                  iconColor: Colors.white,
                  onTap: () => context.push('/device'),
                ),
              ],
            ),
            const SizedBox(height: 28),
          ],
          if (isTherapist) ...[
            const LulunaSectionLabel('Terapist'),
            LulunaSettingsGroup(
              children: [
                if (profile != null)
                  LulunaSettingsTile(
                    icon: Icons.child_care,
                    title: 'Çocuk profili',
                    subtitle:
                        '${profile.name} · ${profile.triggers.length} tetikleyici '
                        '· ${profile.voiceTone.label} ses tonu',
                    iconBackground: LulunaColors.primaryContainer,
                    iconColor: Colors.white,
                  ),
                LulunaSettingsTile(
                  icon: Icons.link,
                  title: 'Hasta eşleşmesi',
                  subtitle: pairing.hasTherapistLink
                      ? '${pairing.linkedChildName ?? 'Çocuk'} · ${pairing.linkedCode}'
                      : 'Henüz eşleşme yok',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: LulunaColors.outline,
                  ),
                  iconBackground: LulunaColors.primaryContainer,
                  iconColor: Colors.white,
                  onTap: () => context.push('/pairing'),
                ),
                LulunaSettingsTile(
                  icon: Icons.edit_note,
                  title: 'Terapist kuralları',
                  subtitle: appState.therapistRules.isEmpty
                      ? 'Henüz kural yok'
                      : '${appState.therapistRules.rules.length} kural',
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: LulunaColors.outline,
                  ),
                  iconBackground: LulunaColors.primaryContainer,
                  iconColor: Colors.white,
                  onTap: () => context.push('/prompt/rules'),
                ),
              ],
            ),
            const SizedBox(height: 28),
          ],
          const LulunaSectionLabel('Sistem ve Veri'),
          LulunaSettingsGroup(
            children: [
              LulunaSettingsTile(
                icon: Icons.terminal,
                title: 'System prompt önizleme',
                subtitle: 'Profil verilerinden üretilen AI yönlendirme metni',
                trailing: const Icon(
                  Icons.chevron_right,
                  color: LulunaColors.outline,
                ),
                iconBackground: LulunaColors.surfaceContainer,
                iconColor: LulunaColors.tertiary,
                onTap: () => context.push('/prompt/preview'),
              ),
              LulunaSettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Gizlilik politikası',
                subtitle: Env.privacyPolicyUrl,
                trailing: const Icon(
                  Icons.open_in_new,
                  color: LulunaColors.outline,
                  size: 20,
                ),
                iconBackground: LulunaColors.surfaceContainer,
                iconColor: LulunaColors.tertiary,
                onTap: () => _openPrivacy(context),
              ),
              LulunaSettingsTile(
                icon: Icons.download_outlined,
                title: 'Verilerimi dışa aktar',
                subtitle: 'KVKK taşınabilirlik — JSON panoya kopyalanır',
                iconBackground: LulunaColors.surfaceContainer,
                iconColor: LulunaColors.tertiary,
                onTap: () => _exportData(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const LulunaSectionLabel(
            'Tehlikeli Bölge',
            color: LulunaColors.error,
          ),
          Container(
            decoration: BoxDecoration(
              color: LulunaColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: LulunaColors.errorContainer.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                LulunaSettingsTile(
                  icon: Icons.logout,
                  title: 'Çıkış yap',
                  subtitle: 'Oturumu kapatır; KVKK onayı saklanır',
                  iconBackground: LulunaColors.surfaceContainerLow,
                  iconColor: LulunaColors.onSurfaceVariant,
                  onTap: () async {
                    await ref.read(authStateProvider.notifier).signOut();
                    if (context.mounted) context.go('/auth');
                  },
                ),
                Divider(
                  height: 1,
                  indent: 68,
                  color: LulunaColors.errorContainer.withValues(alpha: 0.35),
                ),
                LulunaSettingsTile(
                  icon: Icons.restart_alt,
                  title: 'Verileri sıfırla',
                  subtitle:
                      'Rol, profil, eşleşme ve kuralları siler (oturum kalır)',
                  iconBackground: LulunaColors.errorContainer,
                  iconColor: LulunaColors.error,
                  titleColor: LulunaColors.error,
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
                Divider(
                  height: 1,
                  indent: 68,
                  color: LulunaColors.errorContainer.withValues(alpha: 0.35),
                ),
                LulunaSettingsTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Hesabı sil',
                  subtitle:
                      'KVKK silme hakkı — bulut ve yerel hesap verisi kalıcı silinir',
                  iconBackground: LulunaColors.error,
                  iconColor: Colors.white,
                  titleColor: LulunaColors.error,
                  onTap: () => _deleteAccount(context, ref),
                ),
              ],
            ),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 32),
            Text(
              'Debug derlemesi',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: LulunaColors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mock izleme ve test hesapları açıktır',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: LulunaColors.onSurfaceVariant.withValues(alpha: 0.35),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
