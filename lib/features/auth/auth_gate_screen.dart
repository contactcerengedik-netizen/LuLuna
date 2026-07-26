import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

class _AuthGateScreenState extends ConsumerState<AuthGateScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();

  var _busy = false;
  String? _error;
  var _obscure = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabs.indexIsChanging && mounted) setState(() {});
  }

  void _fillDemo(TestAccount account) {
    setState(() {
      _tabs.animateTo(0);
      _email.text = account.email;
      _password.text = account.password;
      _name.text = account.displayName;
      _error = null;
      _obscure = false;
    });
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
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
        _tabs.animateTo(0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kayıt tamam. Şimdi giriş yapın — ardından KVKK, '
              'izinler ve rol seçimi istenecek.',
            ),
          ),
        );
        setState(() {});
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
    await ref
        .read(authStateProvider.notifier)
        .registerEmail(
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
    final scheme = Theme.of(context).colorScheme;
    final isRegister = _tabs.index == 1;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 12),
            Icon(Icons.nightlight_round, size: 64, color: scheme.primary),
            const SizedBox(height: 12),
            Text(
              'Luluna',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isRegister ? 'Yeni hesap oluştur' : 'Hoş geldiniz',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Giriş'),
                Tab(text: 'Kayıt'),
              ],
            ),
            const SizedBox(height: 16),
            if (isRegister) ...[
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Adınız (opsiyonel)',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
            ],
            _AuthFields(
              email: _email,
              password: _password,
              obscure: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
            ),
            if (isRegister) ...[
              const SizedBox(height: 12),
              Text(
                'Kayıt sonrası giriş yapınca KVKK onayı ve cihaz izinleri '
                'istenir.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () {
                      if (isRegister) {
                        _register();
                      } else {
                        _signIn();
                      }
                    },
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isRegister ? 'Kayıt Ol' : 'Giriş Yap'),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _google,
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: Text(
                  isRegister
                      ? 'Google ile kayıt ol (demo)'
                      : 'Google ile giriş (demo)',
                ),
              ),
            ],
            if (kDebugMode) ...[
              const SizedBox(height: 28),
              Text(
                'Test hesapları',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
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
                      ),
                      label: Text(
                        '${account.roleHint}: ${account.email} / ${account.password}',
                      ),
                      onPressed: _busy ? null : () => _fillDemo(account),
                    ),
                ],
              ),
            ],
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
    return Column(
      children: [
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'E-posta',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: password,
          obscureText: obscure,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            labelText: 'Şifre',
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
