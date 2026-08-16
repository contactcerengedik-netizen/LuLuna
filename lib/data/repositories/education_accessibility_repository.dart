import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/student_profile.dart';

/// Öğrenci UI erişilebilirlik tercihleri (cihaz lokal).
class EducationAccessibilityRepository {
  EducationAccessibilityRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'education_accessibility_v1';

  AccessibilitySettings load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const AccessibilitySettings();
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return AccessibilitySettings.fromMap(map);
    } catch (_) {
      return const AccessibilitySettings();
    }
  }

  Future<void> save(AccessibilitySettings settings) async {
    await _prefs.setString(_key, jsonEncode(settings.toMap()));
  }
}
