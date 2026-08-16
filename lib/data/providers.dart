import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/env.dart';
import '../core/test_accounts.dart';
import 'models/auth_session.dart';
import 'models/child_profile.dart';
import 'models/student_profile.dart';
import 'models/user_role.dart';
import 'repositories/auth_repository.dart';
import 'repositories/education_accessibility_repository.dart';
import 'repositories/education_demo_repository.dart';
import 'repositories/education_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/supabase_auth_repository.dart';
import 'repositories/supabase_education_repository.dart';
import 'services/education_progress_sync.dart';
import 'services/permissions_service.dart';
import 'services/speech_service.dart';

/// main() içinde gerçek instance ile override edilir.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('main() içinde override edilmeli'),
);

/// Auth öncesi giriş yolu — rol seçiminin yerine geçer.
enum LoginPath { family, teacher }

final loginPathProvider = NotifierProvider<LoginPathNotifier, LoginPath?>(
  LoginPathNotifier.new,
);

class LoginPathNotifier extends Notifier<LoginPath?> {
  @override
  LoginPath? build() => null;

  void setPath(LoginPath path) => state = path;

  void clear() => state = null;
}

/// Demo e-posta → kanonik rol; bilinmeyen hesaplarda null.
UserRole? accountRoleForEmail(String email) {
  final e = email.trim().toLowerCase();
  for (final a in TestAccounts.all) {
    if (a.email == e) return UserRole.parse(a.roleHint);
  }
  return null;
}

bool roleMatchesLoginPath(UserRole role, LoginPath path) {
  if (path == LoginPath.teacher) {
    return role == UserRole.teacher || role == UserRole.admin;
  }
  return role == UserRole.student || role == UserRole.parent;
}

/// Giriş yolu + hesap e-postasına göre atanacak rol (uyumsuzsa null).
UserRole? resolveRoleForLogin({
  required String email,
  required LoginPath path,
}) {
  final fromAccount = accountRoleForEmail(email);
  if (fromAccount != null) {
    return roleMatchesLoginPath(fromAccount, path) ? fromAccount : null;
  }
  // Bilinmeyen hesap: yol ile bağla (veli/çocuk → parent; öğretmen → teacher).
  return path == LoginPath.teacher ? UserRole.teacher : UserRole.parent;
}

/// Supabase client. `Env.hasSupabase` false ise null (Demo Mode).
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!Env.hasSupabase) return null;
  return Supabase.instance.client;
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final userId = ref.watch(authStateProvider.select((s) => s?.userId));
  return ProfileRepository(
    ref.watch(sharedPreferencesProvider),
    userId: userId,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final client = ref.watch(supabaseClientProvider);
  if (client != null) return SupabaseAuthRepository(prefs, client);
  return LocalAuthRepository(prefs);
});

final permissionsServiceProvider = Provider<PermissionsService>((ref) {
  final userId = ref.watch(authStateProvider.select((s) => s?.userId));
  return PermissionsService(
    ref.watch(sharedPreferencesProvider),
    userId: userId,
  );
});

final speechServiceProvider = Provider<SpeechService>(
  (ref) => FlutterTtsSpeechService(),
);

final educationRepositoryProvider = Provider<EducationRepository>((ref) {
  final demo = InMemoryEducationRepository();
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return demo;
  return FallbackEducationRepository(
    primary: SupabaseEducationRepository(client),
    fallback: demo,
  );
});

final educationDemoRepositoryProvider = educationRepositoryProvider;

final educationProgressSyncProvider = Provider<EducationProgressSync>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const NoopEducationProgressSync();
  return SupabaseEducationProgressSync(client);
});

final educationAccessibilityRepositoryProvider =
    Provider<EducationAccessibilityRepository>((ref) {
  return EducationAccessibilityRepository(
    ref.watch(sharedPreferencesProvider),
  );
});

final educationAccessibilityProvider =
    NotifierProvider<EducationAccessibilityNotifier, AccessibilitySettings>(
  EducationAccessibilityNotifier.new,
);

class EducationAccessibilityNotifier extends Notifier<AccessibilitySettings> {
  @override
  AccessibilitySettings build() {
    return ref.watch(educationAccessibilityRepositoryProvider).load();
  }

  Future<void> update(AccessibilitySettings next) async {
    state = next;
    await ref.read(educationAccessibilityRepositoryProvider).save(next);
  }
}

extension AccessibilitySettingsUi on AccessibilitySettings {
  double get textScaleFactor => switch (textSize) {
        TextScale.small => 1.0,
        TextScale.medium => 1.15,
        TextScale.large => 1.35,
      };
}

final currentStudentProfileProvider = FutureProvider.autoDispose((ref) async {
  final uid = ref.watch(authStateProvider)?.userId ?? '';
  return ref.watch(educationRepositoryProvider).studentByUserId(uid);
});

final teacherStudentsProvider = FutureProvider.autoDispose((ref) async {
  final uid = ref.watch(authStateProvider)?.userId ?? 'demo-teacher-1';
  return ref.watch(educationRepositoryProvider).studentsForTeacher(uid);
});

class AuthStateNotifier extends Notifier<AuthSession?> {
  @override
  AuthSession? build() => ref.watch(authRepositoryProvider).loadSession();

  Future<void> registerEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    await ref.read(authRepositoryProvider).registerEmail(
          email: email,
          password: password,
          displayName: displayName,
        );
    state = null;
  }

  Future<void> signInEmail({
    required String email,
    required String password,
  }) async {
    state = await ref
        .read(authRepositoryProvider)
        .signInEmail(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    state = await ref.read(authRepositoryProvider).signInWithGoogle();
  }

  Future<void> updateKvkk(KvkkConsent kvkk) async {
    await ref.read(authRepositoryProvider).updateKvkk(kvkk);
    state = ref.read(authRepositoryProvider).loadSession();
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = null;
  }

  Future<void> deleteAccount() async {
    await ref.read(authRepositoryProvider).deleteAccount();
    state = null;
  }
}

final authStateProvider = NotifierProvider<AuthStateNotifier, AuthSession?>(
  AuthStateNotifier.new,
);

class AppState {
  const AppState({this.role, this.profile});

  final UserRole? role;
  final ChildProfile? profile;

  bool get onboardingComplete {
    if (role == null) return false;
    if (role == UserRole.student ||
        role == UserRole.teacher ||
        role == UserRole.admin ||
        role == UserRole.parent) {
      return true;
    }
    return profile != null;
  }
}

class AppStateNotifier extends Notifier<AppState> {
  @override
  AppState build() {
    final repo = ref.watch(profileRepositoryProvider);
    return AppState(
      role: repo.loadRole(),
      profile: repo.loadProfile(),
    );
  }

  Future<void> selectRole(UserRole role) async {
    await ref.read(profileRepositoryProvider).saveRole(role);
    final client = ref.read(supabaseClientProvider);
    final userId = client?.auth.currentUser?.id;
    if (client != null && userId != null) {
      try {
        await client.from('profiles').upsert({'id': userId, 'role': role.name});
      } catch (_) {}
    }
    state = AppState(role: role, profile: state.profile);
  }

  Future<void> clearRole() async {
    await ref.read(profileRepositoryProvider).clearRole();
    state = AppState(profile: state.profile);
  }

  Future<void> saveProfile(ChildProfile profile) async {
    await ref.read(profileRepositoryProvider).saveProfile(profile);
    state = AppState(role: state.role, profile: profile);
  }

  Future<void> reset() async {
    await ref.read(profileRepositoryProvider).clear();
    state = const AppState();
  }
}

final appStateProvider = NotifierProvider<AppStateNotifier, AppState>(
  AppStateNotifier.new,
);
