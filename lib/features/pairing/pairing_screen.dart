import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation.dart';
import '../../app/theme.dart';
import '../../app/widgets/luluna_ui.dart';
import '../../data/models/user_role.dart';
import '../../data/providers.dart';
import '../../data/repositories/pairing_repository.dart';

/// Veli: davet kodu üret. Terapist: hasta kodunu gir.
class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final _codeController = TextEditingController();
  var _busy = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final profile = ref.read(appStateProvider).profile;
    if (profile == null) {
      setState(() => _error = 'Önce çocuk profilini oluşturun.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      final email = ref.read(authStateProvider)?.email;
      final link = await ref.read(pairingStateProvider.notifier).createInvite(
            profile: profile,
            parentEmail: email,
          );
      setState(() => _message = 'Kod oluşturuldu: ${link.code}');
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      final link = await ref
          .read(pairingStateProvider.notifier)
          .joinAsTherapist(_codeController.text);
      setState(() => _message = '${link.childName} ile eşleştiniz.');
      if (mounted) context.go('/home');
    } on PairingException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(appStateProvider).role;
    final pairing = ref.watch(pairingStateProvider);
    final isParent = role == UserRole.parent;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: lulunaAppBar(
        context,
        title: isParent ? 'Terapist Davet Kodu' : 'Hasta Kodu Gir',
        fallbackLocation: isParent ? '/home' : '/onboarding/role',
        onBack: isParent
            ? null
            : () async {
                // Rolü temizle ki router tekrar eşleştirmeye zorlamasın.
                await ref.read(appStateProvider.notifier).clearRole();
                if (context.mounted) context.go('/onboarding/role');
              },
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 24),
          LulunaCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                LulunaIconBadge(
                  icon: isParent ? Icons.share : Icons.link,
                  size: 80,
                  backgroundColor: LulunaColors.secondaryContainer,
                  foregroundColor: LulunaColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  isParent ? 'Davet Kodu' : 'Kod ile bağlan',
                  style: textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isParent
                      ? 'Terapistinizin çocuğun verilerine güvenle '
                          'erişebilmesi için aşağıdaki kodu paylaşın.'
                      : 'Velinin ürettiği LUNA-XXXX kodunu girerek doğru '
                          'çocuğun verilerine bağlanın.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: LulunaColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                if (isParent) ...[
                  if (pairing.myInviteCode != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: LulunaColors.secondaryContainer
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: LulunaColors.secondary.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'AKTİF KOD',
                            style: textTheme.labelSmall?.copyWith(
                              color: LulunaColors.onSecondaryContainer,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            pairing.myInviteCode!,
                            textAlign: TextAlign.center,
                            style: textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 4,
                              color: LulunaColors.primary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    LulunaPrimaryButton(
                      label: 'Panoya Kopyala',
                      icon: Icons.content_copy,
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: pairing.myInviteCode!),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Kod panoya kopyalandı'),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _busy ? null : _generate,
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text('Yeni Kod Üret'),
                    ),
                  ] else ...[
                    LulunaPrimaryButton(
                      label: 'Davet kodu üret',
                      icon: Icons.refresh,
                      busy: _busy,
                      onPressed: _busy ? null : _generate,
                    ),
                  ],
                ] else ...[
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Davet kodu',
                      prefixIcon: Icon(Icons.vpn_key_outlined),
                    ),
                    onSubmitted: (_) => _join(),
                  ),
                  const SizedBox(height: 16),
                  LulunaPrimaryButton(
                    label: 'Eşleş ve devam et',
                    icon: Icons.link,
                    busy: _busy,
                    onPressed: _busy ? null : _join,
                  ),
                  if (pairing.linkedCode != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Mevcut eşleşme: ${pairing.linkedCode}'
                      '${pairing.linkedChildName != null ? ' · ${pairing.linkedChildName}' : ''}',
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall,
                    ),
                  ],
                ],
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: LulunaColors.primary),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: LulunaColors.error),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Opacity(
              opacity: 0.4,
              child: LulunaLogo(size: 48),
            ),
          ),
        ],
      ),
    );
  }
}
