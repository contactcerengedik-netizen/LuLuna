import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luluna/data/models/skill_level.dart';
import 'package:luluna/features/assignments/data/assignment_repository.dart';
import 'package:luluna/features/assignments/domain/assignment_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AssignmentMatching', () {
    test('demo-student ataması auth uid ile eşleşir', () {
      expect(
        AssignmentMatching.isForStudent('auth-xyz', ['demo-student-1']),
        isTrue,
      );
      expect(
        AssignmentMatching.isForStudent('demo-student-1', ['demo-student-1']),
        isTrue,
      );
      expect(
        AssignmentMatching.isForStudent('other', ['other-student']),
        isFalse,
      );
    });
  });

  group('AssignmentRepository', () {
    test('upsert, openForStudent, markCompletedMatching', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = AssignmentRepository(prefs);

      final hw = HomeworkAssignment(
        id: 'hw1',
        teacherId: 't1',
        title: 'Toplama – Orta',
        skill: SkillArea.mathematics,
        category: 'addition',
        difficulty: SkillTier.medium,
        questionCount: 10,
        studentIds: const ['demo-student-1'],
        createdAt: DateTime(2026, 8, 15),
      );
      await repo.upsert(hw);

      expect(repo.openForStudent('auth-uid').length, 1);
      expect(repo.forTeacher('t1').length, 1);

      final done = await repo.markCompletedMatching(
        studentId: 'auth-uid',
        skillName: 'mathematics',
        category: 'addition',
        difficulty: 'medium',
        questionCount: 10,
      );
      expect(done, ['hw1']);
      expect(repo.openForStudent('auth-uid'), isEmpty);
      expect(repo.forStudent('auth-uid').first.isCompletedBy('auth-uid'), isTrue);
    });

    test('yetersiz soru sayısında tamamlanmaz', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = AssignmentRepository(prefs);
      await repo.upsert(
        HomeworkAssignment(
          id: 'hw2',
          teacherId: 't1',
          title: 'Çıkarma',
          skill: SkillArea.mathematics,
          category: 'subtraction',
          difficulty: SkillTier.easy,
          questionCount: 10,
          studentIds: const ['demo-student-1'],
          createdAt: DateTime(2026, 8, 15),
        ),
      );
      final done = await repo.markCompletedMatching(
        studentId: 's1',
        skillName: 'mathematics',
        category: 'subtraction',
        difficulty: 'easy',
        questionCount: 5,
      );
      expect(done, isEmpty);
      expect(repo.openForStudent('s1').length, 1);
    });
  });
}
