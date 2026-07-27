import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../app/widgets/luluna_ui.dart';
import '../../core/env.dart';
import '../../core/test_accounts.dart';
import '../../data/providers.dart';
import '../../data/repositories/auth_repository.dart';

/// Sayfa 0 — Giriş/Kayıt. KVKK ve cihaz izinleri burada sorulmaz;
/// ilk giriş sonrası ayrı ekranlarda alınır.
class AuthGateScreen extends ConsumerStatefulWidget {
  const AuthGateScreen({super.key});

  @override
  ConsumerState<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends ConsumerState<AuthGateScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();

  var _tabIndex = 0;
  var _busy = false;
  String? _error;
  var _obscure = true;

  void _fillDemo(TestAccount account) {
    setState(() {
      _tabIndex = 0;
      _email.text = account.email;
      _password.text = account.password;
      _name.text = account.displayName;
      _error = null;
      _obscure = false;
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<void> Function() action, {
    required bool isRegister,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      if (isRegister) {
        setState(() => _tabIndex = 0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kayıt tamam. Şimdi giriş yapın — ardından KVKK, '
              'izinler ve rol seçimi istenecek.',
            ),
          ),
        );
      } else {
        context.go('/home');
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Beklenmeyen hata: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signIn() => _run(() async {
        await ref
            .read(authStateProvider.notifier)
            .signInEmail(email: _email.text, password: _password.text);
      }, isRegister: false);

  Future<void> _register() => _run(() async {
        await ref.read(authStateProvider.notifier).registerEmail(
              email: _email.text,
              password: _password.text,
              displayName: _name.text,
            );
      }, isRegister: true);

  Future<void> _google() => _run(() async {
        await ref.read(authStateProvider.notifier).signInWithGoogle();
      }, isRegister: false);

  @override
  Widget build(BuildContext context) {
    final isRegister = _tabIndex == 1;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: LulunaColors.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            const SizedBox(height: 12),
            const Center(child: LulunaLogo(size: 96)),
            const SizedBox(height: 16),
            Text(
              'Luluna',
              textAlign: TextAlign.center,
              style: textTheme.headlineLarge?.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: LulunaColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isRegister ? 'Yeni hesap oluştur' : 'Hoş geldiniz',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: LulunaColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            LulunaCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LulunaSegmentedTabs(
                    labels: const ['Giriş', 'Kayıt'],
                    index: _tabIndex,
                    onChanged: (i) => setState(() {
                      _tabIndex = i;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: 24),
                  if (isRegister) ...[
                    Text(
                      'Ad Soyad',
                      style: textTheme.labelSmall?.copyWith(
                        color: LulunaColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        hintText: 'Adınızı girin',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _AuthFields(
                    email: _email,
                    password: _password,
                    obscure: _obscure,
                    onToggleObscure: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                  if (isRegister) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Kayıt sonrası giriş yapınca KVKK onayı ve cihaz '
                      'izinleri istenir.',
                      style: textTheme.bodySmall?.copyWith(
                        color: LulunaColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(color: LulunaColors.error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  LulunaPrimaryButton(
                    label: isRegister ? 'Kayıt Ol' : 'Giriş Yap',
                    busy: _busy,
                    onPressed: () {
                      if (isRegister) {
                        _register();
                      } else {
                        _signIn();
                      }
                    },
                  ),
                  if (Env.hasSupabase || kDebugMode) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'veya',
                            style: textTheme.labelSmall?.copyWith(
                              color: LulunaColors.outlineVariant,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _google,
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: Text(
                        Env.hasSupabase
                            ? (isRegister
                                ? 'Google ile kayıt ol'
                                : 'Google ile giriş')
                            : (isRegister
                                ? 'Google ile kayıt ol (demo)'
                                : 'Google ile giriş (demo)'),
                      ),
                    ),
                  ],
                  if (kDebugMode) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Test hesapları',
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(
                        color: LulunaColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final account in TestAccounts.all)
                          ActionChip(
                            avatar: Icon(
                              account.roleHint == 'veli'
                                  ? Icons.family_restroom
                                  : Icons.psychology,
                              size: 18,
                              color: LulunaColors.onSecondaryContainer,
                            ),
                            label: Text(
                              account.roleHint == 'veli' ? 'Veli' : 'Terapist',
                              style: const TextStyle(
                                color: LulunaColors.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: LulunaColors.secondaryContainer,
                            side: BorderSide.none,
                            onPressed:
                                _busy ? null : () => _fillDemo(account),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '© 2024 Luluna AI Health Assistant',
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(
                color: LulunaColors.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthFields extends StatelessWidget {
  const _AuthFields({
    required this.email,
    required this.password,
    required this.obscure,
    required this.onToggleObscure,
  });

  final TextEditingController email;
  final TextEditingController password;
  final bool obscure;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: LulunaColors.onSurfaceVariant,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('E-posta', style: labelStyle),
        const SizedBox(height: 4),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            hintText: 'ornek@mail.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 16),
        Text('Şifre', style: labelStyle),
        const SizedBox(height: 4),
        TextField(
          controller: password,
          obscureText: obscure,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: onToggleObscure,
            ),
          ),
        ),
      ],
    );
  }
}
