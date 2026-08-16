import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/skill_keys.dart';
import '../../../data/models/skill_level.dart';

/// Yerel `student_skill_levels` — öğretmen onaylı skill_key seviyeleri.
class StudentSkillLevelRepository {
  StudentSkillLevelRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'student_skill_levels_v1';

  Map<String, List<StudentSkillLevel>> _loadMap() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in decoded.entries)
          e.key: [
            for (final row in (e.value as List? ?? const []))
              StudentSkillLevel.fromMap(Map<String, dynamic>.from(row as Map)),
          ],
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveMap(Map<String, List<StudentSkillLevel>> map) async {
    await _prefs.setString(
      _key,
      jsonEncode({
        for (final e in map.entries)
          e.key: e.value.map((x) => x.toMap()).toList(),
      }),
    );
  }

  List<StudentSkillLevel> forStudent(String studentId) =>
      List.unmodifiable(_loadMap()[studentId] ?? const []);

  SkillTier? tierFor(String studentId, String skillKey) {
    for (final row in forStudent(studentId)) {
      if (row.effectiveSkillKey == skillKey) return row.tier;
    }
    return null;
  }

  Map<String, SkillTier> tiersByKey(String studentId) {
    final map = <String, SkillTier>{};
    for (final row in forStudent(studentId)) {
      map[row.effectiveSkillKey] = row.tier;
    }
    return map;
  }

  /// Öğretmen onayı / manuel seviye — `source = teacherSet`.
  Future<StudentSkillLevel> setTeacherLevel({
    required String studentId,
    required String skillKey,
    required SkillTier tier,
  }) async {
    final next = StudentSkillLevel(
      skill: SkillKeys.areaFor(skillKey),
      skillKey: skillKey,
      tier: tier,
      source: SkillLevelSource.teacherSet,
      updatedAt: DateTime.now(),
    );
    final all = _loadMap();
    final list = [...(all[studentId] ?? const <StudentSkillLevel>[])];
    final idx = list.indexWhere((e) => e.effectiveSkillKey == skillKey);
    if (idx >= 0) {
      list[idx] = next;
    } else {
      list.add(next);
    }
    all[studentId] = list;
    await _saveMap(all);
    return next;
  }
}
