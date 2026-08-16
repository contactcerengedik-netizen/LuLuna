import 'package:dio/dio.dart';

import '../domain/ai_content_models.dart';
import '../domain/ai_content_services.dart';
import '../domain/question_image_spec.dart';

/// Tarayıcıda CORS’suz çalışan eğitici görsel (Pollinations / Flux).
/// Gemini web’de engellenince yedek; Windows’ta da yedek olarak kullanılır.
class PollinationsImageGenerationService implements ImageGenerationService {
  PollinationsImageGenerationService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 90),
                responseType: ResponseType.bytes,
                validateStatus: (s) => s != null && s < 500,
              ),
            );

  final Dio _dio;

  @override
  Future<GeneratedImage> generate({required String prompt}) =>
      _build(prompt: prompt);

  @override
  Future<GeneratedImage> generateImageForQuestion(QuestionImageSpec spec) {
    final buf = StringBuffer()
      ..write('Special education illustration for children, ')
      ..write('simple clear scene, soft colors, high contrast, ')
      ..write('no clutter, no text overlay, educational worksheet style. ')
      ..write(spec.sceneDescription);
    if (spec.objects.isNotEmpty) {
      buf.write(' Objects: ${spec.objects.join(', ')}.');
    }
    if (spec.mustMatchCount != null) {
      buf.write(' Exactly ${spec.mustMatchCount} countable items visible.');
    }
    return _build(
      prompt: buf.toString(),
      description: 'Eğitici görsel #${spec.questionId}',
    );
  }

  Future<GeneratedImage> _build({
    required String prompt,
    String? description,
  }) async {
    final clipped = prompt.length > 400 ? prompt.substring(0, 400) : prompt;
    final encoded = Uri.encodeComponent(clipped);
    final seed = clipped.hashCode.abs() % 100000;
    final uri = Uri.parse(
      'https://image.pollinations.ai/prompt/$encoded'
      '?width=1024&height=576&nologo=true&model=flux&seed=$seed',
    );
    // HEAD/GET doğrulaması — URL doğrudan Image.network ile açılır.
    try {
      await _dio.head(uri.toString());
    } catch (_) {
      // Bazı CDN’ler HEAD reddeder; URL yine geçerli olabilir.
    }
    return GeneratedImage(
      prompt: clipped,
      assetPath: uri.toString(),
      description: description ?? 'Pollinations eğitici görsel',
      isMock: false,
    );
  }
}
