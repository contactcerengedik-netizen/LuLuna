import '../../../data/models/skill_level.dart';
import 'ai_content_models.dart';
import 'ai_content_services.dart';
import 'question_image_spec.dart';

class PipelineValidation {
  const PipelineValidation({
    required this.ok,
    this.issues = const [],
  });

  final bool ok;
  final List<String> issues;
}

/// Teacher Prompt → analiz → structured JSON → seviye → sahne planı →
/// görsel prompt → görsel → önizleme (öğrenciye gitmez).
class EducationalContentPipeline {
  EducationalContentPipeline({
    required AiContentService content,
    required ImageGenerationService images,
    SpecialEducationVisualPromptBuilder? visualBuilder,
  })  : _content = content,
        _images = images,
        _visual = visualBuilder ?? SpecialEducationVisualPromptBuilder();

  final AiContentService _content;
  final ImageGenerationService _images;
  final SpecialEducationVisualPromptBuilder _visual;

  Future<TeacherAiActivity> generate({
    required String teacherPrompt,
    required String id,
  }) async {
    final analysis = analyzePrompt(teacherPrompt);
    final structured = await _content.parseTeacherPrompt(teacherPrompt);
    final adapted = _adaptDifficulty(structured, analysis);
    final scenePlan = VisualScenePlan.fromStructured(adapted);
    final visualPrompt = _visual.build(adapted, scenePlan: scenePlan);
    final image = await _images.generateImageForQuestion(
      QuestionImageSpec(
        sceneDescription: adapted.questionText,
        questionId: id,
        objects: [
          for (final o in adapted.objects) '${o['type'] ?? 'object'}',
        ],
        mustMatchCount: int.tryParse(adapted.answer),
        consistencyGroupId: id,
      ),
    );
    final validation = validate(adapted);
    final explained = validation.ok
        ? adapted
        : adapted.copyWith(
            explanation:
                '${adapted.explanation ?? ''}\nUyarı: ${validation.issues.join('; ')}'
                    .trim(),
          );
    return TeacherAiActivity(
      id: id,
      teacherPrompt: teacherPrompt,
      structured: explained,
      visualPrompt: visualPrompt,
      image: image,
      status: AiActivityStatus.preview,
      createdAt: DateTime.now(),
      analysis: analysis,
      scenePlan: scenePlan,
    );
  }

  /// Kişi / nesne / sayı / işlem çıkarımı (mock-friendly, deterministik).
  ContentAnalysis analyzePrompt(String prompt) {
    final lower = prompt.toLowerCase();
    final people = <String>[];
    for (final name in const ['ayşe', 'ahmet', 'mehmet', 'zeynep', 'merve']) {
      if (lower.contains(name)) {
        people.add(name[0].toUpperCase() + name.substring(1));
      }
    }
    final objects = <String>[];
    for (final o in const [
      'yumurta',
      'elma',
      'kitap',
      'kalem',
      'top',
      'buzdolab',
    ]) {
      if (lower.contains(o)) objects.add(o);
    }
    final numbers = RegExp(r'\d+')
        .allMatches(prompt)
        .map((m) => int.tryParse(m.group(0)!) ?? 0)
        .where((n) => n > 0)
        .toList();

    String? operation;
    if (lower.contains('topla') ||
        lower.contains('+') ||
        lower.contains('koyuyor') ||
        lower.contains('kaç oldu') ||
        lower.contains('kaç yumurta') ||
        lower.contains('toplam') ||
        (objects.contains('yumurta') && numbers.length >= 2)) {
      operation = 'addition';
    } else if (lower.contains('çıkar') ||
        lower.contains('-') ||
        lower.contains('kalır') ||
        lower.contains('yiyor')) {
      operation = 'subtraction';
    } else if (lower.contains('kim') ||
        lower.contains('nerede') ||
        lower.contains('5n1k')) {
      operation = '5n1k';
    }

    return ContentAnalysis(
      people: people,
      objects: objects,
      numbers: numbers,
      operation: operation,
      notes: const ['Analiz mock serviste tamamlandı'],
    );
  }

  StructuredActivity _adaptDifficulty(
    StructuredActivity a,
    ContentAnalysis analysis,
  ) {
    final n = int.tryParse(a.answer) ??
        (analysis.numbers.isEmpty
            ? null
            : analysis.numbers.reduce((x, y) => x > y ? x : y));
    if (n == null) return a;
    final tier = n <= 10
        ? SkillTier.easy
        : n <= 20
            ? SkillTier.medium
            : SkillTier.hard;
    if (a.difficulty == tier) return a;
    return a.copyWith(difficulty: tier);
  }

  PipelineValidation validate(StructuredActivity a) {
    final issues = <String>[];
    if (a.questionText.trim().isEmpty) issues.add('Soru metni boş');
    if (a.answer.trim().isEmpty) issues.add('Doğru cevap boş');
    if (a.choices.isNotEmpty && !a.choices.contains(a.answer)) {
      issues.add('Doğru cevap şıklarda yok (önizlemede düzeltilebilir)');
    }
    final countSum = a.objects.fold<int>(0, (s, o) {
      final c = o['count'];
      if (c is int) return s + c;
      return s + (int.tryParse('$c') ?? 0);
    });
    final ans = int.tryParse(a.answer);
    if (a.operation == 'addition' &&
        ans != null &&
        countSum > 0 &&
        countSum != ans) {
      issues.add('Nesne sayıları cevap ile uyuşmuyor ($countSum ≠ $ans)');
    }
    return PipelineValidation(ok: issues.isEmpty, issues: issues);
  }
}
