import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/env.dart';
import '../models/auth_session.dart';
import 'auth_repository.dart';

/// Gerçek Supabase Auth.
/// KVKK kayıtta istenmez; ilk giriş sonrası consent ekranında alınır.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._prefs, this._client);

  final SharedPreferences _prefs;
  final sb.SupabaseClient _client;

  static String _kvkkUserKey(String userId) => 'kvkk_$userId';
  static String _kvkkEmailKey(String email) => 'kvkk_email_$email';

  KvkkConsent _loadKvkkLocal({String? userId, String? email}) {
    if (userId != null) {
      final raw = _prefs.getString(_kvkkUserKey(userId));
      if (raw != null) {
        return KvkkConsent.fromMap(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      }
    }
    if (email != null) {
      final raw = _prefs.getString(_kvkkEmailKey(email.trim().toLowerCase()));
      if (raw != null) {
        return KvkkConsent.fromMap(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      }
    }
    return const KvkkConsent();
  }

  Future<void> _saveKvkkLocal({
    required String userId,
    required String email,
    required KvkkConsent kvkk,
  }) async {
    final json = jsonEncode(kvkk.toMap());
    await _prefs.setString(_kvkkUserKey(userId), json);
    await _prefs.setString(_kvkkEmailKey(email.trim().toLowerCase()), json);
  }

  @override
  AuthSession? loadSession() {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _toSession(user);
  }

  AuthSession _toSession(sb.User user) {
    final providerMeta = user.appMetadata['provider'] as String?;
    final providers = user.appMetadata['providers'];
    final isGoogle = providerMeta == 'google' ||
        (providers is List && providers.contains('google'));
    final meta = user.userMetadata ?? const <String, dynamic>{};
    final displayName = meta['full_name'] as String? ??
        meta['name'] as String? ??
        meta['display_name'] as String?;
    return AuthSession(
      userId: user.id,
      email: user.email ?? '',
      displayName: displayName,
      provider: isGoogle ? AuthProviderType.google : AuthProviderType.email,
      signedInAt: DateTime.tryParse(user.lastSignInAt ?? '') ?? DateTime.now(),
      kvkk: _loadKvkkLocal(userId: user.id, email: user.email),
    );
  }

  Future<void> _upsertCloudRecords(sb.User user, KvkkConsent kvkk) async {
    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'display_name': user.userMetadata?['display_name'],
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (kvkk.isComplete) {
        await _client.from('kvkk_consents').upsert({
          'user_id': user.id,
          'privacy_notice': kvkk.privacyNotice,
          'data_processing': kvkk.dataProcessing,
          'health_data': kvkk.healthData,
          'mic_camera': kvkk.micCamera,
          'consented_at': (kvkk.consentedAt ?? DateTime.now())
              .toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Supabase profil/KVKK upsert ertelendi: $e');
    }
  }

  Future<KvkkConsent?> _fetchKvkkFromCloud(String userId) async {
    try {
      final row = await _client
          .from('kvkk_consents')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return null;
      return KvkkConsent(
        privacyNotice: row['privacy_notice'] as bool? ?? false,
        dataProcessing: row['data_processing'] as bool? ?? false,
        healthData: row['health_data'] as bool? ?? false,
        micCamera: row['mic_camera'] as bool? ?? false,
        consentedAt: row['consented_at'] != null
            ? DateTime.tryParse(row['consented_at'] as String)
            : null,
      );
    } catch (e) {
      debugPrint('KVKK buluttan okunamadı: $e');
      return null;
    }
  }

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

    try {
      final res = await _client.auth.signUp(
        email: normalized,
        password: password,
        data: {
          if (displayName != null && displayName.trim().isNotEmpty)
            'display_name': displayName.trim(),
        },
      );
      if (res.user == null) {
        throw AuthException('Kayıt başarısız oldu, tekrar deneyin.');
      }
      // Oturum açılmışsa kapat — kullanıcı Giriş sekmesinden devam eder.
      if (res.session != null) {
        await _client.auth.signOut();
      }
    } on sb.AuthApiException catch (e) {
      throw AuthException(_friendly(e));
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<AuthSession> signInEmail({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    try {
      final res = await _client.auth.signInWithPassword(
        email: normalized,
        password: password,
      );
      final user = res.user;
      if (user == null) {
        throw AuthException('Giriş başarısız oldu, tekrar deneyin.');
      }

      var kvkk = _loadKvkkLocal(userId: user.id, email: normalized);
      if (!kvkk.isComplete) {
        final remote = await _fetchKvkkFromCloud(user.id);
        if (remote != null && remote.isComplete) {
          kvkk = remote;
          await _saveKvkkLocal(userId: user.id, email: normalized, kvkk: kvkk);
        }
      }

      try {
        await _client.from('profiles').upsert({
          'id': user.id,
          'email': user.email,
          'display_name': user.userMetadata?['display_name'],
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Profil upsert ertelendi: $e');
      }

      return _toSession(user);
    } on sb.AuthApiException catch (e) {
      throw AuthException(_friendly(e));
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
  }

  @override
  Future<AuthSession> signInWithGoogle() async {
    if (!Env.hasGoogleSignIn) {
      throw AuthException(
        'Google girişi için config/gemini.json içine '
        'GOOGLE_WEB_CLIENT_ID ekleyin (Google Cloud Web OAuth istemcisi).',
      );
    }

    try {
      final google = GoogleSignIn.instance;
      await google.initialize(
        clientId:
            Env.googleIosClientId.isEmpty ? null : Env.googleIosClientId,
        serverClientId: Env.googleWebClientId,
      );

      final account = await google.authenticate(
        scopeHint: const ['email', 'profile'],
      );
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw AuthException(
          'Google kimlik jetonu alınamadı. Web Client ID ve '
          'Android SHA-1 / iOS bundle ayarlarını kontrol edin.',
        );
      }

      String? accessToken;
      try {
        final silent = await account.authorizationClient
            .authorizationForScopes(const ['email', 'profile']);
        accessToken = silent?.accessToken;
        if (accessToken == null) {
          final prompted = await account.authorizationClient.authorizeScopes(
            const ['email', 'profile'],
          );
          accessToken = prompted.accessToken;
        }
      } catch (e) {
        debugPrint('Google accessToken alınamadı (idToken yeterli): $e');
      }

      final res = await _client.auth.signInWithIdToken(
        provider: sb.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      final user = res.user;
      if (user == null) {
        throw AuthException('Google girişi başarısız oldu, tekrar deneyin.');
      }

      var kvkk = _loadKvkkLocal(userId: user.id, email: user.email);
      if (!kvkk.isComplete) {
        final remote = await _fetchKvkkFromCloud(user.id);
        if (remote != null && remote.isComplete) {
          kvkk = remote;
          await _saveKvkkLocal(
            userId: user.id,
            email: user.email ?? '',
            kvkk: kvkk,
          );
        }
      }

      try {
        await _client.from('profiles').upsert({
          'id': user.id,
          'email': user.email,
          'display_name': user.userMetadata?['full_name'] ??
              user.userMetadata?['name'] ??
              user.userMetadata?['display_name'],
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Profil upsert ertelendi: $e');
      }

      return _toSession(user);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthException('Google girişi iptal edildi.');
      }
      throw AuthException(
        'Google girişi başarısız: ${e.description ?? e.code.name}',
      );
    } on sb.AuthApiException catch (e) {
      throw AuthException(_friendly(e));
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Google girişi başarısız: $e');
    }
  }

  @override
  Future<void> updateKvkk(KvkkConsent kvkk) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final stamped = kvkk.copyWith(consentedAt: DateTime.now());
    await _saveKvkkLocal(
      userId: user.id,
      email: user.email ?? '',
      kvkk: stamped,
    );
    await _upsertCloudRecords(user, stamped);
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Google oturumu yoksa sorun değil.
    }
    await _client.auth.signOut();
  }
  @override
  Future<void> deleteAccount() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthException('Silinecek aktif oturum yok.');
    }
    final email = user.email ?? '';
    try {
      await _client.rpc('delete_own_account');
    } on sb.PostgrestException catch (e) {
      throw AuthException('Hesap silinemedi: ${e.message}');
    } on sb.AuthException catch (e) {
      throw AuthException(e.message);
    }
    await _prefs.remove(_kvkkUserKey(user.id));
    if (email.isNotEmpty) {
      await _prefs.remove(_kvkkEmailKey(email));
    }
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Hesap zaten silinmiş olabilir.
    }
  }

  static String _friendly(sb.AuthApiException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'E-posta veya şifre hatalı.';
    }
    if (msg.contains('email not confirmed')) {
      return 'E-posta henüz doğrulanmadı. Gelen kutunuzu kontrol edin.';
    }
    if (msg.contains('already registered') ||
        msg.contains('already been registered')) {
      return 'Bu e-posta zaten kayıtlı. Giriş yapın.';
    }
    if (msg.contains('rate limit')) {
      return 'Çok fazla deneme yapıldı. Biraz bekleyip tekrar deneyin.';
    }
    return e.message;
  }
}
