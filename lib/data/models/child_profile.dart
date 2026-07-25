import 'dart:convert';

/// Velinin seçtiği, çocuğun en olumlu tepki verdiği yapay zeka ses tonu.
/// Adım 3'te TTS konfigürasyonuna ve system prompt'a yansıtılacak.
enum VoiceTone {
  compassionate('Şefkatli'),
  energetic('Enerjik'),
  calm('Sakin');

  const VoiceTone(this.label);

  final String label;
}

class ChildProfile {
  const ChildProfile({
    required this.name,
    this.triggers = const [],
    this.calmingItems = const [],
    this.voiceTone = VoiceTone.compassionate,
  });

  final String name;

  /// Fobiler ve tetikleyiciler (örn. "Yüksek ses", "Kalabalık").
  /// System prompt'a otomatik enjekte edilecek.
  final List<String> triggers;

  /// Çocuğu sakinleştiren şeyler (örn. "Annesinin sesi", "Klasik müzik").
  final List<String> calmingItems;

  final VoiceTone voiceTone;

  ChildProfile copyWith({
    String? name,
    List<String>? triggers,
    List<String>? calmingItems,
    VoiceTone? voiceTone,
  }) {
    return ChildProfile(
      name: name ?? this.name,
      triggers: triggers ?? this.triggers,
      calmingItems: calmingItems ?? this.calmingItems,
      voiceTone: voiceTone ?? this.voiceTone,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'triggers': triggers,
    'calmingItems': calmingItems,
    'voiceTone': voiceTone.name,
  };

  factory ChildProfile.fromMap(Map<String, dynamic> map) {
    return ChildProfile(
      name: map['name'] as String? ?? '',
      triggers: List<String>.from(map['triggers'] as List? ?? const []),
      calmingItems: List<String>.from(map['calmingItems'] as List? ?? const []),
      voiceTone: VoiceTone.values.asNameMap()[map['voiceTone']] ??
          VoiceTone.compassionate,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ChildProfile.fromJson(String source) =>
      ChildProfile.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
