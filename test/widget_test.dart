import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:luluna/app/app.dart';
import 'package:luluna/app/router.dart';
import 'package:luluna/data/models/auth_session.dart';
import 'package:luluna/data/models/child_profile.dart';
import 'package:luluna/data/models/user_role.dart';
import 'package:luluna/data/providers.dart';
import 'package:luluna/data/repositories/auth_repository.dart';
import 'package:luluna/data/repositories/log_queue_repository.dart';
import 'package:luluna/data/repositories/profile_repository.dart';

const _kvkk = KvkkConsent(
  privacyNotice: true,
  dataProcessing: true,
  healthData: true,
  micCamera: true,
);

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  overrides(SharedPreferences prefs) => [
        sharedPreferencesProvider.overrideWithValue(prefs),
        logQueueRepositoryProvider.overrideWith(
          (ref) => LogQueueRepository(
            databaseFactory: databaseFactoryFfi,
            databasePath: inMemoryDatabasePath,
          ),
        ),
      ];

  /// Kayıt → giriş → KVKK (oturum hazır). Kullanıcı id'sini döndürür.
  Future<String> seedReadyAuth(SharedPreferences prefs) async {
    final auth = LocalAuthRepository(prefs);
    await auth.registerEmail(email: 'veli@test.com', password: 'secret1');
    final session = await auth.signInEmail(
      email: 'veli@test.com',
      password: 'secret1',
    );
    await auth.updateKvkk(_kvkk);
    return session.userId;
  }

  testWidgets('ilk açılışta giriş ekranı gösterilir (KVKK yok)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(prefs),
        child: const LulunaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hoş geldiniz'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsOneWidget);
    expect(find.text('KVKK ve Aydınlatma'), findsNothing);
  });

  testWidgets('kayıt sekmesinde de KVKK yok', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(prefs),
        child: const LulunaApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kayıt'));
    await tester.pumpAndSettle();

    expect(find.text('Yeni hesap oluştur'), findsOneWidget);
    expect(find.text('KVKK ve Aydınlatma'), findsNothing);
  });

  testWidgets('giriş sonrası KVKK onayı ekranı açılır', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = LocalAuthRepository(prefs);
    await auth.registerEmail(email: 'veli@test.com', password: 'secret1');
    await auth.signInEmail(email: 'veli@test.com', password: 'secret1');

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(prefs),
        child: const LulunaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('KVKK ve Aydınlatma'), findsOneWidget);
    expect(find.text('Onayla ve devam et'), findsOneWidget);
  });

  testWidgets('her yeni hesapta rol seçimi sorulur', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await seedReadyAuth(prefs);
    await prefs.setBool('permissions_intro_seen', true);
    // Başka bir hesaba ait eski rol bu kullanıcıyı etkilememeli.
    await prefs.setString('user_role', 'therapist');

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(prefs),
        child: const LulunaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kim olarak devam etmek istiyorsunuz?'), findsOneWidget);
    expect(find.text('Veli'), findsOneWidget);
  });

  testWidgets('rol seçilmeden ana paneli açamaz', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await seedReadyAuth(prefs);
    await prefs.setBool('permissions_intro_seen', true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(prefs),
        child: const LulunaApp(),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.text('Luluna')),
    );
    container.read(routerProvider).go('/home');
    await tester.pumpAndSettle();

    expect(find.text('Veli'), findsOneWidget);
    expect(find.text('Panel'), findsNothing);
  });

  testWidgets('terapist eşleşmeden geri ile rol seçimine döner', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final userId = await seedReadyAuth(prefs);
    await prefs.setBool('permissions_intro_seen', true);
    await ProfileRepository(prefs, userId: userId).saveRole(UserRole.therapist);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(prefs),
        child: const LulunaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hasta Kodu Gir'), findsOneWidget);

    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();

    expect(find.text('Kim olarak devam etmek istiyorsunuz?'), findsOneWidget);
    expect(find.text('Veli'), findsOneWidget);
    expect(find.text('Terapist'), findsOneWidget);
  });

  testWidgets('veli onboarding tamamsa panele gider', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final userId = await seedReadyAuth(prefs);
    await prefs.setBool('permissions_intro_seen', true);
    final repo = ProfileRepository(prefs, userId: userId);
    await repo.saveRole(UserRole.parent);
    await repo.saveProfile(
      const ChildProfile(name: 'Ela', triggers: ['Yüksek ses']),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(prefs),
        child: const LulunaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Luluna Paneli'), findsOneWidget);
    expect(find.text('Panel'), findsOneWidget);
  });

  testWidgets('terapist alt menüsünde Panel/Asistan yok', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final userId = await seedReadyAuth(prefs);
    await prefs.setBool('permissions_intro_seen', true);
    final repo = ProfileRepository(prefs, userId: userId);
    await repo.saveRole(UserRole.therapist);
    await repo.saveProfile(
      const ChildProfile(name: 'Ela', triggers: ['Yüksek ses']),
    );
    await prefs.setString('pairing_linked_code_$userId', 'LUNA-TEST');

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(prefs),
        child: const LulunaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Raporlar'), findsWidgets);
    expect(find.text('Ayarlar'), findsOneWidget);
    expect(find.text('Panel'), findsNothing);
    expect(find.text('Asistan'), findsNothing);
  });
}
