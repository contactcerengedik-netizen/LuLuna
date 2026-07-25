import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation.dart';
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
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
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            isParent ? Icons.qr_code_2 : Icons.link,
            size: 64,
            color: scheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            isParent
                ? 'Terapistinize bu kodu verin. Kod, çocuğunuzun profil '
                    'anlığını taşır; terapist raporlara bağlanır.'
                : 'Velinin ürettiği LUNA-XXXX kodunu girerek doğru çocuğun '
                    'verilerine bağlanın.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          if (isParent) ...[
            if (pairing.myInviteCode != null) ...[
              SelectableText(
                pairing.myInviteCode!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: pairing.myInviteCode!),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kod panoya kopyalandı')),
                    );
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('Kodu kopyala'),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              onPressed: _busy ? null : _generate,
              icon: const Icon(Icons.refresh),
              label: Text(
                pairing.myInviteCode == null
                    ? 'Davet kodu üret'
                    : 'Yeni kod üret',
              ),
            ),
          ] else ...[
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Davet kodu',
                hintText: 'LUNA-AB12',
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
              onSubmitted: (_) => _join(),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _busy ? null : _join,
              icon: const Icon(Icons.link),
              label: const Text('Eşleş ve devam et'),
            ),
            if (pairing.linkedCode != null) ...[
              const SizedBox(height: 12),
              Text(
                'Mevcut eşleşme: ${pairing.linkedCode}'
                '${pairing.linkedChildName != null ? ' · ${pairing.linkedChildName}' : ''}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(
              _message!,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.primary),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
