import 'difficulty.dart';

/// Beceri alanları — kronolojik yaştan bağımsız seviye tutulur.
enum SkillArea {
  mathematics('Matematik'),
  language('Türkçe'),
  puzzle('Puzzle'),
  tracing('Çizgi'),
  coloring('Boyama'),
  dailyLife('Günlük Yaşam'),
  communication('İletişim'),
  visualPerception('Görsel algı'),
  fineMotor('İnce motor');

  const SkillArea(this.label);
  final String label;
}

/// Öğrenci beceri seviyesi (easy/medium/hard ürün dili).
enum SkillTier {
  easy('Kolay'),
  medium('Orta'),
  hard('Zor');

  const SkillTier(this.label);
  final String label;

  Difficulty toDifficulty() => switch (this) {
    SkillTier.easy => Difficulty.beginner,
    SkillTier.medium => Difficulty.medium,
    SkillTier.hard => Difficulty.advanced,
  };

  static SkillTier fromDifficulty(Difficulty d) => switch (d) {
    Difficulty.beginner || Difficulty.easy => SkillTier.easy,
    Difficulty.medium => SkillTier.medium,
    Difficulty.advanced => SkillTier.hard,
  };
}

/// Seviye kaynağı — sistem önerisi otomatik uygulanmaz; öğretmen onaylar.
enum SkillLevelSource {
  systemSuggested,
  teacherSet;

  String get label => switch (this) {
        SkillLevelSource.systemSuggested => 'Sistem önerisi',
        SkillLevelSource.teacherSet => 'Öğretmen onayı',
      };
}

class StudentSkillLevel {
  const StudentSkillLevel({
    required this.skill,
    required this.tier,
    this.skillKey,
    this.source = SkillLevelSource.teacherSet,
    this.masteryPercent = 0,
    this.updatedAt,
  });

  final SkillArea skill;
  final SkillTier tier;
  /// Prompt §6: örn. toplama, 5n1k. Yoksa [skill].name kullanılır.
  final String? skillKey;
  final SkillLevelSource source;
  final double masteryPercent;
  final DateTime? updatedAt;

  String get effectiveSkillKey => skillKey ?? skill.name;

  Map<String, dynamic> toMap() => {
        'skill': skill.name,
        'tier': tier.name,
        'skillKey': skillKey,
        'source': source.name,
        'masteryPercent': masteryPercent,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory StudentSkillLevel.fromMap(Map<String, dynamic> map) {
    final sourceName = map['source'] as String?;
    return StudentSkillLevel(
      skill: SkillArea.values.asNameMap()[map['skill']] ?? SkillArea.mathematics,
      tier: SkillTier.values.asNameMap()[map['tier'] ?? map['level']] ??
          SkillTier.easy,
      skillKey: map['skillKey'] as String? ?? map['skill_key'] as String?,
      source: SkillLevelSource.values.asNameMap()[sourceName] ??
          SkillLevelSource.teacherSet,
      masteryPercent: (map['masteryPercent'] as num?)?.toDouble() ?? 0,
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
    );
  }

  StudentSkillLevel copyWith({
    SkillArea? skill,
    SkillTier? tier,
    String? skillKey,
    SkillLevelSource? source,
    double? masteryPercent,
    DateTime? updatedAt,
  }) {
    return StudentSkillLevel(
      skill: skill ?? this.skill,
      tier: tier ?? this.tier,
      skillKey: skillKey ?? this.skillKey,
      source: source ?? this.source,
      masteryPercent: masteryPercent ?? this.masteryPercent,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
