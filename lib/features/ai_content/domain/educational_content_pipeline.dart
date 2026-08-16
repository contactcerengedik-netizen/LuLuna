import '../../../data/models/skill_keys.dart';
import '../../../data/models/skill_level.dart';
import 'ai_content_models.dart';
import 'ai_content_services.dart';
import 'image_quota_exception.dart';
import 'question_image_spec.dart';

class PipelineValidation {
  const PipelineValidation({
    required this.ok,
    this.issues = const [],
  });

  final bool ok;
  final List<String> issues;
}

/// Teacher Prompt → kapalı skill_key → structured → görsel (tek sefer) → önizleme.
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
    SkillTier? suggestedDifficulty,
    String? targetStudentId,
    bool deferImageOnQuota = true,
  }) async {
    final analysis = analyzePrompt(teacherPrompt);
    final parsed = await _content.parseTeacherQuestion(
      prompt: teacherPrompt,
      validSkillKeys: SkillKeys.mvp,
      suggestedDifficulty: suggestedDifficulty,
    );
    var adapted = _adaptDifficulty(parsed.structured, analysis);
    if (suggestedDifficulty != null && parsed.confidence < 0.6) {
      adapted = adapted.copyWith(difficulty: suggestedDifficulty);
    }
    final scenePlan = VisualScenePlan.fromStructured(adapted);
    final visualPrompt = parsed.imagePrompt?.trim().isNotEmpty == true
        ? parsed.imagePrompt!.trim()
        : _visual.build(adapted, scenePlan: scenePlan);

    GeneratedImage image;
    var imagePending = false;
    var status = AiActivityStatus.preview;
    try {
      image = await _images.generateImageForQuestion(
        QuestionImageSpec(
          sceneDescription: visualPrompt,
          questionId: id,
          objects: [
            for (final o in adapted.objects) '${o['type'] ?? 'object'}',
          ],
          mustMatchCount: int.tryParse(adapted.answer),
          consistencyGroupId: id,
        ),
      );
    } on ImageQuotaExceededException {
      if (!deferImageOnQuota) rethrow;
      imagePending = true;
      status = AiActivityStatus.pendingRetry;
      image = GeneratedImage(
        prompt: visualPrompt,
        description: 'Görsel daha sonra eklenecek (kota)',
        isMock: true,
      );
    }

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
      status: status,
      createdAt: DateTime.now(),
      analysis: analysis,
      scenePlan: scenePlan,
      skillKey: parsed.skillKey,
      confidence: parsed.confidence,
      needsCategoryReview: parsed.needsCategoryReview,
      targetStudentId: targetStudentId,
      imagePending: imagePending,
      source: 'teacher_ai_generated',
    );
  }

  /// Tek seferlik görsel yeniden üretimi (önizlemede öğretmen isteği).
  Future<TeacherAiActivity> regenerateImage(TeacherAiActivity activity) async {
    final img = await _images.generateImageForQuestion(
      QuestionImageSpec(
        sceneDescription: activity.visualPrompt.isNotEmpty
            ? activity.visualPrompt
            : activity.structured.questionText,
        questionId: '${activity.id}_regen',
        objects: [
          for (final o in activity.structured.objects)
            '${o['type'] ?? 'object'}',
        ],
        mustMatchCount: int.tryParse(activity.structured.answer),
        consistencyGroupId: activity.id,
      ),
    );
    return activity.copyWith(
      image: img,
      imagePending: false,
      status: activity.status == AiActivityStatus.pendingRetry
          ? AiActivityStatus.preview
          : activity.status,
    );
  }

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
