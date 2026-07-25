import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/user_role.dart';
import '../data/providers.dart';
import '../features/auth/auth_gate_screen.dart';
import '../features/crisis/crisis_screen.dart';
import '../features/device/device_connection_screen.dart';
import '../features/home/home_shell.dart';
import '../features/onboarding/child_profile_screen.dart';
import '../features/onboarding/kvkk_consent_screen.dart';
import '../features/onboarding/permissions_intro_screen.dart';
import '../features/onboarding/role_selection_screen.dart';
import '../features/pairing/pairing_screen.dart';
import '../features/prompt/prompt_preview_screen.dart';
import '../features/prompt/therapist_rules_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(appStateProvider, (_, _) => refresh.value++);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.listen(pairingStateProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/auth',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final app = ref.read(appStateProvider);
      final pairing = ref.read(pairingStateProvider);
      final loc = state.matchedLocation;

      final onAuth = loc == '/auth';
      final onConsent = loc == '/onboarding/consent';
      final onRole = loc == '/onboarding/role';
      final onProfile = loc == '/onboarding/profile';
      final onPermissions = loc == '/onboarding/permissions';
      final onPairing = loc == '/pairing';

      // 0) Oturum yoksa → giriş/kayıt.
      if (auth == null) {
        return onAuth ? null : '/auth';
      }

      // 1) İlk giriş sonrası KVKK (bir kez).
      if (!auth.isReady) {
        return onConsent ? null : '/onboarding/consent';
      }

      // 2) Cihaz izinleri (bir kez).
      final permsSeen = ref.read(permissionsServiceProvider).introSeen;
      if (!permsSeen) {
        return onPermissions ? null : '/onboarding/permissions';
      }

      // 3) Rol yoksa → rol seçimi.
      if (app.role == null) {
        return onRole ? null : '/onboarding/role';
      }

      // 4) Terapist: eşleşme zorunlu — rol seçimine geri dönebilir.
      if (app.role == UserRole.therapist) {
        if (!pairing.hasTherapistLink && app.profile == null) {
          return (onPairing || onRole) ? null : '/pairing';
        }
        if (onAuth || onProfile || onPermissions || onConsent || onRole) {
          return '/home';
        }
        return null;
      }

      // 5) Veli: profil zorunlu — rol ekranına geri dönebilir.
      if (app.profile == null) {
        return (onProfile || onRole) ? null : '/onboarding/profile';
      }

      if (onAuth || onConsent || onPermissions || onRole || onProfile) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthGateScreen(),
      ),
      GoRoute(
        path: '/onboarding/consent',
        builder: (context, state) => const KvkkConsentScreen(),
      ),
      GoRoute(
        path: '/onboarding/role',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding/profile',
        builder: (context, state) => const ChildProfileScreen(),
      ),
      GoRoute(
        path: '/onboarding/permissions',
        builder: (context, state) => const PermissionsIntroScreen(),
      ),
      GoRoute(
        path: '/pairing',
        builder: (context, state) => const PairingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeShell(),
      ),
      GoRoute(
        path: '/crisis',
        builder: (context, state) => const CrisisScreen(),
      ),
      GoRoute(
        path: '/prompt/preview',
        builder: (context, state) => const PromptPreviewScreen(),
      ),
      GoRoute(
        path: '/prompt/rules',
        builder: (context, state) => const TherapistRulesScreen(),
      ),
      GoRoute(
        path: '/device',
        builder: (context, state) => const DeviceConnectionScreen(),
      ),
    ],
  );
});
