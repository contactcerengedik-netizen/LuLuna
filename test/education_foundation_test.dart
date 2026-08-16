import 'package:flutter_test/flutter_test.dart';

import 'package:luluna/data/models/education_question.dart';
import 'package:luluna/data/models/skill_level.dart';
import 'package:luluna/data/models/student_profile.dart';
import 'package:luluna/data/models/user_role.dart';
import 'package:luluna/data/repositories/education_demo_repository.dart';

void main() {
  group('UserRole.parse', () {
    test('eski adları yeni rollere map eder', () {
      expect(UserRole.parse('learner'), UserRole.student);
      expect(UserRole.parse('therapist'), UserRole.teacher);
      expect(UserRole.parse('student'), UserRole.student);
      expect(UserRole.parse('teacher'), UserRole.teacher);
    });
  });

  group('StudentProfile', () {
    test('beceri seviyesi kronolojik yaştan bağımsız', () {
      const profile = StudentProfile(
        id: '1',
        name: 'Ayşe',
        skillLevels: [
          StudentSkillLevel(
            skill: SkillArea.mathematics,
            tier: SkillTier.easy,
          ),
          StudentSkillLevel(
            skill: SkillArea.puzzle,
            tier: SkillTier.hard,
          ),
        ],
      );
      expect(profile.tierFor(SkillArea.mathematics), SkillTier.easy);
      expect(profile.tierFor(SkillArea.puzzle), SkillTier.hard);
      expect(profile.tierFor(SkillArea.language), SkillTier.easy);
    });
  });

  group('EducationQuestion', () {
    test('cevap doğrulama', () {
      const q = EducationQuestion(
        id: '1',
        category: 'addition',
        skill: SkillArea.mathematics,
        difficulty: SkillTier.easy,
        instruction: 'Topla',
        questionText: '2+2',
        correctAnswer: '4',
      );
      expect(q.isCorrect('4'), isTrue);
      expect(q.isCorrect(' 4 '), isTrue);
      expect(q.isCorrect('5'), isFalse);
    });
  });

  group('EducationDemoRepository', () {
    test('öğretmen öğrencileri ve örnek sorular', () async {
      final repo = InMemoryEducationDemoRepository();
      final students = await repo.studentsForTeacher('t1');
      expect(students.length, greaterThanOrEqualTo(2));
      final qs = await repo.sampleQuestions(skill: SkillArea.mathematics);
      expect(qs.length, greaterThanOrEqualTo(8));
      expect(qs.first.isCorrect(qs.first.correctAnswer), isTrue);
    });
  });
}
