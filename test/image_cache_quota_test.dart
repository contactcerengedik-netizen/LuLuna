import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luluna/features/ai_content/data/caching_image_generation_service.dart';
import 'package:luluna/features/ai_content/data/question_image_cache.dart';
import 'package:luluna/features/ai_content/domain/ai_content_models.dart';
import 'package:luluna/features/ai_content/domain/ai_content_services.dart';
import 'package:luluna/features/ai_content/domain/image_quota_exception.dart';
import 'package:luluna/features/ai_content/domain/question_image_spec.dart';

class _CountingImages implements ImageGenerationService {
  var calls = 0;

  @override
  Future<GeneratedImage> generate({required String prompt}) async {
    calls++;
    return GeneratedImage(
      prompt: prompt,
      assetPath: 'https://example.com/img_$calls.png',
      isMock: false,
    );
  }

  @override
  Future<GeneratedImage> generateImageForQuestion(QuestionImageSpec spec) async {
    calls++;
    return GeneratedImage(
      prompt: spec.sceneDescription,
      assetPath: 'https://example.com/q_${spec.questionId}_$calls.png',
      isMock: false,
    );
  }
}

class _QuotaImages implements ImageGenerationService {
  @override
  Future<GeneratedImage> generate({required String prompt}) async {
    throw const ImageQuotaExceededException();
  }

  @override
  Future<GeneratedImage> generateImageForQuestion(QuestionImageSpec spec) async {
    throw const ImageQuotaExceededException();
  }
}

void main() {
  late SharedPreferences prefs;
  late QuestionImageCache cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    cache = QuestionImageCache(prefs);
  });

  test('aynı soru 5 kez → API yalnız ilk sefer', () async {
    final inner = _CountingImages();
    final svc = CachingImageGenerationService(inner: inner, cache: cache);
    const spec = QuestionImageSpec(
      sceneDescription: '3 elma + 2 elma',
      questionId: 'q1',
      objects: ['3 elma', '2 elma'],
      mustMatchCount: 5,
    );

    for (var i = 0; i < 5; i++) {
      final img = await svc.generateImageForQuestion(spec);
      expect(img.assetPath, 'https://example.com/q_q1_1.png');
    }
    expect(inner.calls, 1);
  });

  test('kota sonrası Gemini tekrar çağrılmaz; fallback kullanılır', () async {
    final quota = _QuotaImages();
    final fallback = _CountingImages();
    final svc = CachingImageGenerationService(
      inner: quota,
      cache: cache,
      fallback: fallback,
    );
    const spec = QuestionImageSpec(
      sceneDescription: 'sahne',
      questionId: 'q2',
    );

    final a = await svc.generateImageForQuestion(spec);
    final b = await svc.generateImageForQuestion(spec);
    expect(a.assetPath, startsWith('https://example.com/'));
    expect(b.assetPath, a.assetPath);
    expect(svc.quotaExhausted, isTrue);
    expect(fallback.calls, 1); // ikinci sefer cache
  });

  test('prefs yeniden açılınca cache HIT', () async {
    final key = QuestionImageCache.keyForSpec(
      const QuestionImageSpec(
        sceneDescription: 'kalıcı sahne',
        questionId: 'q3',
      ),
    );
    await cache.put(key, 'https://cdn.example/cached.png');

    final prefs2 = await SharedPreferences.getInstance();
    final cache2 = QuestionImageCache(prefs2);
    expect(cache2.lookup(key), 'https://cdn.example/cached.png');
  });
}
