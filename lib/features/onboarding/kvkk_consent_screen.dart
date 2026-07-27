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
    final bodyStyle = textTheme.bodyMedium?.copyWith(
      color: LulunaColors.onSurfaceVariant,
      height: 1.45,
    );
    final headingStyle = textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: LulunaColors.onSurface,
    );

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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
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
                        size: 36,
                        color: LulunaColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'KVKK ve Aydınlatma',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'İlk girişinizde bir kez onayınızı alıyoruz. Sonraki '
                    'girişlerde tekrar sorulmaz. Aşağıdaki metni okuyup '
                    'kaydırarak ilerleyin; ardından açık rızanızı verin.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: LulunaColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  LulunaCard(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aydınlatma ve Açık Rıza Metni',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '1. Veri Sorumlusunun Kimliği',
                          style: headingStyle,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Luluna ("Uygulama") olarak, 6698 sayılı Kişisel '
                          'Verilerin Korunması Kanunu ("KVKK") uyarınca, '
                          'kişisel verileriniz ve özel nitelikli kişisel '
                          'verileriniz veri sorumlusu sıfatıyla tarafımızca '
                          'işlenmektedir. Amacımız, yapay zeka destekli '
                          'asistan hizmetini en güvenli ve şeffaf şekilde '
                          'sunmaktır.',
                          style: bodyStyle,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '2. İşlenen Veriler ve İşlenme Amacı',
                          style: headingStyle,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Uygulama üzerinden sağladığınız profil bilgileri '
                          '(isim, iletişim bilgileri), rolünüz '
                          '(Veli/Terapist) ve donanım üzerinden alınan '
                          'veriler şu amaçlarla işlenmektedir:',
                          style: bodyStyle,
                        ),
                        const SizedBox(height: 10),
                        Text.rich(
                          TextSpan(
                            style: bodyStyle,
                            children: [
                              TextSpan(
                                text: 'Özel Nitelikli Sağlık Verileri: ',
                                style: bodyStyle?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: LulunaColors.onSurface,
                                ),
                              ),
                              const TextSpan(
                                text:
                                    'Profil ekranında girilen '
                                    'tetikleyiciler, fobiler, sakinleştirici '
                                    'unsurlar ve kriz anı stres göstergeleri, '
                                    'yapay zekanın (Gemini) anlık asistanlık '
                                    've yönlendirme hizmetini (System Prompt) '
                                    'kişiselleştirmesi amacıyla işlenir.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text.rich(
                          TextSpan(
                            style: bodyStyle,
                            children: [
                              TextSpan(
                                text:
                                    'Sensör ve Medya Verileri (Ses/Görüntü): ',
                                style: bodyStyle?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: LulunaColors.onSurface,
                                ),
                              ),
                              const TextSpan(
                                text:
                                    'Cihaz donanımı (ESP32-CAM ve mikrofon) '
                                    'üzerinden sağlanan canlı akış ve ses '
                                    'verileri, kriz tespiti ve veli '
                                    'müdahalesi amacıyla işlenir. Veli '
                                    'tarafından kaydedilen kriz anı telkin '
                                    'ses kayıtları yalnızca kullanıcının '
                                    'yerel cihazında (lokal) saklanmaktadır.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '3. Verilerin Aktarımı '
                          '(Terapist ve Bulut Entegrasyonu)',
                          style: headingStyle,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kişisel ve sağlık verileriniz, yalnızca sizin '
                          '(Veli) oluşturduğunuz davet kodunu kullanarak '
                          'hesabınızla eşleşen yetkili terapistiniz ile '
                          'gelişim raporları ve dinamik kural yönetimi '
                          'amacıyla paylaşılır. Verileriniz, uygulamanın '
                          'çalışabilmesi için güvenli bulut sunucularında '
                          '(Supabase) şifreli olarak muhafaza edilmektedir. '
                          'Üçüncü taraf reklam veya pazarlama şirketleriyle '
                          'hiçbir veri paylaşılmaz.',
                          style: bodyStyle,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '4. Veri Güvenliği ve Saklama Süresi',
                          style: headingStyle,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'İşlenen veriler, asistanlık hizmetinin devamı '
                          'süresince saklanır. Ayarlar menüsünden '
                          '"Verileri Sıfırla" veya "Hesabı Sil" seçenekleri '
                          'kullanıldığında, KVKK madde 7 uyarınca tüm '
                          'profil, kural ve eşleşme verileriniz '
                          'sistemlerimizden kalıcı olarak ve '
                          'anonimleştirilemeyecek şekilde silinir.',
                          style: bodyStyle,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '5. KVKK Madde 11 Kapsamındaki Haklarınız',
                          style: headingStyle,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kullanıcılar; verilerinin işlenip işlenmediğini '
                          'öğrenme, amacına uygun kullanılıp '
                          'kullanılmadığını bilme, eksik/yanlış verileri '
                          'düzeltme (Profil ekranından), verilerin '
                          'silinmesini talep etme (Ayarlar ekranından) ve '
                          'verilerini dışa aktarma (JSON formatında) '
                          'haklarına sahiptir.',
                          style: bodyStyle,
                        ),
                      ],
                    ),
                  ),
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
                  const SizedBox(height: 16),
                  LulunaCard(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
                            padding: const EdgeInsets.only(top: 12, bottom: 8),
                            child: Text(
                              'Aydınlatma Metni\'ni okudum. Luluna\'nın bana '
                              've çocuğuma ait kişisel verileri ile sağlık '
                              've biyometrik verileri (kriz anı ses '
                              'analizleri, tetikleyici bilgileri) hizmetin '
                              'sağlanması amacıyla işlemesine, saklamasına '
                              've eşleştiğim terapist ile paylaşmasına açık '
                              'rıza gösteriyorum.',
                              style: textTheme.bodyMedium,
                            ),
                          ),
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
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: LulunaColors.surface.withValues(alpha: 0.95),
                border: Border(
                  top: BorderSide(
                    color: LulunaColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
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
