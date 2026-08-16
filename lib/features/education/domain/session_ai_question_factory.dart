import 'package:flutter/foundation.dart';

import '../../../data/models/education_question.dart';
import '../../../data/models/skill_level.dart';
import '../../ai_content/data/caching_image_generation_service.dart';
import '../../ai_content/data/gemini_ai_services.dart';
import '../../ai_content/data/openai_ai_services.dart';
import '../../ai_content/data/pollinations_image_service.dart';
import '../../ai_content/domain/ai_content_services.dart';
import '../../ai_content/domain/image_quota_exception.dart';
import '../../ai_content/domain/question_image_spec.dart';
import '../../ai_content/domain/session_question_batch.dart';
import 'activity_engine.dart';

/// Oturum soruları + her soruya gerçek görsel (önbellek → API → yedek).
class SessionAiQuestionFactory {
  SessionAiQuestionFactory({
    required this.localGenerator,
    SessionQuestionBatchService? batch,
    ImageGenerationService? images,
    // Kota/hız: paralel 2 görsel.
    this.maxConcurrentImages = 2,
  })  : _batch = batch ?? _defaultBatch(),
        _images = images ?? _defaultImages();

  final QuestionGenerator localGenerator;
  final SessionQuestionBatchService _batch;
  final ImageGenerationService _images;
  final int maxConcurrentImages;

  static SessionQuestionBatchService _defaultBatch() {
    final gemini = GeminiAiContentService();
    if (gemini.isConfigured) return gemini;
    return OpenAiAiContentService();
  }

  static ImageGenerationService _defaultImages() {
    final gemini = GeminiImageGenerationService();
    if (gemini.isConfigured) return gemini;
    final openAi = OpenAiImageGenerationService();
    if (openAi.isConfigured) return openAi;
    return PollinationsImageGenerationService();
  }

  bool get canUseAi => _batch.isConfigured;

  Future<List<EducationQuestion>> build({
    required String category,
    required SkillTier difficulty,
    int count = 10,
    List<String> excludeIds = const [],
  }) async {
    // Havuz biraz büyük tut — görselsizleri eleyince 10 kalsın.
    final poolCount = count + 4;
    List<EducationQuestion> questions;
    if (!canUseAi) {
      debugPrint('SessionAI: anahtar yok → yerel sorular + AI görseller');
      questions = localGenerator.generate(
        category: category,
        difficulty: difficulty,
        count: poolCount,
        excludeIds: excludeIds,
      );
    } else {
      try {
        questions = await _batch
            .generateSessionQuestions(
              skill: localGenerator.skill,
              category: category,
              difficulty: difficulty,
              count: poolCount,
              excludeHints: excludeIds,
            )
            .timeout(const Duration(seconds: 90));
        debugPrint('SessionAI: ${questions.length} AI soru üretildi');
      } catch (e) {
        debugPrint('SessionAI: soru API hata ($e) → yerel + görsel');
        questions = localGenerator.generate(
          category: category,
          difficulty: difficulty,
          count: poolCount,
          excludeIds: excludeIds,
        );
      }
    }

    final withImages = await _attachImages(questions);
    // Öğrenci: görseli hazır olmayan soruyu gösterme.
    final ready = withImages
        .where((q) => _hasUsableImage(q.imageUrl))
        .take(count)
        .toList();
    if (ready.isEmpty) {
      debugPrint('SessionAI: görselli soru yok — havuzu olduğu gibi dön');
      return withImages.take(count).toList();
    }
    debugPrint('SessionAI: ${ready.length}/$count görselli soru seçildi');
    return ready;
  }

  /// Sabit müfredat sorularına yalnızca eksik görselleri ekler (metin API yok).
  Future<List<EducationQuestion>> attachImagesTo(
    List<EducationQuestion> questions,
  ) async {
    final withImages = await _attachImages(questions);
    final ready = withImages
        .where((q) => _hasUsableImage(q.imageUrl))
        .toList();
    if (ready.isEmpty) return withImages;
    return ready;
  }

  static bool _hasUsableImage(String? url) {
    if (url == null || url.isEmpty) return false;
    if (url.startsWith('mock:')) return false;
    return url.startsWith('http') ||
        url.startsWith('data:image') ||
        url.startsWith('assets/');
  }

  Future<List<EducationQuestion>> _attachImages(
    List<EducationQuestion> questions,
  ) async {
    final out = List<EducationQuestion>.from(questions);
    var i = 0;
    while (i < out.length) {
      final chunk = out.skip(i).take(maxConcurrentImages).toList();
      final results = await Future.wait([
        for (final q in chunk) _imageFor(q),
      ]);
      for (var j = 0; j < chunk.length; j++) {
        final url = results[j];
        if (url == null) continue;
        final idx = i + j;
        final q = out[idx];
        out[idx] = EducationQuestion(
          id: q.id,
          category: q.category,
          skill: q.skill,
          difficulty: q.difficulty,
          instruction: q.instruction,
          questionText: q.questionText,
          imageUrl: url,
          solutionImageUrl: url,
          audioUrl: q.audioUrl,
          choices: q.choices,
          correctAnswer: q.correctAnswer,
          explanation: q.explanation,
          metadata: {
            ...q.metadata,
            'aiImage': true,
          },
        );
      }
      i += chunk.length;
    }
    final withImg =
        out.where((q) => _hasUsableImage(q.imageUrl)).length;
    debugPrint('SessionAI: $withImg/${out.length} soruya görsel bağlandı');
    return out;
  }

  Future<String?> _imageFor(EducationQuestion q) async {
    final existing = q.imageUrl;
    if (_hasUsableImage(existing)) return existing;

    final objects = <String>[];
    final rawObjs = q.metadata['objects'];
    if (rawObjs is List) {
      for (final o in rawObjs) {
        if (o is Map) {
          objects.add('${o['count'] ?? 1} ${o['type'] ?? 'nesne'}');
        } else {
          objects.add('$o');
        }
      }
    }
    var mustMatch = 0;
    if (rawObjs is List) {
      for (final o in rawObjs) {
        if (o is Map) mustMatch += (o['count'] as num?)?.toInt() ?? 0;
      }
    }
    final spec = QuestionImageSpec(
      sceneDescription: '${q.instruction}\n${q.questionText}',
      questionId: q.id,
      objects: objects,
      mustMatchCount: mustMatch > 0 ? mustMatch : null,
      consistencyGroupId: '${q.skill.name}_${q.category}',
    );

    try {
      final img = await _images
          .generateImageForQuestion(spec)
          .timeout(const Duration(seconds: 90));
      final path = img.assetPath;
      if (_hasUsableImage(path)) {
        debugPrint(
          '[SessionAI] image OK '
          '(${path!.substring(0, path.length.clamp(0, 48))}…)',
        );
        return path;
      }
    } on ImageQuotaExceededException catch (e) {
      debugPrint('[SessionAI] kota: $e — bu soru atlanacak');
      // Retry yok; görselsiz bırak → build() eler.
      return null;
    } catch (e) {
      debugPrint('SessionAI: image fail ($e)');
      if (_images is CachingImageGenerationService &&
          _images.quotaExhausted) {
        return null;
      }
    }
    return null;
  }
}
