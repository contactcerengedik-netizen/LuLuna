import 'dart:convert';

/// Veli tarafından üretilen davet kodu + çocuk profili anlık görüntüsü.
/// Supabase/Firebase gelince aynı şema uzak koleksiyona taşınır.
class PairingLink {
  const PairingLink({
    required this.code,
    required this.childName,
    required this.profileJson,
    required this.createdAt,
    this.parentEmail,
    this.parentId,
  });

  final String code;
  final String childName;
  final String profileJson;
  final DateTime createdAt;
  final String? parentEmail;
  final String? parentId;

  Map<String, dynamic> toMap() => {
    'code': code,
    'childName': childName,
    'profileJson': profileJson,
    'createdAt': createdAt.toIso8601String(),
    'parentEmail': parentEmail,
    'parentId': parentId,
  };

  String toJson() => jsonEncode(toMap());

  factory PairingLink.fromMap(Map<String, dynamic> map) => PairingLink(
    code: map['code'] as String,
    childName: map['childName'] as String,
    profileJson: map['profileJson'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
    parentEmail: map['parentEmail'] as String?,
    parentId: map['parentId'] as String?,
  );

  factory PairingLink.fromJson(String raw) =>
      PairingLink.fromMap(jsonDecode(raw) as Map<String, dynamic>);
}
