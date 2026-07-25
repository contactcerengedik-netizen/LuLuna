import 'dart:convert';

/// Terapistin AI davranışını uzaktan (şimdilik yerel) güncellemek için
/// kullandığı serbest metin kuralları.
///
/// Örn: "Kalabalık ortamlarda komut verme, sadece nefes egzersizi yaptır."
class TherapistRules {
  const TherapistRules({this.rules = const []});

  final List<String> rules;

  bool get isEmpty => rules.isEmpty;

  TherapistRules copyWith({List<String>? rules}) =>
      TherapistRules(rules: rules ?? this.rules);

  Map<String, dynamic> toMap() => {'rules': rules};

  factory TherapistRules.fromMap(Map<String, dynamic> map) {
    return TherapistRules(
      rules: List<String>.from(map['rules'] as List? ?? const []),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory TherapistRules.fromJson(String source) =>
      TherapistRules.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
