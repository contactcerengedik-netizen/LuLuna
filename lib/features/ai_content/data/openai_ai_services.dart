import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/env.dart';
import '../../../data/models/education_question.dart';
import '../../../data/models/skill_keys.dart';
import '../../../data/models/skill_level.dart';
import '../domain/ai_content_models.dart';
import '../domain/ai_content_services.dart';
import '../domain/question_image_spec.dart';
import '../domain/session_question_batch.dart';

/// OpenAI Chat Completions — yapılandırılmış eğitim soruları.
class OpenAiAiContentService
    implements AiContentService, SessionQuestionBatchService {
  OpenAiAiContentService({
    Dio? dio,
    String? apiKey,
    this.model = 'gpt-4o-mini',
  })  : _apiKey = apiKey ?? _normalizeOpenAiKey(Env.openAiApiKey),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.openai.com/v1',
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 90),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization':
                      'Bearer ${apiKey ?? _normalizeOpenAiKey(Env.openAiApiKey)}',
                },
              ),
            );

  final Dio _dio;
  final String _apiKey;
  final String model;

  /// Gemini AQ./AIza anahtarlarını OpenAI olarak kullanma.
  static String _normalizeOpenAiKey(String raw) {
    if (raw.startsWith('sk-')) return raw;
    return '';
  }

  @override
  bool get isConfigured => _apiKey.isNotEmpty;

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
    final raw = await _chatJson(
      system: '''
You author Turkish special-education questions.
VALID skillKey values only:
$catalog
Return ONE JSON with: questionText, skillKey, difficulty (easy|medium|hard),
confidence (0-1), choices, correctAnswer, instruction, imagePrompt,
objects, characters, operation, explanation.
If unsure, confidence < 0.6.
$hint
''',
      user: prompt,
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

    final raw = await _chatJson(
      system: _sessionSystemPrompt,
      user: '''
Generate exactly $count UNIQUE special-education questions in Turkish.
skill: ${skill.name}
category: $category
difficulty: ${difficulty.name}
$excludeBlock
Return JSON object:
{"questions":[ ... ]}
Each question object fields:
- id (string, unique)
- instruction (string)
- questionText (string)
- choices (string array; for sequence types use shuffled card labels)
- correctAnswer (string; for sequence: comma-separated correct order)
- explanation (string)
- type: "multipleChoice" | "sequence"
- for sequence: "correctOrderLabels" (string array in correct order), "cardIcons" (map label→icon name)
- sceneCaption (string, short visual caption)
- objects (array of {type, count, location?})
- characters (array of {name})
- operation (string|null)
Every question MUST use a different story/setting/objects. No egg fridge repeats unless unavoidable.
Counts in objects must match the math in the question.
For five_w1h / event_ordering / word_ordering / routine: use type "sequence".
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
    if (out.isEmpty) {
      throw StateError('OpenAI boş soru listesi döndü');
    }
    return out.take(count).toList();
  }

  Future<Map<String, dynamic>> _chatJson({
    required String system,
    required String user,
  }) async {
    if (!isConfigured) {
      throw StateError('OPENAI_API_KEY tanımlı değil');
    }
    final res = await _dio.post<Map<String, dynamic>>(
      '/chat/completions',
      data: {
        'model': model,
        'temperature': 0.85,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': user},
        ],
      },
    );
    final content =
        res.data?['choices']?[0]?['message']?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw StateError('OpenAI boş yanıt');
    }
    final decoded = jsonDecode(content);
    if (decoded is! Map) {
      throw StateError('OpenAI JSON nesne değil');
    }
    return Map<String, dynamic>.from(decoded);
  }

  static const _sessionSystemPrompt = '''
You create UNIQUE Turkish special-education quiz questions.
Prefer concrete everyday scenes (park, kitchen, school, beach, market, garden, bedroom).
Never reuse the same story across questions in one batch.
Keep language simple and clear. Multiple choice: exactly 4 choices when type is multipleChoice.
JSON only.
''';
}

/// OpenAI DALL·E 3 görsel üretimi.
class OpenAiImageGenerationService implements ImageGenerationService {
  OpenAiImageGenerationService({
    Dio? dio,
    String? apiKey,
    this.model = 'dall-e-3',
  })  : _apiKey = apiKey ??
            OpenAiAiContentService._normalizeOpenAiKey(Env.openAiApiKey),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.openai.com/v1',
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 120),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization':
                      'Bearer ${apiKey ?? OpenAiAiContentService._normalizeOpenAiKey(Env.openAiApiKey)}',
                },
              ),
            );

  final Dio _dio;
  final String _apiKey;
  final String model;
  final _promptBuilder = SpecialEducationVisualPromptBuilder();

  bool get isConfigured => _apiKey.isNotEmpty;

  @override
  Future<GeneratedImage> generate({required String prompt}) async {
    return _generateUrl(prompt: prompt);
  }

  @override
  Future<GeneratedImage> generateImageForQuestion(QuestionImageSpec spec) async {
    final buf = StringBuffer()
      ..writeln('Special education illustration for children.')
      ..writeln('Style: ${spec.style}')
      ..writeln('Scene: ${spec.sceneDescription}')
      ..writeln('Question id: ${spec.questionId}');
    if (spec.objects.isNotEmpty) {
      buf.writeln('Objects only: ${spec.objects.join(', ')}');
    }
    if (spec.mustMatchCount != null) {
      buf.writeln('Visible countable items must total: ${spec.mustMatchCount}');
    }
    for (final r in const VisualPromptRules().activeRuleLines()) {
      buf.writeln('- $r');
    }
    return _generateUrl(
      prompt: buf.toString().trim(),
      description: 'AI soru görseli #${spec.questionId}',
    );
  }

  /// StructuredActivity'den görsel (öğretmen pipeline).
  Future<GeneratedImage> generateForStructured(
    StructuredActivity activity, {
    VisualScenePlan? scenePlan,
  }) {
    final prompt = _promptBuilder.build(activity, scenePlan: scenePlan);
    return _generateUrl(prompt: prompt);
  }

  Future<GeneratedImage> _generateUrl({
    required String prompt,
    String? description,
  }) async {
    if (!isConfigured) {
      throw StateError('OPENAI_API_KEY tanımlı değil');
    }
    // DALL·E 3 prompt limiti ~4000; kırp.
    final clipped =
        prompt.length > 3500 ? '${prompt.substring(0, 3500)}…' : prompt;
    final res = await _dio.post<Map<String, dynamic>>(
      '/images/generations',
      data: {
        'model': model,
        'prompt': clipped,
        'n': 1,
        'size': '1024x1024',
        'quality': 'standard',
        'response_format': 'url',
      },
    );
    final url = res.data?['data']?[0]?['url'] as String?;
    if (url == null || url.isEmpty) {
      throw StateError('OpenAI görsel URL dönmedi');
    }
    return GeneratedImage(
      prompt: clipped,
      assetPath: url,
      description: description ?? 'OpenAI DALL·E 3 eğitici görsel',
      isMock: false,
    );
  }
}
