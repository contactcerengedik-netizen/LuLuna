import '../models/education_question.dart';
import '../models/skill_level.dart';
import '../models/student_profile.dart';

/// Eğitim platformu veri kaynağı — demo veya Supabase.
abstract class EducationRepository {
  Future<StudentProfile?> studentByUserId(String userId);

  Future<List<StudentProfile>> studentsForTeacher(String teacherId);

  Future<List<EducationQuestion>> sampleQuestions({
    required SkillArea skill,
    SkillTier difficulty = SkillTier.easy,
    String? category,
    List<String> excludeIds = const [],
    int count = 10,
  });

  /// Öğretmen onaylı skill_key seviyesi (bulutta upsert; demo no-op).
  Future<void> upsertSkillLevel({
    required String studentId,
    required String skillKey,
    required SkillTier tier,
    SkillLevelSource source = SkillLevelSource.teacherSet,
  });
}

/// Geriye uyumluluk (PHASE 1 adı).
typedef EducationDemoRepository = EducationRepository;
