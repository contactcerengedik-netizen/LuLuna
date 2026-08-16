import '../../../data/models/skill_level.dart';

enum AssignmentProgressStatus { assigned, completed }

/// Öğretmenin atadığı ödev.
class HomeworkAssignment {
  const HomeworkAssignment({
    required this.id,
    required this.teacherId,
    required this.title,
    required this.skill,
    required this.category,
    required this.difficulty,
    required this.questionCount,
    required this.studentIds,
    required this.createdAt,
    this.dueAt,
    this.completedStudentIds = const [],
  });

  final String id;
  final String teacherId;
  final String title;
  final SkillArea skill;
  final String category;
  final SkillTier difficulty;
  final int questionCount;
  final List<String> studentIds;
  final DateTime createdAt;
  final DateTime? dueAt;
  final List<String> completedStudentIds;

  bool isAssignedTo(String studentId) =>
      AssignmentMatching.isForStudent(studentId, studentIds);

  bool isCompletedBy(String studentId) {
    if (completedStudentIds.contains(studentId)) return true;
    return AssignmentMatching.isForStudent(studentId, completedStudentIds);
  }

  AssignmentProgressStatus statusFor(String studentId) =>
      isCompletedBy(studentId)
          ? AssignmentProgressStatus.completed
          : AssignmentProgressStatus.assigned;

  HomeworkAssignment copyWith({
    List<String>? studentIds,
    List<String>? completedStudentIds,
    DateTime? dueAt,
  }) {
    return HomeworkAssignment(
      id: id,
      teacherId: teacherId,
      title: title,
      skill: skill,
      category: category,
      difficulty: difficulty,
      questionCount: questionCount,
      studentIds: studentIds ?? this.studentIds,
      createdAt: createdAt,
      dueAt: dueAt ?? this.dueAt,
      completedStudentIds: completedStudentIds ?? this.completedStudentIds,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'teacherId': teacherId,
        'title': title,
        'skill': skill.name,
        'category': category,
        'difficulty': difficulty.name,
        'questionCount': questionCount,
        'studentIds': studentIds,
        'createdAt': createdAt.toIso8601String(),
        'dueAt': dueAt?.toIso8601String(),
        'completedStudentIds': completedStudentIds,
      };

  factory HomeworkAssignment.fromMap(Map<String, dynamic> map) {
    return HomeworkAssignment(
      id: map['id'] as String? ?? '',
      teacherId: map['teacherId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      skill: SkillArea.values.asNameMap()[map['skill'] as String?] ??
          SkillArea.mathematics,
      category: map['category'] as String? ?? '',
      difficulty: SkillTier.values.asNameMap()[map['difficulty'] as String?] ??
          SkillTier.easy,
      questionCount: map['questionCount'] as int? ?? 10,
      studentIds: List<String>.from(map['studentIds'] as List? ?? const []),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      dueAt: DateTime.tryParse(map['dueAt'] as String? ?? ''),
      completedStudentIds: List<String>.from(
        map['completedStudentIds'] as List? ?? const [],
      ),
    );
  }
}

/// Demo hesaplarında teacher listesi id ↔ auth uid eşlemesi.
abstract final class AssignmentMatching {
  static bool isForStudent(String studentId, List<String> ids) {
    if (ids.contains(studentId)) return true;
    if (studentId.isEmpty || ids.isEmpty) return false;
    // Tek cihaz demo: demo-student-* atamaları aktif öğrenci oturumuna görünür.
    if (ids.any((id) => id.startsWith('demo-student'))) return true;
    if (studentId.startsWith('demo-student') &&
        ids.any((id) => !id.startsWith('demo-student'))) {
      return true;
    }
    return false;
  }
}
