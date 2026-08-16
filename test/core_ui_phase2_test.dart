import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luluna/app/app.dart';
import 'package:luluna/app/widgets/education_ui.dart';
import 'package:luluna/data/models/auth_session.dart';
import 'package:luluna/data/models/user_role.dart';
import 'package:luluna/data/providers.dart';
import 'package:luluna/data/repositories/auth_repository.dart';
import 'package:luluna/data/repositories/profile_repository.dart';
import 'package:luluna/features/student/presentation/student_home_screen.dart';
import 'package:luluna/features/teacher/presentation/teacher_dashboard_screen.dart';
import 'package:luluna/features/teacher/presentation/teacher_student_detail_screen.dart';

const _kvkk = KvkkConsent(
  privacyNotice: true,
  dataProcessing: true,
  healthData: true,
  micCamera: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> readyPrefs({
    required UserRole role,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = LocalAuthRepository(prefs);
    await auth.registerEmail(email: 'u@test.com', password: 'secret12');
    final session =
        await auth.signInEmail(email: 'u@test.com', password: 'secret12');
    await auth.updateKvkk(_kvkk);
    await prefs.setBool('permissions_intro_seen_${session.userId}', true);
    await ProfileRepository(prefs, userId: session.userId).saveRole(role);
    return prefs;
  }

  testWidgets('öğrenci ana: Matematik Türkçe Puzzle', (tester) async {
    final prefs = await readyPrefs(role: UserRole.student);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: StudentHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Matematik'), findsOneWidget);
    expect(find.text('Türkçe'), findsOneWidget);
    expect(find.text('Puzzle'), findsOneWidget);
    expect(find.text('Boyama'), findsOneWidget);
    expect(find.text('Çizgi / Motor'), findsOneWidget);
  });

  testWidgets('öğretmen paneli öğrenci listesi', (tester) async {
    final prefs = await readyPrefs(role: UserRole.teacher);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: TeacherDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Öğretmen Paneli'), findsOneWidget);
    expect(find.text('Öğrencilerim'), findsOneWidget);
    expect(find.text('Ayşe'), findsOneWidget);
    expect(find.text('Mehmet'), findsOneWidget);
  });

  testWidgets('öğrenci detay beceri chip', (tester) async {
    final prefs = await readyPrefs(role: UserRole.teacher);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          home: TeacherStudentDetailScreen(studentId: 'demo-student-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Beceri seviyeleri'), findsOneWidget);
    expect(find.text('Performans'), findsOneWidget);
    expect(find.text('Ayşe'), findsOneWidget);
    expect(find.textContaining('Onaylı'), findsWidgets);
    expect(find.byType(SkillTierChip), findsWidgets);
    expect(find.byType(ChoiceChip), findsWidgets);
  });

  testWidgets('giriş ekranı marka metni', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const LulunaApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Veli / Çocuk Girişi'), findsOneWidget);
    expect(find.text('Öğretmen Girişi'), findsOneWidget);
    expect(find.text('Luluna'), findsWidgets);
  });
}
