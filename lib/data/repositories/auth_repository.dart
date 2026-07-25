import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session.dart';

/// Kimlik doğrulama arayüzü.
///
/// KVKK kayıtta istenmez; ilk giriş sonrası ayrı ekranda alınır.
abstract class AuthRepository {
  AuthSession? loadSession();

  /// Hesap oluşturur; oturum açmaz (kullanıcı giriş yapmalı).
  Future<void> registerEmail({
    required String email,
    required String password,
    String? displayName,
  });

  Future<AuthSession> signInEmail({
    required String email,
    required String password,
  });

  Future<AuthSession> signInWithGoogle();

  Future<void> updateKvkk(KvkkConsent kvkk);

  Future<void> signOut();
}

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _sessionKey = 'auth_session';
  static const _accountsKey = 'auth_accounts';
  static const _namesKey = 'auth_display_names';
  static const _kvkkByEmailKey = 'kvkk_by_email';

  @override
  AuthSession? loadSession() {
    final raw = _prefs.getString(_sessionKey);
    if (raw == null) return null;
    return AuthSession.fromJson(raw);
  }

  Future<void> _saveSession(AuthSession session) =>
      _prefs.setString(_sessionKey, session.toJson());

  Map<String, String> _accounts() {
    final raw = _prefs.getString(_accountsKey);
    if (raw == null) return {};
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  Future<void> _saveAccounts(Map<String, String> accounts) =>
      _prefs.setString(_accountsKey, jsonEncode(accounts));

  Map<String, String> _names() {
    final raw = _prefs.getString(_namesKey);
    if (raw == null) return {};
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  Future<void> _saveNames(Map<String, String> names) =>
      _prefs.setString(_namesKey, jsonEncode(names));

  Map<String, dynamic> _kvkkMap() {
    final raw = _prefs.getString(_kvkkByEmailKey);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _saveKvkkForEmail(String email, KvkkConsent kvkk) async {
    final map = _kvkkMap();
    map[email] = kvkk.toMap();
    await _prefs.setString(_kvkkByEmailKey, jsonEncode(map));
  }

  KvkkConsent _loadKvkkForEmail(String email) {
    final entry = _kvkkMap()[email];
    if (entry is! Map) return const KvkkConsent();
    return KvkkConsent.fromMap(Map<String, dynamic>.from(entry));
  }

  static String hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  @override
  Future<void> registerEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw AuthException('Geçerli bir e-posta girin.');
    }
    if (password.length < 6) {
      throw AuthException('Şifre en az 6 karakter olmalı.');
    }

    final accounts = _accounts();
    if (accounts.containsKey(normalized)) {
      throw AuthException('Bu e-posta zaten kayıtlı. Giriş yapın.');
    }
    accounts[normalized] = hashPassword(password);
    await _saveAccounts(accounts);

    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      final names = _names()..[normalized] = name;
      await _saveNames(names);
    }

    // KVKK henüz yok; ilk girişte alınacak. Oturum açılmaz.
    await _prefs.remove(_sessionKey);
  }

  @override
  Future<AuthSession> signInEmail({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    final accounts = _accounts();
    final stored = accounts[normalized];
    if (stored == null) {
      throw AuthException('Hesap bulunamadı. Önce kayıt olun.');
    }
    if (stored != hashPassword(password)) {
      throw AuthException('E-posta veya şifre hatalı.');
    }

    final session = AuthSession(
      userId: 'email_${normalized.hashCode.abs()}',
      email: normalized,
      displayName: _names()[normalized],
      provider: AuthProviderType.email,
      signedInAt: DateTime.now(),
      kvkk: _loadKvkkForEmail(normalized),
    );
    await _saveSession(session);
    return session;
  }

  @override
  Future<AuthSession> signInWithGoogle() async {
    const email = 'demo.user@gmail.com';
    final session = AuthSession(
      userId: 'google_demo_${email.hashCode.abs()}',
      email: email,
      displayName: 'Google Demo',
      provider: AuthProviderType.google,
      signedInAt: DateTime.now(),
      kvkk: _loadKvkkForEmail(email),
    );
    await _saveSession(session);
    return session;
  }

  @override
  Future<void> updateKvkk(KvkkConsent kvkk) async {
    final current = loadSession();
    if (current == null) return;
    final stamped = kvkk.copyWith(consentedAt: DateTime.now());
    await _saveKvkkForEmail(current.email, stamped);
    await _saveSession(current.copyWith(kvkk: stamped));
  }

  @override
  Future<void> signOut() async {
    await _prefs.remove(_sessionKey);
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
