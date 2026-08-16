import 'package:flutter/foundation.dart';

import '../domain/ai_content_models.dart';
import '../domain/ai_content_services.dart';
import '../domain/image_quota_exception.dart';
import '../domain/question_image_spec.dart';
import 'question_image_cache.dart';

/// Üretim öncesi önbellek; kota bitince Gemini’ye tekrar gitmez.
class CachingImageGenerationService implements ImageGenerationService {
  CachingImageGenerationService({
    required ImageGenerationService inner,
    required QuestionImageCache cache,
    ImageGenerationService? fallback,
  })  : _inner = inner,
        _cache = cache,
        _fallback = fallback;

  final ImageGenerationService _inner;
  final QuestionImageCache _cache;
  final ImageGenerationService? _fallback;

  /// Oturum boyunca Gemini kotası dolduysa true — retry yok.
  bool quotaExhausted = false;

  @override
  Future<GeneratedImage> generate({required String prompt}) async {
    final key = QuestionImageCache.keyForPrompt(prompt);
    final hit = await _cache.cachedImage(key, prompt: prompt);
    if (hit != null) return hit;

    if (quotaExhausted) {
      return _fallbackOrThrow(prompt: prompt, cacheKey: key);
    }

    try {
      final img = await _inner.generate(prompt: prompt);
      final path = img.assetPath;
      if (path != null && path.isNotEmpty && !path.startsWith('mock:')) {
        await _cache.put(key, path);
        await _cache.clearPendingRetry(key);
      }
      return img;
    } on ImageQuotaExceededException {
      quotaExhausted = true;
      await _cache.markPendingRetry(key);
      return _fallbackOrThrow(prompt: prompt, cacheKey: key, rethrowQuota: true);
    } catch (e) {
      if (ImageQuotaExceededException.matches(e)) {
        quotaExhausted = true;
        await _cache.markPendingRetry(key);
        return _fallbackOrThrow(
          prompt: prompt,
          cacheKey: key,
          rethrowQuota: true,
        );
      }
      rethrow;
    }
  }

  @override
  Future<GeneratedImage> generateImageForQuestion(QuestionImageSpec spec) async {
    final key = QuestionImageCache.keyForSpec(spec);
    final promptHint = spec.sceneDescription;
    final hit = await _cache.cachedImage(
      key,
      prompt: promptHint,
      description: 'Önbellek #${spec.questionId}',
    );
    if (hit != null) return hit;

    if (quotaExhausted) {
      debugPrint('[CachingImage] kota dolu — API atlandı key=$key');
      return _fallbackOrThrowQuestion(spec: spec, cacheKey: key);
    }

    try {
      final img = await _inner.generateImageForQuestion(spec);
      final path = img.assetPath;
      if (path != null && path.isNotEmpty && !path.startsWith('mock:')) {
        await _cache.put(key, path);
        await _cache.clearPendingRetry(key);
      }
      return img;
    } on ImageQuotaExceededException {
      quotaExhausted = true;
      await _cache.markPendingRetry(key);
      return _fallbackOrThrowQuestion(
        spec: spec,
        cacheKey: key,
        rethrowQuota: true,
      );
    } catch (e) {
      if (ImageQuotaExceededException.matches(e)) {
        quotaExhausted = true;
        await _cache.markPendingRetry(key);
        return _fallbackOrThrowQuestion(
          spec: spec,
          cacheKey: key,
          rethrowQuota: true,
        );
      }
      // Kota değilse yedek dene (örn. Pollinations).
      final fb = _fallback;
      if (fb != null) {
        debugPrint('[CachingImage] primary hata ($e) → fallback');
        final img = await fb.generateImageForQuestion(spec);
        final path = img.assetPath;
        if (path != null && path.isNotEmpty && !path.startsWith('mock:')) {
          await _cache.put(key, path);
        }
        return img;
      }
      rethrow;
    }
  }

  Future<GeneratedImage> _fallbackOrThrow({
    required String prompt,
    required String cacheKey,
    bool rethrowQuota = false,
  }) async {
    final fb = _fallback;
    if (fb != null) {
      final img = await fb.generate(prompt: prompt);
      final path = img.assetPath;
      if (path != null && path.isNotEmpty && !path.startsWith('mock:')) {
        await _cache.put(cacheKey, path);
      }
      return img;
    }
    if (rethrowQuota || quotaExhausted) {
      throw const ImageQuotaExceededException();
    }
    throw StateError('Görsel üretilemedi');
  }

  Future<GeneratedImage> _fallbackOrThrowQuestion({
    required QuestionImageSpec spec,
    required String cacheKey,
    bool rethrowQuota = false,
  }) async {
    final fb = _fallback;
    if (fb != null) {
      final img = await fb.generateImageForQuestion(spec);
      final path = img.assetPath;
      if (path != null && path.isNotEmpty && !path.startsWith('mock:')) {
        await _cache.put(cacheKey, path);
      }
      return img;
    }
    if (rethrowQuota || quotaExhausted) {
      throw const ImageQuotaExceededException();
    }
    throw StateError('Görsel üretilemedi');
  }
}
