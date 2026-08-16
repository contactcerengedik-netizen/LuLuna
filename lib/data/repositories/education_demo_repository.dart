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
  }) async {
    if (skill == SkillArea.mathematics) {
      return [
        EducationQuestion(
          id: 'math-add-1',
          category: 'addition',
          skill: SkillArea.mathematics,
          difficulty: difficulty,
          instruction: 'Toplamı bul.',
          questionText: '3 + 5 = ?',
          choices: const ['6', '7', '8', '9'],
          correctAnswer: '8',
          explanation: '3 ile 5 toplanınca 8 olur.',
        ),
        EducationQuestion(
          id: 'math-sub-1',
          category: 'subtraction',
          skill: SkillArea.mathematics,
          difficulty: difficulty,
          instruction: 'Farkı bul.',
          questionText: '9 - 4 = ?',
          choices: const ['3', '4', '5', '6'],
          correctAnswer: '5',
          explanation: '9 eksi 4 eşittir 5.',
        ),
      ];
    }
    if (skill == SkillArea.language) {
      return [
        EducationQuestion(
          id: 'lang-antonym-1',
          category: 'antonyms',
          skill: SkillArea.language,
          difficulty: difficulty,
          instruction: 'Zıt kavramı seç.',
          questionText: 'GECE',
          choices: const ['Gündüz', 'Karanlık', 'Akşam'],
          correctAnswer: 'Gündüz',
          explanation: 'Gecenin zıttı gündüzdür.',
        ),
      ];
    }
    return const [];
  }

  @override
  Future<void> upsertSkillLevel({
    required String studentId,
    required String skillKey,
    required SkillTier tier,
    SkillLevelSource source = SkillLevelSource.teacherSet,
  }) async {
    // Demo: bellek içi profil güncellemesi yok; yerel StudentSkillLevelRepository kullanır.
  }
}

/// Eski sınıf adı.
typedef InMemoryEducationDemoRepository = InMemoryEducationRepository;
