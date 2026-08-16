import 'skill_level.dart';

/// Erişilebilirlik tercihleri — kullanıcı bazında saklanır.
class AccessibilitySettings {
  const AccessibilitySettings({
    this.voiceInstructions = true,
    this.animationEnabled = false,
    this.textSize = TextScale.medium,
    this.soundEnabled = true,
    this.highContrast = false,
    this.reducedDistractionMode = true,
  });

  final bool voiceInstructions;
  final bool animationEnabled;
  final TextScale textSize;
  final bool soundEnabled;
  final bool highContrast;
  final bool reducedDistractionMode;

  AccessibilitySettings copyWith({
    bool? voiceInstructions,
    bool? animationEnabled,
    TextScale? textSize,
    bool? soundEnabled,
    bool? highContrast,
    bool? reducedDistractionMode,
  }) {
    return AccessibilitySettings(
      voiceInstructions: voiceInstructions ?? this.voiceInstructions,
      animationEnabled: animationEnabled ?? this.animationEnabled,
      textSize: textSize ?? this.textSize,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      highContrast: highContrast ?? this.highContrast,
      reducedDistractionMode:
          reducedDistractionMode ?? this.reducedDistractionMode,
    );
  }

  Map<String, dynamic> toMap() => {
    'voiceInstructions': voiceInstructions,
    'animationEnabled': animationEnabled,
    'textSize': textSize.name,
    'soundEnabled': soundEnabled,
    'highContrast': highContrast,
    'reducedDistractionMode': reducedDistractionMode,
  };

  factory AccessibilitySettings.fromMap(Map<String, dynamic> map) {
    return AccessibilitySettings(
      voiceInstructions: map['voiceInstructions'] as bool? ?? true,
      animationEnabled: map['animationEnabled'] as bool? ?? false,
      textSize: TextScale.values.asNameMap()[map['textSize']] ?? TextScale.medium,
      soundEnabled: map['soundEnabled'] as bool? ?? true,
      highContrast: map['highContrast'] as bool? ?? false,
      reducedDistractionMode: map['reducedDistractionMode'] as bool? ?? true,
    );
  }
}

enum TextScale { small, medium, large }

/// Öğrenci profili (eğitim platformu).
class StudentProfile {
  const StudentProfile({
    required this.id,
    required this.name,
    this.birthDate,
    this.createdAt,
    this.teacherIds = const [],
    this.skillLevels = const [],
    this.accessibility = const AccessibilitySettings(),
    this.preferences = const {},
  });

  final String id;
  final String name;
  final DateTime? birthDate;
  final DateTime? createdAt;
  final List<String> teacherIds;
  final List<StudentSkillLevel> skillLevels;
  final AccessibilitySettings accessibility;
  final Map<String, dynamic> preferences;

  SkillTier tierFor(SkillArea skill) {
    for (final s in skillLevels) {
      if (s.skill == skill) return s.tier;
    }
    return SkillTier.easy;
  }

  StudentProfile copyWith({
    String? id,
    String? name,
    DateTime? birthDate,
    DateTime? createdAt,
    List<String>? teacherIds,
    List<StudentSkillLevel>? skillLevels,
    AccessibilitySettings? accessibility,
    Map<String, dynamic>? preferences,
  }) {
    return StudentProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      createdAt: createdAt ?? this.createdAt,
      teacherIds: teacherIds ?? this.teacherIds,
      skillLevels: skillLevels ?? this.skillLevels,
      accessibility: accessibility ?? this.accessibility,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'birthDate': birthDate?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'teacherIds': teacherIds,
    'skillLevels': skillLevels.map((e) => e.toMap()).toList(),
    'accessibility': accessibility.toMap(),
    'preferences': preferences,
  };

  factory StudentProfile.fromMap(Map<String, dynamic> map) {
    return StudentProfile(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      birthDate: DateTime.tryParse(map['birthDate'] as String? ?? ''),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
      teacherIds: List<String>.from(map['teacherIds'] as List? ?? const []),
      skillLevels: [
        for (final e in (map['skillLevels'] as List? ?? const []))
          StudentSkillLevel.fromMap(Map<String, dynamic>.from(e as Map)),
      ],
      accessibility: AccessibilitySettings.fromMap(
        Map<String, dynamic>.from(
          map['accessibility'] as Map? ?? const {},
        ),
      ),
      preferences: Map<String, dynamic>.from(
        map['preferences'] as Map? ?? const {},
      ),
    );
  }
}
