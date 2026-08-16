import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/assignment_models.dart';

class AssignmentRepository {
  AssignmentRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'homework_assignments_v1';

  List<HomeworkAssignment> loadAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list)
          HomeworkAssignment.fromMap(Map<String, dynamic>.from(e as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveAll(List<HomeworkAssignment> items) async {
    await _prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toMap()).toList()),
    );
  }

  Future<void> upsert(HomeworkAssignment assignment) async {
    final all = [...loadAll()];
    final i = all.indexWhere((e) => e.id == assignment.id);
    if (i >= 0) {
      all[i] = assignment;
    } else {
      all.insert(0, assignment);
    }
    await saveAll(all);
  }

  Future<void> delete(String id) async {
    await saveAll(loadAll().where((e) => e.id != id).toList());
  }

  List<HomeworkAssignment> forTeacher(String teacherId) =>
      loadAll().where((e) => e.teacherId == teacherId || teacherId.isEmpty).toList();

  List<HomeworkAssignment> forStudent(String studentId) =>
      loadAll().where((e) => e.isAssignedTo(studentId)).toList();

  List<HomeworkAssignment> openForStudent(String studentId) => forStudent(
        studentId,
      ).where((e) => !e.isCompletedBy(studentId)).toList();

  /// Oturum bitince eşleşen açık ödevleri tamamlandı işaretle.
  Future<List<String>> markCompletedMatching({
    required String studentId,
    required String skillName,
    required String category,
    required String difficulty,
    required int questionCount,
  }) async {
    final all = [...loadAll()];
    final completedIds = <String>[];
    for (var i = 0; i < all.length; i++) {
      final a = all[i];
      if (!a.isAssignedTo(studentId) || a.isCompletedBy(studentId)) continue;
      if (a.skill.name != skillName) continue;
      if (a.category != category) continue;
      if (a.difficulty.name != difficulty) continue;
      if (questionCount < a.questionCount) continue;
      final nextCompleted = {
        ...a.completedStudentIds,
        studentId,
        ...a.studentIds.where((id) => id.startsWith('demo-student')),
      }.toList();
      all[i] = a.copyWith(completedStudentIds: nextCompleted);
      completedIds.add(a.id);
    }
    if (completedIds.isNotEmpty) await saveAll(all);
    return completedIds;
  }
}
