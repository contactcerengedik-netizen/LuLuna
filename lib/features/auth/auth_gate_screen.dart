import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../app/widgets/google_sign_in_button.dart';
import '../../app/widgets/luluna_ui.dart';
import '../../core/test_accounts.dart';
import '../../data/models/user_role.dart';
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
    final path = ref.read(loginPathProvider);
    if (path == null && !isRegister) {
      setState(() => _error = 'Önce giriş yolunu seçin.');
      return;
    }
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
              'Kayıt tamam. Şimdi giriş yolunu seçip giriş yapın.',
            ),
          ),
        );
      } else {
        final email = _email.text.trim();
        final role = resolveRoleForLogin(email: email, path: path!);
        if (role == null) {
          await ref.read(authStateProvider.notifier).signOut();
          setState(() {
            _error = path == LoginPath.teacher
                ? 'Bu hesap öğretmen girişi için uygun değil. '
                    'Veli/Çocuk Girişi’ni kullanın.'
                : 'Bu hesap veli/çocuk girişi için uygun değil. '
                    'Öğretmen Girişi’ni kullanın.';
          });
          return;
        }
        await ref.read(appStateProvider.notifier).selectRole(role);
        if (!mounted) return;
        context.go('/onboarding/consent');
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
    final path = ref.watch(loginPathProvider);
    final isRegister = _tabIndex == 1;
    final textTheme = Theme.of(context).textTheme;

    if (path == null) {
      return Scaffold(
        backgroundColor: LulunaColors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Center(child: LulunaLogo(size: 96)),
                const SizedBox(height: 16),
                Text(
                  'Luluna',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: LulunaColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Giriş yolunu seçin — hesaplar birbirine karışmaz.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: LulunaColors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                LulunaPrimaryButton(
                  label: 'Veli / Çocuk Girişi',
                  onPressed: () =>
                      ref.read(loginPathProvider.notifier).setPath(
                            LoginPath.family,
                          ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: () =>
                      ref.read(loginPathProvider.notifier).setPath(
                            LoginPath.teacher,
                          ),
                  child: const Text('Öğretmen Girişi'),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    final pathTitle = path == LoginPath.teacher
        ? 'Öğretmen Girişi'
        : 'Veli / Çocuk Girişi';
    final demoAccounts = TestAccounts.all.where((a) {
      final role = UserRole.parse(a.roleHint);
      if (role == null) return false;
      return roleMatchesLoginPath(role, path);
    });

    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: Text(pathTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(loginPathProvider.notifier).clear();
            setState(() => _error = null);
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            Text(
              path == LoginPath.teacher
                  ? 'Yalnızca öğretmen hesapları'
                  : 'Veli ve öğrenci hesapları',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: LulunaColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
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
                  GoogleSignInButton(
                    enabled: !_busy,
                    onPressed: _google,
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Test hesapları (bu yol)',
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
                        for (final account in demoAccounts)
                          ActionChip(
                            avatar: Icon(
                              _demoIcon(account.roleHint),
                              size: 18,
                              color: LulunaColors.onSecondaryContainer,
                            ),
                            label: Text(
                              _demoLabel(account.roleHint),
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
          ],
        ),
      ),
    );
  }
}

IconData _demoIcon(String roleHint) {
  return switch (roleHint) {
    'student' => Icons.school_outlined,
    'teacher' => Icons.badge_outlined,
    'parent' => Icons.family_restroom,
    _ => Icons.person_outline,
  };
}

String _demoLabel(String roleHint) {
  return switch (roleHint) {
    'student' => 'Öğrenci',
    'teacher' => 'Öğretmen',
    'parent' => 'Veli',
    _ => roleHint,
  };
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
