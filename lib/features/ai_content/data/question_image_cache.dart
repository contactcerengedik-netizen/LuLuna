import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env.dart';
import '../domain/ai_content_models.dart';
import '../domain/question_image_spec.dart';

/// Soru görselleri: bir kez üret → kalıcı URL; sonraki gösterimde API yok.
class QuestionImageCache {
  QuestionImageCache(this._prefs, {SupabaseClient? supabase})
      : _supabase = supabase;

  final SharedPreferences _prefs;
  final SupabaseClient? _supabase;

  static const _indexKey = 'question_image_cache_v1';
  static const _pendingKey = 'question_image_pending_retry_v1';
  static const _maxInlineUrlChars = 180000;

  /// Oturum içi hızlı bakış (prefs’e yazmadan önce).
  final Map<String, String> _memory = {};

  static String keyForSpec(QuestionImageSpec spec) {
    // İçerik hash — questionId değişse bile aynı sahne tek üretim.
    final raw = [
      spec.sceneDescription.trim(),
      spec.objects.join('|'),
      '${spec.mustMatchCount ?? ''}',
      spec.consistencyGroupId ?? '',
    ].join('\u001f');
    return sha1.convert(utf8.encode(raw)).toString();
  }

  static String keyForPrompt(String prompt, {String? id}) {
    final raw = '${id ?? ''}\u001f${prompt.trim()}';
    return sha1.convert(utf8.encode(raw)).toString();
  }

  String? lookup(String cacheKey) {
    final mem = _memory[cacheKey];
    if (mem != null && mem.isNotEmpty) return mem;
    final map = _readIndex();
    final url = map[cacheKey];
    if (url != null && url.isNotEmpty) {
      _memory[cacheKey] = url;
      return url;
    }
    return null;
  }

  Future<void> put(String cacheKey, String url) async {
    if (url.isEmpty || url.startsWith('mock:')) return;
    _memory[cacheKey] = url;

    var storeUrl = url;
    // Büyük data URL → mümkünse Storage public URL.
    if (url.startsWith('data:image') && Env.hasSupabase && _supabase != null) {
      final uploaded = await _tryUploadDataUrl(cacheKey, url);
      if (uploaded != null) storeUrl = uploaded;
    }

    // Prefs’e yalnızca makul boyutta URL yaz (localStorage limiti).
    if (storeUrl.length > _maxInlineUrlChars) {
      debugPrint(
        '[ImageCache] URL çok büyük, yalnızca bellek: '
        '${storeUrl.length} chars key=$cacheKey',
      );
      return;
    }

    final map = _readIndex();
    map[cacheKey] = storeUrl;
    await _prefs.setString(_indexKey, jsonEncode(map));
    debugPrint('[ImageCache] kaydedildi key=$cacheKey');
  }

  Future<GeneratedImage?> cachedImage(
    String cacheKey, {
    required String prompt,
    String? description,
  }) async {
    final url = lookup(cacheKey);
    if (url == null) return null;
    debugPrint('[ImageCache] HIT key=$cacheKey');
    return GeneratedImage(
      prompt: prompt,
      assetPath: url,
      description: description ?? 'Önbellek görsel',
      isMock: false,
    );
  }

  Future<void> markPendingRetry(String cacheKey) async {
    final set = _readPending()..add(cacheKey);
    await _prefs.setString(_pendingKey, jsonEncode(set.toList()));
  }

  Set<String> pendingRetryKeys() => _readPending();

  Future<void> clearPendingRetry(String cacheKey) async {
    final set = _readPending()..remove(cacheKey);
    await _prefs.setString(_pendingKey, jsonEncode(set.toList()));
  }

  Map<String, String> _readIndex() {
    final raw = _prefs.getString(_indexKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in decoded.entries)
          if (e.value is String) e.key: e.value as String,
      };
    } catch (_) {
      return {};
    }
  }

  Set<String> _readPending() {
    final raw = _prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return {for (final e in list) '$e'};
    } catch (_) {
      return {};
    }
  }

  Future<String?> _tryUploadDataUrl(String cacheKey, String dataUrl) async {
    try {
      final client = _supabase;
      if (client == null) return null;
      final comma = dataUrl.indexOf(',');
      if (comma < 0) return null;
      final meta = dataUrl.substring(0, comma);
      final b64 = dataUrl.substring(comma + 1);
      final bytes = base64Decode(b64);
      final ext = meta.contains('jpeg') || meta.contains('jpg') ? 'jpg' : 'png';
      final path = 'question-images/$cacheKey.$ext';
      const bucket = 'question-images';
      await client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: ext == 'jpg' ? 'image/jpeg' : 'image/png',
            ),
          );
      final publicUrl = client.storage.from(bucket).getPublicUrl(path);
      debugPrint('[ImageCache] Supabase upload OK $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('[ImageCache] Supabase upload atlandı: $e');
      return null;
    }
  }
}
