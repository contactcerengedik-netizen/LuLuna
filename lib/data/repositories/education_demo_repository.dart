import '../../features/education/domain/question_selection.dart';
import '../../features/language/data/language_question_generator.dart';
import '../../features/mathematics/data/math_question_generator.dart';
import '../models/education_question.dart';
import '../models/skill_level.dart';
import '../models/student_profile.dart';
import 'education_repository.dart';

/// Yerel demo — Supabase yokken / boşken tüm temel akışlar.
class InMemoryEducationRepository implements EducationRepository {
  InMemoryEducationRepository();

  static final demoStudent = StudentProfile(
    id: 'demo-student-1',
    name: 'Ayşe',
    birthDate: DateTime(2015, 3, 12),
    createdAt: DateTime(2026, 1, 1),
    teacherIds: const ['demo-teacher-1'],
    skillLevels: const [
      StudentSkillLevel(
        skill: SkillArea.mathematics,
        skillKey: 'sayi_tanima',
        tier: SkillTier.easy,
      ),
      StudentSkillLevel(
        skill: SkillArea.mathematics,
        skillKey: 'toplama',
        tier: SkillTier.easy,
      ),
      StudentSkillLevel(
        skill: SkillArea.mathematics,
        skillKey: 'cikarma',
        tier: SkillTier.easy,
      ),
      StudentSkillLevel(
        skill: SkillArea.language,
        skillKey: '5n1k',
        tier: SkillTier.medium,
      ),
      StudentSkillLevel(
        skill: SkillArea.language,
        skillKey: 'zit_kavramlar',
        tier: SkillTier.medium,
      ),
      StudentSkillLevel(
        skill: SkillArea.puzzle,
        skillKey: 'puzzle',
        tier: SkillTier.hard,
      ),
    ],
  );

  static final demoStudentB = StudentProfile(
    id: 'demo-student-2',
    name: 'Mehmet',
    birthDate: DateTime(2014, 7, 1),
    createdAt: DateTime(2026, 1, 1),
    teacherIds: const ['demo-teacher-1'],
    skillLevels: const [
      StudentSkillLevel(
        skill: SkillArea.mathematics,
        skillKey: 'toplama',
        tier: SkillTier.medium,
      ),
      StudentSkillLevel(
        skill: SkillArea.language,
        skillKey: '5n1k',
        tier: SkillTier.easy,
      ),
    ],
  );

  @override
  Future<StudentProfile?> studentByUserId(String userId) async {
    return demoStudent.copyWith(id: userId.isEmpty ? demoStudent.id : userId);
  }

  @override
  Future<List<StudentProfile>> studentsForTeacher(String teacherId) async {
    return [demoStudent, demoStudentB];
  }

  @override
  Future<List<EducationQuestion>> sampleQuestions({
    required SkillArea skill,
    SkillTier difficulty = SkillTier.easy,
    String? category,
    List<String> excludeIds = const [],
    int count = 10,
  }) async {
    final cat = category ??
        (skill == SkillArea.language ? 'antonyms' : 'addition');
    if (skill == SkillArea.mathematics) {
      return MathQuestionGenerator().generate(
        category: cat,
        difficulty: difficulty,
        count: count,
        excludeIds: excludeIds,
      );
    }
    if (skill == SkillArea.language) {
      return LanguageQuestionGenerator().generate(
        category: cat,
        difficulty: difficulty,
        count: count,
        excludeIds: excludeIds,
      );
    }
    return QuestionSelection.pickWithoutRecent(
      pool: const [],
      recentIds: excludeIds,
      count: count,
    );
  }

  @override
  Future<void> upsertSkillLevel({
    required String studentId,
    required String skillKey,
    required SkillTier tier,
    SkillLevelSource source = SkillLevelSource.teacherSet,
  }) async {}
}

/// Eski test / import adı.
typedef InMemoryEducationDemoRepository = InMemoryEducationRepository;
