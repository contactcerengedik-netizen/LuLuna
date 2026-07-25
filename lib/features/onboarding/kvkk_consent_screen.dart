import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
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
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.privacy_tip_outlined, size: 64, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'KVKK ve Aydınlatma',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'İlk girişinizde bir kez onayınızı alıyoruz. Sonraki girişlerde '
              'tekrar sorulmaz. Mikrofon, bildirim ve Bluetooth izinleri '
              'bir sonraki adımda istenecek.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            CheckboxListTile(
              value: _accepted,
              onChanged: (v) => setState(() => _accepted = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Aydınlatma metnini okudum; kişisel / sağlık verilerimin '
                'işlenmesine açık rıza veriyorum.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              secondary: IconButton(
                tooltip: 'Aydınlatma metni',
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showNotice(context),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _continue,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Onayla ve devam et'),
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
