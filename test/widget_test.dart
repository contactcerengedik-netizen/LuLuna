import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luluna/app/app.dart';
import 'package:luluna/data/models/auth_session.dart';
import 'package:luluna/data/models/user_role.dart';
import 'package:luluna/data/providers.dart';
import 'package:luluna/data/repositories/auth_repository.dart';
import 'package:luluna/data/repositories/profile_repository.dart';

const _kvkk = KvkkConsent(
  privacyNotice: true,
  dataProcessing: true,
  healthData: true,
  micCamera: true,
);

void main() {
  overrides(SharedPreferences prefs) => [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ];

  Future<void> seedReadyAuth(SharedPreferences prefs) async {
    final auth = LocalAuthRepository(prefs);
    await auth.registerEmail(email: 'student@test.com', password: 'secret1');
    await auth.signInEmail(email: 'student@test.com', password: 'secret1');
    await auth.updateKvkk(_kvkk);
  }

  testWidgets('ilk açılışta giriş ekranı gösterilir', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(overrides: overrides(prefs), child: const LulunaApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Özel eğitim platformuna hoş geldiniz'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsOneWidget);
  });

  testWidgets('giriş sonrası KVKK onayı ekranı açılır', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = LocalAuthRepository(prefs);
    await auth.registerEmail(email: 'a@test.com', password: 'secret1');
    await auth.signInEmail(email: 'a@test.com', password: 'secret1');

    await tester.pumpWidget(
      ProviderScope(overrides: overrides(prefs), child: const LulunaApp()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('KVKK'), findsWidgets);
  });

  testWidgets('öğrenci rolü sonrası öğrenci ana ekranı', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await seedReadyAuth(prefs);
    final session = LocalAuthRepository(prefs).loadSession();
    expect(session, isNotNull);
    await prefs.setBool('permissions_intro_seen_${session!.userId}', true);
    await ProfileRepository(prefs, userId: session.userId)
        .saveRole(UserRole.student);

    await tester.pumpWidget(
      ProviderScope(overrides: overrides(prefs), child: const LulunaApp()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Merhaba'), findsOneWidget);
    expect(find.text('Matematik'), findsOneWidget);
  });
}
