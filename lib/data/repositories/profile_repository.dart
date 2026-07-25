import 'package:shared_preferences/shared_preferences.dart';

import '../models/child_profile.dart';
import '../models/therapist_rules.dart';
import '../models/user_role.dart';

/// Rol, çocuk profili ve terapist kuralları kalıcılığı.
///
/// Kayıtlar oturum açan kullanıcıya (userId) göre ayrılır; böylece farklı
/// hesapla girildiğinde rol yeniden sorulur ve veriler karışmaz.
class ProfileRepository {
  ProfileRepository(this._prefs, {this.userId});

  final SharedPreferences _prefs;
  final String? userId;

  static const _roleKey = 'user_role';
  static const _profileKey = 'child_profile';
  static const _therapistRulesKey = 'therapist_rules';

  String _k(String base) => userId == null ? base : '${base}_$userId';

  UserRole? loadRole() {
    final name = _prefs.getString(_k(_roleKey));
    return UserRole.values.asNameMap()[name];
  }

  Future<void> saveRole(UserRole role) =>
      _prefs.setString(_k(_roleKey), role.name);

  Future<void> clearRole() => _prefs.remove(_k(_roleKey));

  ChildProfile? loadProfile() {
    final json = _prefs.getString(_k(_profileKey));
    if (json == null) return null;
    return ChildProfile.fromJson(json);
  }

  Future<void> saveProfile(ChildProfile profile) =>
      _prefs.setString(_k(_profileKey), profile.toJson());

  TherapistRules loadTherapistRules() {
    final json = _prefs.getString(_k(_therapistRulesKey));
    if (json == null) return const TherapistRules();
    return TherapistRules.fromJson(json);
  }

  Future<void> saveTherapistRules(TherapistRules rules) =>
      _prefs.setString(_k(_therapistRulesKey), rules.toJson());

  Future<void> clear() async {
    await _prefs.remove(_k(_roleKey));
    await _prefs.remove(_k(_profileKey));
    await _prefs.remove(_k(_therapistRulesKey));
  }
}
