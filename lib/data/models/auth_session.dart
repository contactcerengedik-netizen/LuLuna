import 'dart:convert';

enum AuthProviderType { email, google }

/// KVKK / aydınlatma açık rıza seti. Mağaza ve avukat gereksinimleri için
/// dört onay da zorunlu.
class KvkkConsent {
  const KvkkConsent({
    this.privacyNotice = false,
    this.dataProcessing = false,
    this.healthData = false,
    this.micCamera = false,
    this.consentedAt,
  });

  final bool privacyNotice;
  final bool dataProcessing;
  final bool healthData;
  final bool micCamera;
  final DateTime? consentedAt;

  bool get isComplete =>
      privacyNotice && dataProcessing && healthData && micCamera;

  KvkkConsent copyWith({
    bool? privacyNotice,
    bool? dataProcessing,
    bool? healthData,
    bool? micCamera,
    DateTime? consentedAt,
  }) {
    return KvkkConsent(
      privacyNotice: privacyNotice ?? this.privacyNotice,
      dataProcessing: dataProcessing ?? this.dataProcessing,
      healthData: healthData ?? this.healthData,
      micCamera: micCamera ?? this.micCamera,
      consentedAt: consentedAt ?? this.consentedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'privacyNotice': privacyNotice,
        'dataProcessing': dataProcessing,
        'healthData': healthData,
        'micCamera': micCamera,
        'consentedAt': consentedAt?.toIso8601String(),
      };

  factory KvkkConsent.fromMap(Map<String, dynamic> map) => KvkkConsent(
        privacyNotice: map['privacyNotice'] as bool? ?? false,
        dataProcessing: map['dataProcessing'] as bool? ?? false,
        healthData: map['healthData'] as bool? ?? false,
        micCamera: map['micCamera'] as bool? ?? false,
        consentedAt: map['consentedAt'] != null
            ? DateTime.tryParse(map['consentedAt'] as String)
            : null,
      );
}

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.email,
    required this.provider,
    required this.signedInAt,
    this.displayName,
    this.kvkk = const KvkkConsent(),
  });

  final String userId;
  final String email;
  final String? displayName;
  final AuthProviderType provider;
  final DateTime signedInAt;
  final KvkkConsent kvkk;

  bool get isReady => kvkk.isComplete;

  AuthSession copyWith({KvkkConsent? kvkk, String? displayName}) {
    return AuthSession(
      userId: userId,
      email: email,
      displayName: displayName ?? this.displayName,
      provider: provider,
      signedInAt: signedInAt,
      kvkk: kvkk ?? this.kvkk,
    );
  }

  String toJson() => jsonEncode({
        'userId': userId,
        'email': email,
        'displayName': displayName,
        'provider': provider.name,
        'signedInAt': signedInAt.toIso8601String(),
        'kvkk': kvkk.toMap(),
      });

  factory AuthSession.fromJson(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return AuthSession(
      userId: map['userId'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      provider: AuthProviderType.values.asNameMap()[map['provider'] as String] ??
          AuthProviderType.email,
      signedInAt: DateTime.parse(map['signedInAt'] as String),
      kvkk: KvkkConsent.fromMap(
        Map<String, dynamic>.from(map['kvkk'] as Map? ?? {}),
      ),
    );
  }
}
