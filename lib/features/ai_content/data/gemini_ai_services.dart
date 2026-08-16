import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/env.dart';
import '../../../data/models/education_question.dart';
import '../../../data/models/skill_keys.dart';
import '../../../data/models/skill_level.dart';
import '../domain/ai_content_models.dart';
import '../domain/ai_content_services.dart';
import '../domain/image_quota_exception.dart';
import '../domain/question_image_spec.dart';
import '../domain/session_question_batch.dart';

/// Yerel CORS proxy (tools/gemini_cors_proxy.py).
const kGeminiProxyBase = String.fromEnvironment(
  'GEMINI_PROXY_URL',
  defaultValue: 'http://127.0.0.1:8791',
);

/// Gemini (native API) — AQ. / AIza anahtarları.
class GeminiAiContentService
    implements AiContentService, SessionQuestionBatchService {
  GeminiAiContentService({
    Dio? dio,
    String? apiKey,
    String? model,
  })  : _apiKey = apiKey ?? _resolveGeminiKey(),
        _model = model ??
            (Env.geminiModel.isNotEmpty ? Env.geminiModel : 'gemini-3.5-flash'),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 90),
                headers: const {'Content-Type': 'application/json'},
              ),
            );

  final Dio _dio;
  final String _apiKey;
  final String _model;

  static String _resolveGeminiKey() {
    if (Env.geminiApiKey.isNotEmpty) return Env.geminiApiKey;
    // Yanlışlıkla OPENAI alanına yapıştırılan AQ. anahtarları.
    final o = Env.openAiApiKey;
    if (o.startsWith('AQ.') || o.startsWith('AIza')) return o;
    return '';
  }

  @override
  bool get isConfigured => _apiKey.isNotEmpty || kIsWeb;

  @override
  Future<StructuredActivity> parseTeacherPrompt(String prompt) async {
    final result = await parseTeacherQuestion(
      prompt: prompt,
      validSkillKeys: SkillKeys.mvp,
    );
    return result.structured;
  }

  @override
  Future<TeacherAiParseResult> parseTeacherQuestion({
    required String prompt,
    required List<String> validSkillKeys,
    SkillTier? suggestedDifficulty,
  }) async {
    final catalog = validSkillKeys.map((k) => '- $k').join('\n');
    final hint = suggestedDifficulty == null
        ? ''
        : 'Prefer difficulty "${suggestedDifficulty.name}" if appropriate.\n';
    final raw = await _generateJson(
      '''
You are an educational content author for Turkish special-education children.
VALID skillKey values (pick EXACTLY one; never invent new keys):
$catalog
$hint
Return ONE JSON object with fields:
questionText, skillKey, difficulty (easy|medium|hard), confidence (0.0-1.0),
choices (array), correctAnswer, instruction, imagePrompt,
objects (array of {type,count,location?}), characters (array of {name}),
operation, explanation.
If unsure which skillKey fits, set confidence below 0.6.
Teacher prompt:
$prompt
''',
    );
    return TeacherAiParseResult.fromAiMap(raw, validSkillKeys: validSkillKeys);
  }

  @override
  Future<List<EducationQuestion>> generateSessionQuestions({
    required SkillArea skill,
    required String category,
    required SkillTier difficulty,
    int count = 10,
    List<String> excludeHints = const [],
  }) async {
    final excludeBlock = excludeHints.isEmpty
        ? ''
        : 'Avoid repeating these recent ideas:\n'
            '${excludeHints.take(12).map((e) => '- $e').join('\n')}\n';

    final raw = await _generateJson(
      '''
Generate exactly $count UNIQUE special-education questions in Turkish.
skill: ${skill.name}
category: $category
difficulty: ${difficulty.name}
$excludeBlock
Return JSON object: {"questions":[...]}
Each question:
- id, instruction, questionText, choices, correctAnswer, explanation
- type: "multipleChoice" | "sequence"
- for sequence: correctOrderLabels, cardIcons
- sceneCaption, objects [{type,count,location?}], characters [{name}], operation
Every question MUST use a different story/setting. Counts must match the math.
For five_w1h / event_ordering / word_ordering: type "sequence".
''',
    );

    final list = raw['questions'] as List? ?? const [];
    final out = <EducationQuestion>[];
    for (var i = 0; i < list.length; i++) {
      out.add(
        SessionQuestionMapper.fromAiMap(
          map: Map<String, dynamic>.from(list[i] as Map),
          index: i,
          skill: skill,
          category: category,
          difficulty: difficulty,
        ),
      );
    }
    if (out.isEmpty) throw StateError('Gemini boş soru listesi döndü');
    return out.take(count).toList();
  }

  Future<Map<String, dynamic>> _generateJson(String prompt) async {
    if (!isConfigured && !kIsWeb) {
      throw StateError('GEMINI_API_KEY tanımlı değil');
    }
    // Web: CORS → yerel proxy
    if (kIsWeb) {
      debugPrint(
        '[GeminiText] PROXY $kGeminiProxyBase/v1/generate-json model=$_model',
      );
      final proxy = Dio(
        BaseOptions(
          baseUrl: kGeminiProxyBase,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 90),
          // 404/429 gövdesini oku; ham DioException yerine anlamlı hata.
          validateStatus: (code) => code != null && code < 500,
        ),
      );
      final res = await proxy.post<Map<String, dynamic>>(
        '/v1/generate-json',
        data: {'prompt': prompt, 'model': _model},
      );
      final code = res.statusCode ?? 0;
      debugPrint(
        '[GeminiText] PROXY status=$code model=$_model '
        'body=${'${res.data}'.length > 200 ? '${res.data}'.substring(0, 200) : res.data}',
      );
      if (code == 404) {
        throw StateError(
          'Gemini metin modeli bulunamadı ($_model). '
          'config/gemini.json içinde GEMINI_MODEL=gemini-3.5-flash kullanın '
          '(gemini-2.0-flash kapatıldı).',
        );
      }
      if (code == 429 || ImageQuotaExceededException.matches('${res.data}')) {
        throw const ImageQuotaExceededException(
          'Günlük AI kota doldu, yarın tekrar deneyin.',
        );
      }
      if (code >= 400) {
        throw StateError('Gemini proxy hata $code: ${res.data?['error'] ?? res.data}');
      }
      final text = res.data?['text'] as String? ?? '';
      if (text.trim().isEmpty) throw StateError('Gemini proxy boş yanıt');
      final decoded = jsonDecode(text);
      if (decoded is! Map) throw StateError('Gemini JSON nesne değil');
      return Map<String, dynamic>.from(decoded);
    }

    if (!isConfigured) throw StateError('GEMINI_API_KEY tanımlı değil');
    debugPrint('[GeminiText] DIRECT model=$_model');
    final res = await _dio.post<Map<String, dynamic>>(
      '/models/$_model:generateContent',
      queryParameters: {'key': _apiKey},
      options: Options(headers: {'x-goog-api-key': _apiKey}),
      data: {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.85,
          'responseMimeType': 'application/json',
        },
      },
    );
    debugPrint('[GeminiText] status=${res.statusCode}');
    final text = _extractText(res.data);
    if (text == null || text.trim().isEmpty) {
      throw StateError('Gemini boş yanıt');
    }
    debugPrint(
      '[GeminiText] body=${text.length > 200 ? text.substring(0, 200) : text}',
    );
    final decoded = jsonDecode(text);
    if (decoded is! Map) throw StateError('Gemini JSON nesne değil');
    return Map<String, dynamic>.from(decoded);
  }

  static String? _extractText(Map<String, dynamic>? data) {
    final parts = data?['candidates']?[0]?['content']?['parts'] as List?;
    if (parts == null) return null;
    final buf = StringBuffer();
    for (final p in parts) {
      if (p is Map && p['text'] != null) buf.write(p['text']);
    }
    return buf.toString();
  }
}

/// Gemini native image — generateContent + inlineData (Imagen predict DEĞİL).
class GeminiImageGenerationService implements ImageGenerationService {
  GeminiImageGenerationService({
    Dio? dio,
    String? apiKey,
    String? imageModel,
  })  : _apiKey = apiKey ?? GeminiAiContentService._resolveGeminiKey(),
        imageModel = imageModel ??
            (Env.geminiImageModel.isNotEmpty
                ? Env.geminiImageModel
                : 'gemini-3.1-flash-image'),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 120),
                headers: const {'Content-Type': 'application/json'},
              ),
            );

  final Dio _dio;
  final String _apiKey;
  final String imageModel;

  bool get isConfigured => _apiKey.isNotEmpty || kIsWeb;

  @override
  Future<GeneratedImage> generate({required String prompt}) =>
      _generateDataUrl(prompt: prompt);

  @override
  Future<GeneratedImage> generateImageForQuestion(QuestionImageSpec spec) {
    final buf = StringBuffer()
      ..writeln(
        'Create a clear special-education illustration for young children.',
      )
      ..writeln('Simple flat background, high contrast, few objects only.')
      ..writeln('No decorative clutter, no extra people, no text overlays.')
      ..writeln('Scene: ${spec.sceneDescription}');
    if (spec.objects.isNotEmpty) {
      buf.writeln('Show only these objects: ${spec.objects.join(', ')}');
    }
    if (spec.mustMatchCount != null) {
      buf.writeln(
        'The countable items visible must total exactly ${spec.mustMatchCount}.',
      );
    }
    buf.writeln(
      'Friendly realistic-but-simple style, educational worksheet look.',
    );
    return _generateDataUrl(
      prompt: buf.toString().trim(),
      description: 'Gemini görsel #${spec.questionId}',
    );
  }

  Future<GeneratedImage> _generateDataUrl({
    required String prompt,
    String? description,
  }) async {
    final clipped =
        prompt.length > 3000 ? '${prompt.substring(0, 3000)}…' : prompt;

    // Web: CORS engeli → yerel proxy (tools/gemini_cors_proxy.py)
    if (kIsWeb) {
      debugPrint(
        '[GeminiImage] PROXY $kGeminiProxyBase/v1/generate-image '
        'model=$imageModel prompt_len=${clipped.length}',
      );
      final proxy = Dio(
        BaseOptions(
          baseUrl: kGeminiProxyBase,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ),
      );
      try {
        final res = await proxy.post<Map<String, dynamic>>(
          '/v1/generate-image',
          data: {'prompt': clipped, 'model': imageModel},
        );
        final dataUrl = res.data?['dataUrl'] as String?;
        debugPrint(
          '[GeminiImage] status=${res.statusCode} '
          'hasDataUrl=${dataUrl != null} '
          'prefix=${dataUrl == null ? 'null' : dataUrl.substring(0, dataUrl.length.clamp(0, 48))}',
        );
        if (dataUrl == null || !dataUrl.startsWith('data:image')) {
          final err = '${res.data?['error'] ?? res.data}';
          if (ImageQuotaExceededException.matches(err) ||
              res.statusCode == 429) {
            throw const ImageQuotaExceededException();
          }
          throw StateError('Proxy görsel dönmedi: $err');
        }
        return GeneratedImage(
          prompt: clipped,
          assetPath: dataUrl,
          description: description ?? 'Gemini eğitici görsel',
          isMock: false,
        );
      } on ImageQuotaExceededException {
        rethrow;
      } catch (e, st) {
        debugPrint('[GeminiImage] PROXY HATA: $e\n$st');
        if (e is DioException &&
            (e.response?.statusCode == 429 ||
                ImageQuotaExceededException.matches(e))) {
          throw const ImageQuotaExceededException();
        }
        if (ImageQuotaExceededException.matches(e)) {
          throw const ImageQuotaExceededException();
        }
        rethrow;
      }
    }

    if (!isConfigured) throw StateError('GEMINI_API_KEY tanımlı değil');

    final path = '/models/$imageModel:generateContent';
    final fullUrl =
        'https://generativelanguage.googleapis.com/v1beta$path';
    debugPrint('[GeminiImage] DIRECT url=$fullUrl model=$imageModel');
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        options: Options(headers: {'x-goog-api-key': _apiKey}),
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': clipped},
              ],
            },
          ],
          'generationConfig': {
            // Güncel image modelleri IMAGE (TEXT opsiyonel).
            'responseModalities': ['TEXT', 'IMAGE'],
          },
        },
      );
      final raw = jsonEncode(res.data);
      debugPrint(
        '[GeminiImage] status=${res.statusCode} '
        'body=${raw.length > 240 ? raw.substring(0, 240) : raw}',
      );
      final dataUrl = _parseGenerateContentImage(res.data);
      if (dataUrl == null) {
        throw StateError('Gemini görsel üretmedi (inlineData yok)');
      }
      return GeneratedImage(
        prompt: clipped,
        assetPath: dataUrl,
        description: description ?? 'Gemini eğitici görsel',
        isMock: false,
      );
    } on ImageQuotaExceededException {
      rethrow;
    } catch (e, st) {
      debugPrint('[GeminiImage] DIRECT HATA: $e\n$st');
      if (e is DioException) {
        final code = e.response?.statusCode;
        final body = '${e.response?.data}'.substring(
          0,
          '${e.response?.data}'.length.clamp(0, 400),
        );
        debugPrint('[GeminiImage] status=$code body=$body');
        if (code == 429 || ImageQuotaExceededException.matches(e)) {
          throw const ImageQuotaExceededException();
        }
      }
      if (ImageQuotaExceededException.matches(e)) {
        throw const ImageQuotaExceededException();
      }
      rethrow;
    }
  }

  static String? _parseGenerateContentImage(Map<String, dynamic>? data) {
    final parts = data?['candidates']?[0]?['content']?['parts'] as List?;
    if (parts == null) return null;
    for (final p in parts) {
      if (p is! Map) continue;
      final inline = p['inlineData'] as Map? ?? p['inline_data'] as Map?;
      if (inline == null) continue;
      final b64 = inline['data'] as String?;
      final mime = inline['mimeType'] as String? ??
          inline['mime_type'] as String? ??
          'image/png';
      if (b64 != null && b64.isNotEmpty) return 'data:$mime;base64,$b64';
    }
    return null;
  }
}
