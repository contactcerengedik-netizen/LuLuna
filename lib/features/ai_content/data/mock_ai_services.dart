import '../../../data/models/skill_level.dart';
import '../domain/ai_content_models.dart';
import '../domain/ai_content_services.dart';
import '../domain/question_image_spec.dart';

/// API anahtarı olmadan çalışan içerik üretici.
class MockAiContentService implements AiContentService {
  @override
  Future<StructuredActivity> parseTeacherPrompt(String prompt) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final lower = prompt.toLowerCase();

    // Yumurta örneği (prompt §27)
    if (lower.contains('yumurta') || lower.contains('buzdolab')) {
      return const StructuredActivity(
        activityType: 'math_addition',
        difficulty: SkillTier.medium,
        instruction: 'Soruyu görsele bakarak çöz.',
        questionText:
            'Ayşe’nin elinde 3 yumurta var. Buzdolabında 5 yumurta var. '
            'Ayşe yumurtaları buzdolabına koyuyor. Kaç yumurta olur?',
        answer: '8',
        choices: ['6', '7', '8', '9'],
        characters: [
          {'name': 'Ayşe'},
        ],
        objects: [
          {'type': 'egg', 'count': 3, 'location': 'hand'},
          {'type': 'egg', 'count': 5, 'location': 'fridge'},
        ],
        operation: 'addition',
        explanation: '3 + 5 = 8',
      );
    }

    final numbers = RegExp(r'\d+')
        .allMatches(prompt)
        .map((m) => int.tryParse(m.group(0)!) ?? 0)
        .where((n) => n > 0)
        .toList();
    if (numbers.length >= 2 &&
        (lower.contains('+') ||
            lower.contains('topla') ||
            lower.contains('kaç'))) {
      final a = numbers[0];
      final b = numbers[1];
      final sum = a + b;
      return StructuredActivity(
        activityType: 'math_addition',
        difficulty: SkillTier.easy,
        instruction: 'Toplamı bul.',
        questionText: '$a + $b = ?',
        answer: '$sum',
        choices: ['${sum - 1}', '$sum', '${sum + 1}', '${sum + 2}'],
        operation: 'addition',
        explanation: '$a + $b = $sum',
        objects: [
          {'type': 'item', 'count': a},
          {'type': 'item', 'count': b},
        ],
      );
    }

    return StructuredActivity(
      activityType: 'language_comprehension',
      difficulty: SkillTier.easy,
      instruction: 'Metni oku ve doğru seçeneği işaretle.',
      questionText: prompt.trim().isEmpty
          ? 'Örnek soru: Hangisi bir meyvedir?'
          : prompt.trim(),
      answer: 'Elma',
      choices: const ['Elma', 'Masa', 'Araba'],
      explanation: 'Mock içerik — API anahtarı yokken üretilir.',
    );
  }
}

class MockImageGenerationService implements ImageGenerationService {
  @override
  Future<GeneratedImage> generate({required String prompt}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return GeneratedImage(
      prompt: prompt,
      description:
          'Mock görsel: özel eğitim kurallarına uygun sahne taslağı '
          '(gerçek API yok).',
      isMock: true,
      assetPath: 'mock://legacy/${prompt.hashCode.abs()}',
    );
  }

  @override
  Future<GeneratedImage> generateImageForQuestion(QuestionImageSpec spec) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    // Aynı consistencyGroupId stil paylaşır; görsel URL her questionId için ayrı.
    final group = spec.consistencyGroupId ?? 'solo';
    final uniquePath =
        'mock://qimg/$group/${spec.questionId}/${spec.sceneDescription.hashCode.abs()}';
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
          'Mock soru görseli (#${spec.questionId}) — tekrar kullanılmaz.',
      isMock: true,
      assetPath: uniquePath,
    );
  }
}
