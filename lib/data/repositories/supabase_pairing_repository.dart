import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/child_profile.dart';
import '../models/pairing_link.dart';
import 'pairing_repository.dart';

/// Eşleştirme kodları `pairing_codes` tablosunda tutulur; veli ve
/// terapist farklı cihazlarda eşleşebilir. Kod ve son eşleşme yerelde
/// de cache'lenir (senkron okuma için).
class SupabasePairingRepository implements PairingRepository {
  SupabasePairingRepository(this._prefs, this._client);

  final SharedPreferences _prefs;
  final SupabaseClient _client;

  String get _cacheSuffix {
    final id = _client.auth.currentUser?.id;
    return id == null ? '' : '_$id';
  }

  String get _myCodeKey => 'pairing_my_code$_cacheSuffix';
  String get _linkedCodeKey => 'pairing_linked_code$_cacheSuffix';
  String get _linkedLinkKey => 'pairing_linked_link$_cacheSuffix';

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw PairingException('Önce giriş yapın (oturum bulunamadı).');
    }
    return id;
  }

  @override
  String? loadMyInviteCode() => _prefs.getString(_myCodeKey);

  @override
  String? loadLinkedCode() => _prefs.getString(_linkedCodeKey);

  @override
  bool get isPairedAsTherapist => loadLinkedCode() != null;

  @override
  Future<PairingLink> createOrRefreshInvite({
    required ChildProfile profile,
    String? parentEmail,
  }) async {
    final uid = _uid;
    final code = generatePairingCode();
    final link = PairingLink(
      code: code,
      childName: profile.name,
      profileJson: profile.toJson(),
      createdAt: DateTime.now(),
      parentEmail: parentEmail,
    );

    try {
      // Velinin eski kodlarını temizle, yenisini yaz.
      await _client.from('pairing_codes').delete().eq('parent_id', uid);
      await _client.from('pairing_codes').insert({
        'code': code,
        'parent_id': uid,
        'child_name': link.childName,
        // jsonb kolonu: string değil, decode edilmiş obje gönderilir.
        'profile_json': jsonDecode(link.profileJson),
        'parent_email': parentEmail,
      });
    } on PostgrestException catch (e) {
      throw PairingException('Kod buluta yazılamadı: ${e.message}');
    }

    await _prefs.setString(_myCodeKey, code);
    return link;
  }

  @override
  Future<void> syncInviteProfile(ChildProfile profile) async {
    final code = loadMyInviteCode();
    if (code == null) return;
    try {
      await _client.from('pairing_codes').update({
        'child_name': profile.name,
        'profile_json': profile.toMap(),
      }).eq('code', code);
    } catch (e) {
      debugPrint('Davet kodu profili güncellenemedi: $e');
    }
  }

  @override
  Future<PairingLink> joinWithCode(String rawCode) async {
    final code = normalizePairingCode(rawCode);
    if (code.isEmpty) {
      throw PairingException('Lütfen davet kodunu girin.');
    }

    final Map<String, dynamic>? row;
    try {
      row = await _client
          .from('pairing_codes')
          .select()
          .eq('code', code)
          .maybeSingle();
    } on PostgrestException catch (e) {
      throw PairingException('Kod sorgulanamadı: ${e.message}');
    }

    if (row == null) {
      throw PairingException(
        'Kod bulunamadı. Velinin ürettiği güncel kodu kontrol edin.',
      );
    }

    // Kodu bu terapiste claim et (rapor erişimi RLS'te buna bakar).
    try {
      await _client
          .from('pairing_codes')
          .update({'claimed_by': _uid}).eq('code', code);
    } on PostgrestException catch (e) {
      throw PairingException('Eşleşme kaydedilemedi: ${e.message}');
    }

    final profileJson = row['profile_json'];
    final link = PairingLink(
      code: code,
      childName: row['child_name'] as String? ?? '',
      profileJson: profileJson is String
          ? profileJson
          : ChildProfile.fromMap(
              Map<String, dynamic>.from(profileJson as Map),
            ).toJson(),
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ??
              DateTime.now(),
      parentEmail: row['parent_email'] as String?,
    );

    await _prefs.setString(_linkedCodeKey, code);
    await _prefs.setString(_linkedLinkKey, link.toJson());
    return link;
  }

  @override
  PairingLink? loadLinkedLink() {
    final raw = _prefs.getString(_linkedLinkKey);
    if (raw == null) return null;
    return PairingLink.fromJson(raw);
  }

  @override
  Future<void> clearTherapistLink() async {
    final code = loadLinkedCode();
    if (code != null) {
      try {
        await _client
            .from('pairing_codes')
            .update({'claimed_by': null}).eq('code', code);
      } catch (e) {
        debugPrint('Claim geri alınamadı: $e');
      }
    }
    await _prefs.remove(_linkedCodeKey);
    await _prefs.remove(_linkedLinkKey);
  }

  @override
  Future<void> clearAll() async {
    final my = loadMyInviteCode();
    if (my != null) {
      try {
        await _client.from('pairing_codes').delete().eq('code', my);
      } catch (e) {
        debugPrint('Davet kodu silinemedi: $e');
      }
    }
    await _prefs.remove(_myCodeKey);
    await _prefs.remove(_linkedCodeKey);
    await _prefs.remove(_linkedLinkKey);
  }
}
