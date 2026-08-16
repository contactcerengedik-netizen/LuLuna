import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/ai_content_models.dart';

/// Onaylı AI etkinlikleri — öğrenciye yalnızca approved/published gider.
class AiActivityRepository {
  AiActivityRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'teacher_ai_activities_v1';

  List<TeacherAiActivity> loadAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list)
          TeacherAiActivity.fromMap(Map<String, dynamic>.from(e as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveAll(List<TeacherAiActivity> items) async {
    await _prefs.setString(
      _key,
      jsonEncode(items.map((e) => e.toMap()).toList()),
    );
  }

  Future<void> upsert(TeacherAiActivity activity) async {
    final all = [...loadAll()];
    final i = all.indexWhere((e) => e.id == activity.id);
    if (i >= 0) {
      all[i] = activity;
    } else {
      all.insert(0, activity);
    }
    await saveAll(all);
  }

  List<TeacherAiActivity> publishedForStudents() =>
      loadAll().where((e) => e.isStudentVisible).toList();
}
