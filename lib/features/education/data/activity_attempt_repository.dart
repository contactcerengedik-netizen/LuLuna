import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/activity_models.dart';

/// Yerel aktivite denemeleri (PHASE 7 analytics öncesi).
class ActivityAttemptRepository {
  ActivityAttemptRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'activity_attempts_v1';

  List<ActivityAttempt> loadAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list)
          ActivityAttempt.fromMap(Map<String, dynamic>.from(e as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> append(ActivityAttempt attempt) async {
    final all = [...loadAll(), attempt];
    await _prefs.setString(
      _key,
      jsonEncode(all.map((e) => e.toMap()).toList()),
    );
  }

  Future<void> appendAll(Iterable<ActivityAttempt> attempts) async {
    final all = [...loadAll(), ...attempts];
    await _prefs.setString(
      _key,
      jsonEncode(all.map((e) => e.toMap()).toList()),
    );
  }

  List<ActivityAttempt> forStudent(String studentId) =>
      loadAll().where((e) => e.studentId == studentId).toList();
}
