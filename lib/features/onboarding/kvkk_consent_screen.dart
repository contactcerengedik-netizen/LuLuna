import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../app/widgets/luluna_ui.dart';
import '../../data/models/auth_session.dart';
import '../../data/providers.dart';

/// İlk giriş sonrası KVKK / aydınlatma açık rızası (bir kez).
class KvkkConsentScreen extends ConsumerStatefulWidget {
  const KvkkConsentScreen({super.key});

  @override
  ConsumerState<KvkkConsentScreen> createState() => _KvkkConsentScreenState();
}

class _KvkkConsentScreenState extends ConsumerState<KvkkConsentScreen> {
  var _accepted = false;
  var _busy = false;
  String? _error;

  Future<void> _continue() async {
    if (!_accepted) {
      setState(() => _error = 'Devam etmek için onay kutusunu işaretleyin.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final kvkk = KvkkConsent(
        privacyNotice: true,
        dataProcessing: true,
        healthData: true,
        micCamera: true,
        consentedAt: DateTime.now(),
      );
      await ref.read(authStateProvider.notifier).updateKvkk(kvkk);
      if (mounted) context.go('/onboarding/permissions');
    } catch (e) {
      setState(() => _error = 'Onay kaydedilemedi: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final canSubmit = _accepted && !_busy;

    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: const Text('Açık Rıza'),
        leading: IconButton(
          tooltip: 'Çıkış',
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await ref.read(authStateProvider.notifier).signOut();
            if (context.mounted) context.go('/auth');
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
                children: [
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: LulunaColors.primary.withValues(alpha: 0.05),
                        border: Border.all(
                          color: LulunaColors.primary.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.security,
                        size: 48,
                        color: LulunaColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'KVKK ve Aydınlatma',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'İlk girişinizde bir kez onayınızı alıyoruz. Sonraki '
                    'girişlerde tekrar sorulmaz. Mikrofon, bildirim ve '
                    'Bluetooth izinleri bir sonraki adımda istenecek.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: LulunaColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),
                  LulunaCard(
                    padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _accepted,
                          onChanged: (v) =>
                              setState(() => _accepted = v ?? false),
                          activeColor: LulunaColors.primaryContainer,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'Aydınlatma metnini okudum; kişisel / sağlık '
                              'verilerimin işlenmesine açık rıza veriyorum.',
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Aydınlatma metni',
                          icon: const Icon(Icons.info_outline),
                          color: LulunaColors.onSurfaceVariant,
                          onPressed: () => _showNotice(context),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: LulunaColors.error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _TrustMiniCard(
                          icon: Icons.lock_open,
                          title: 'Güvenli Veri',
                          subtitle: 'Uçtan uca şifreleme',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _TrustMiniCard(
                          icon: Icons.verified_user,
                          title: 'Tam Şeffaflık',
                          subtitle: 'İstediğiniz an iptal',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: LulunaColors.surface.withValues(alpha: 0.9),
              ),
              child: FilledButton(
                onPressed: canSubmit ? _continue : (_busy ? null : _continue),
                style: canSubmit
                    ? null
                    : FilledButton.styleFrom(
                        backgroundColor: LulunaColors.surfaceContainerHighest,
                        foregroundColor: LulunaColors.onSurfaceVariant,
                        disabledBackgroundColor:
                            LulunaColors.surfaceContainerHighest,
                        disabledForegroundColor:
                            LulunaColors.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                        elevation: 0,
                      ),
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Onayla ve devam et'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotice(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aydınlatma Metni (özet)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Luluna, otizm spektrumundaki çocuklara destek olmak için '
                'giyilebilir kamera/mikrofon verilerini ve uygulama içi '
                'etkileşim kayıtlarını işler. Veriler; kriz müdahalesi, '
                'veli bilgilendirme ve (eşleştirme sonrası) terapist '
                'raporlaması amacıyla kullanılır.\n\n'
                'Kayıtlar mümkün olduğunca cihazda ve şifreli kanallarda '
                'tutulur. Üçüncü taraflara (yapay zeka API) yalnızca '
                'gerekli gözlem metinleri gönderilir. Haklarınız: '
                'erişim, düzeltme, silme ve rızayı geri çekme.\n\n'
                'Bu metin yasal danışman onaylı nihai metinle '
                'değiştirilecektir.',
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tamam'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustMiniCard extends StatelessWidget {
  const _TrustMiniCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LulunaColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: LulunaColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: LulunaColors.onSurface,
                        letterSpacing: 0,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        height: 1.2,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                        color: LulunaColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
