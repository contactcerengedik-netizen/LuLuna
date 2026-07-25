import 'dart:convert';

/// Çocuk doğru reaksiyon verdiğinde veli ekranına düşen başarı rozeti.
class AchievementBadge {
  const AchievementBadge({
    required this.id,
    required this.title,
    required this.earnedAt,
  });

  final String id;
  final String title;
  final DateTime earnedAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'earnedAt': earnedAt.toIso8601String(),
  };

  factory AchievementBadge.fromMap(Map<String, dynamic> map) {
    return AchievementBadge(
      id: map['id'] as String,
      title: map['title'] as String,
      earnedAt: DateTime.parse(map['earnedAt'] as String),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AchievementBadge.fromJson(String source) =>
      AchievementBadge.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
