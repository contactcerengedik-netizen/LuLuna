import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/analytics_models.dart';

class ActivitySessionRepository {
  ActivitySessionRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'activity_sessions_v1';

  List<ActivitySessionEvent> loadAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list)
          ActivitySessionEvent.fromMap(Map<String, dynamic>.from(e as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> append(ActivitySessionEvent event) async {
    final all = [...loadAll(), event];
    await _prefs.setString(
      _key,
      jsonEncode(all.map((e) => e.toMap()).toList()),
    );
  }

  List<ActivitySessionEvent> forStudent(String studentId) =>
      loadAll().where((e) => e.studentId == studentId).toList();
}
