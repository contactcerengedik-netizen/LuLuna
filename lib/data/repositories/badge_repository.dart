import 'package:shared_preferences/shared_preferences.dart';

import '../models/achievement_badge.dart';

class BadgeRepository {
  BadgeRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'achievement_badges';

  List<AchievementBadge> load() {
    final raw = _prefs.getStringList(_key) ?? const [];
    return raw.map(AchievementBadge.fromJson).toList()
      ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
  }

  Future<void> save(List<AchievementBadge> badges) async {
    await _prefs.setStringList(
      _key,
      badges.map((b) => b.toJson()).toList(),
    );
  }

  Future<void> clear() => _prefs.remove(_key);
}
