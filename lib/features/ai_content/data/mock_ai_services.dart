import '../../../data/models/skill_keys.dart';
import '../../../data/models/skill_level.dart';
import '../domain/ai_content_models.dart';
import '../domain/ai_content_services.dart';
import '../domain/question_image_spec.dart';

/// API anahtarı olmadan çalışan içerik üretici.
class MockAiContentService implements AiContentService {
  @override
  Future<StructuredActivity> parseTeacherPrompt(String prompt) async {
    final r = await parseTeacherQuestion(
      prompt: prompt,
      validSkillKeys: SkillKeys.mvp,
    );
    return r.structured;
  }

  @override
  Future<TeacherAiParseResult> parseTeacherQuestion({
    required String prompt,
    required List<String> validSkillKeys,
    SkillTier? suggestedDifficulty,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final lower = prompt.toLowerCase();
    final difficulty = suggestedDifficulty ?? SkillTier.medium;

    if (lower.contains('yumurta') ||
        lower.contains('topla') ||
        lower.contains('elma')) {
      final key = validSkillKeys.contains(SkillKeys.addition)
          ? SkillKeys.addition
          : validSkillKeys.first;
      return TeacherAiParseResult(
        structured: StructuredActivity(
          activityType: 'teacher_ai_$key',
          difficulty: difficulty,
          instruction: 'Soruyu görsele bakarak çöz.',
          questionText: lower.contains('elma')
              ? 'Sepette 3 elma var. 2 elma daha geliyor. Toplam kaç elma olur?'
              : 'Ayşe’nin elinde 3 yumurta var. Buzdolabında 5 yumurta var. '
                  'Ayşe yumurtaları buzdolabına koyuyor. Kaç yumurta olur?',
          answer: lower.contains('elma') ? '5' : '8',
          choices: lower.contains('elma')
              ? const ['4', '5', '6', '7']
              : const ['6', '7', '8', '9'],
          characters: const [
            {'name': 'Ayşe'},
          ],
          objects: lower.contains('elma')
              ? const [
                  {'type': 'apple', 'count': 3},
                  {'type': 'apple', 'count': 2},
                ]
              : const [
                  {'type': 'egg', 'count': 3, 'location': 'hand'},
                  {'type': 'egg', 'count': 5, 'location': 'fridge'},
                ],
          operation: 'addition',
          explanation: lower.contains('elma') ? '3 + 2 = 5' : '3 + 5 = 8',
        ),
        skillKey: key,
        confidence: 0.92,
        imagePrompt:
            'Simple special-education illustration, plain background, countable objects only.',
      );
    }

    if (lower.contains('5n1k') || lower.contains('kim') || lower.contains('nerede')) {
      final key = validSkillKeys.contains(SkillKeys.fiveW1h)
          ? SkillKeys.fiveW1h
          : validSkillKeys.first;
      return TeacherAiParseResult(
        structured: StructuredActivity(
          activityType: 'teacher_ai_$key',
          difficulty: difficulty,
          instruction: 'Görsele bak, soruyu cevapla.',
          questionText: 'Kim markette elma alıyor?',
          answer: 'Çocuk',
          choices: const ['Çocuk', 'Kedi', 'Araba'],
          explanation: 'Mock 5N1K',
        ),
        skillKey: key,
        confidence: 0.85,
        imagePrompt: 'Child buying apples in a simple market aisle, plain background.',
      );
    }

    // Düşük güven — öğretmen seçsin
    return TeacherAiParseResult(
      structured: StructuredActivity(
        activityType: 'teacher_ai_pending',
        difficulty: difficulty,
        instruction: 'Metni oku ve doğru seçeneği işaretle.',
        questionText: prompt.trim().isEmpty
            ? 'Örnek soru: Hangisi bir meyvedir?'
            : prompt.trim(),
        answer: 'Elma',
        choices: const ['Elma', 'Masa', 'Araba'],
        explanation: 'Mock — kategori belirsiz, öğretmen seçmeli.',
      ),
      skillKey: null,
      confidence: 0.35,
      needsCategoryReview: true,
      imagePrompt: 'Simple fruit illustration, plain background.',
    );
  }
}

class MockImageGenerationService implements ImageGenerationService {
  /// Debug UI için geçerli 1×1 PNG (Image.memory ile gösterilir).
  static const kDebugPlaceholderDataUrl =
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAFUlEQVR42mNk+M9Qz0AEYBxVSF+FABJADveWkH6oAAAAAElFTkSuQmCC';

  @override
  Future<GeneratedImage> generate({required String prompt}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return GeneratedImage(
      prompt: prompt,
      description:
          'Mock görsel: özel eğitim kurallarına uygun sahne taslağı '
          '(gerçek API yok).',
      isMock: true,
      assetPath: kDebugPlaceholderDataUrl,
    );
  }

  @override
  Future<GeneratedImage> generateImageForQuestion(QuestionImageSpec spec) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final group = spec.consistencyGroupId ?? 'solo';
    final buf = StringBuffer()
      ..writeln('Special education illustration for children.')
      ..writeln('Style: ${spec.style}')
      ..writeln('Scene: ${spec.sceneDescription}')
      ..writeln('Question id: ${spec.questionId}')
      ..writeln('Consistency group: $group');
    if (spec.objects.isNotEmpty) {
      buf.writeln('Objects: ${spec.objects.join(', ')}');
    }
    if (spec.mustMatchCount != null) {
      buf.writeln('Count must match: ${spec.mustMatchCount}');
    }
    buf.writeln('- sade, düz arka plan');
    buf.writeln('- metinde olmayan obje eklenmesin');
    return GeneratedImage(
      prompt: buf.toString().trim(),
      description:
          'Mock soru görseli (#${spec.questionId}) — kota koruması.',
      isMock: true,
      assetPath: kDebugPlaceholderDataUrl,
    );
  }
}
