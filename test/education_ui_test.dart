import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luluna/app/widgets/education_ui.dart';
import 'package:luluna/data/models/skill_level.dart';
import 'package:luluna/data/models/student_profile.dart';
import 'package:luluna/data/repositories/education_accessibility_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EducationAccessibilityRepository', () {
    test('kaydet ve yükle', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = EducationAccessibilityRepository(prefs);
      const next = AccessibilitySettings(
        voiceInstructions: false,
        highContrast: true,
        textSize: TextScale.large,
      );
      await repo.save(next);
      final loaded = repo.load();
      expect(loaded.voiceInstructions, isFalse);
      expect(loaded.highContrast, isTrue);
      expect(loaded.textSize, TextScale.large);
    });
  });

  group('Education UI', () {
    testWidgets('SkillTierChip etiketi gösterir', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SkillTierChip(tier: SkillTier.medium)),
        ),
      );
      expect(find.text('Orta'), findsOneWidget);
    });

    testWidgets('EducationBigTile dokunulabilir', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EducationBigTile(
              title: 'Matematik',
              subtitle: 'Sayılar',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Matematik'));
      expect(tapped, isTrue);
    });
  });
}
