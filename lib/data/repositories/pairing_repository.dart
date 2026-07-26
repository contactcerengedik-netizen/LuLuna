import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/child_profile.dart';
import '../models/pairing_link.dart';

/// Veli davet kodu üretimi + terapist eşleştirme arayüzü.
///
/// - `LocalPairingRepository`: aynı cihazda demo kayıt defteri.
/// - `SupabasePairingRepository`: kodlar bulutta; veli ve terapist
///   farklı cihazlarda eşleşebilir.
abstract class PairingRepository {
  String? loadMyInviteCode();

  String? loadLinkedCode();

  bool get isPairedAsTherapist;

  Future<PairingLink> createOrRefreshInvite({
    required ChildProfile profile,
    String? parentEmail,
  });

  Future<void> syncInviteProfile(ChildProfile profile);

  Future<PairingLink> joinWithCode(String rawCode);

  PairingLink? loadLinkedLink();

  Future<void> clearTherapistLink();

  Future<void> clearAll();
}

/// Kod üretimi — iki implementasyon da kullanır.
String generatePairingCode() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rng = Random.secure();
  final body = List.generate(
    4,
    (_) => alphabet[rng.nextInt(alphabet.length)],
  ).join();
  return 'LUNA-$body';
}

String normalizePairingCode(String rawCode) =>
    rawCode.trim().toUpperCase().replaceAll(' ', '');

/// Demo: yerel "kod → profil" kayıt defteri (tek cihaz).
/// Kod sahipliği ve eşleşme kullanıcıya göre ayrılır; kayıt defteri
/// (registry) ise cihaz genelinde ortaktır — bulut tablosunu taklit eder.
class LocalPairingRepository implements PairingRepository {
  LocalPairingRepository(this._prefs, {this.userId});

  final SharedPreferences _prefs;
  final String? userId;

  static const _registryKey = 'pairing_registry';

  String get _myCodeKey =>
      userId == null ? 'pairing_my_code' : 'pairing_my_code_$userId';

  String get _linkedCodeKey =>
      userId == null ? 'pairing_linked_code' : 'pairing_linked_code_$userId';

  @override
  String? loadMyInviteCode() => _prefs.getString(_myCodeKey);

  @override
  String? loadLinkedCode() => _prefs.getString(_linkedCodeKey);

  @override
  bool get isPairedAsTherapist => loadLinkedCode() != null;

  Map<String, dynamic> _registry() {
    final raw = _prefs.getString(_registryKey);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _saveRegistry(Map<String, dynamic> registry) =>
      _prefs.setString(_registryKey, jsonEncode(registry));

  @override
  Future<PairingLink> createOrRefreshInvite({
    required ChildProfile profile,
    String? parentEmail,
  }) async {
    final code = generatePairingCode();
    final link = PairingLink(
      code: code,
      childName: profile.name,
      profileJson: profile.toJson(),
      createdAt: DateTime.now(),
      parentEmail: parentEmail,
      parentId: userId,
    );
    final registry = _registry();
    final old = _prefs.getString(_myCodeKey);
    if (old != null) registry.remove(old);
    registry[code] = link.toMap();
    await _saveRegistry(registry);
    await _prefs.setString(_myCodeKey, code);
    return link;
  }

  @override
  Future<void> syncInviteProfile(ChildProfile profile) async {
    final code = loadMyInviteCode();
    if (code == null) return;
    final registry = _registry();
    final existing = registry[code];
    if (existing is! Map) return;
    final link = PairingLink.fromMap(Map<String, dynamic>.from(existing));
    registry[code] = PairingLink(
      code: code,
      childName: profile.name,
      profileJson: profile.toJson(),
      createdAt: link.createdAt,
      parentEmail: link.parentEmail,
      parentId: link.parentId,
    ).toMap();
    await _saveRegistry(registry);
  }

  @override
  Future<PairingLink> joinWithCode(String rawCode) async {
    final code = normalizePairingCode(rawCode);
    if (code.isEmpty) {
      throw PairingException('Lütfen davet kodunu girin.');
    }
    final registry = _registry();
    final entry = registry[code];
    if (entry is! Map) {
      throw PairingException(
        'Kod bulunamadı. Velinin ürettiği güncel kodu deneyin '
        '(aynı cihazda demo kayıt defteri kullanılır).',
      );
    }
    final link = PairingLink.fromMap(Map<String, dynamic>.from(entry));
    await _prefs.setString(_linkedCodeKey, code);
    return link;
  }

  @override
  PairingLink? loadLinkedLink() {
    final code = loadLinkedCode();
    if (code == null) return null;
    final entry = _registry()[code];
    if (entry is! Map) return null;
    return PairingLink.fromMap(Map<String, dynamic>.from(entry));
  }

  @override
  Future<void> clearTherapistLink() => _prefs.remove(_linkedCodeKey);

  @override
  Future<void> clearAll() async {
    final my = loadMyInviteCode();
    if (my != null) {
      final registry = _registry()..remove(my);
      await _saveRegistry(registry);
    }
    await _prefs.remove(_myCodeKey);
    await _prefs.remove(_linkedCodeKey);
  }
}

class PairingException implements Exception {
  PairingException(this.message);
  final String message;

  @override
  String toString() => message;
}
