import 'ai_content_models.dart';
import 'question_image_spec.dart';

/// LLM içerik servisi — API anahtarı yoksa mock kullanılır.
abstract class AiContentService {
  Future<StructuredActivity> parseTeacherPrompt(String prompt);
}

/// Görsel üretimi — provider değiştirilebilir.
/// Kural A: her soru kendi görselini alır; asset havuzundan seçilmez.
abstract class ImageGenerationService {
  Future<GeneratedImage> generate({required String prompt});

  /// Per-question üretim (v3 §2.2).
  Future<GeneratedImage> generateImageForQuestion(QuestionImageSpec spec);
}

class VisualPromptRules {
  const VisualPromptRules({
    this.simpleBackground = true,
    this.fewObjects = true,
    this.onlyNecessaryObjects = true,
    this.highVisualSeparation = true,
    this.clearObjectBoundaries = true,
    this.centerMainSubject = true,
    this.noDecoration = true,
    this.noDistractors = true,
    this.realisticButSimple = true,
    this.countsMustMatchMath = true,
    this.noExtraObjectsFromText = true,
    this.noUnnecessaryPeople = true,
    this.lowVisualComplexity = true,
  });

  final bool simpleBackground;
  final bool fewObjects;
  final bool onlyNecessaryObjects;
  final bool highVisualSeparation;
  final bool clearObjectBoundaries;
  final bool centerMainSubject;
  final bool noDecoration;
  final bool noDistractors;
  final bool realisticButSimple;
  final bool countsMustMatchMath;
  final bool noExtraObjectsFromText;
  final bool noUnnecessaryPeople;
  final bool lowVisualComplexity;

  List<String> activeRuleLines() {
    final lines = <String>[];
    if (simpleBackground) lines.add('sade, düz arka plan');
    if (fewObjects) lines.add('az sayıda nesne');
    if (onlyNecessaryObjects) lines.add('yalnızca gerekli nesneler');
    if (highVisualSeparation) lines.add('yüksek görsel ayrışma');
    if (clearObjectBoundaries) lines.add('net obje sınırları');
    if (centerMainSubject) lines.add('ana öğe merkezde');
    if (noDecoration) lines.add('gereksiz dekorasyon yok');
    if (noDistractors) lines.add('dikkat dağıtan nesne yok');
    if (realisticButSimple) lines.add('gerçekçi fakat basit');
    if (countsMustMatchMath) {
      lines.add('görseldeki sayılar matematiksel olarak doğru');
    }
    if (noExtraObjectsFromText) {
      lines.add('metinde olmayan obje eklenmesin');
    }
    if (noUnnecessaryPeople) lines.add('tek sahnede gereksiz insan yok');
    if (lowVisualComplexity) lines.add('düşük görsel karmaşıklık');
    return lines;
  }
}

/// Özel eğitim görsel prompt üretici.
class SpecialEducationVisualPromptBuilder {
  SpecialEducationVisualPromptBuilder({
    this.rules = const VisualPromptRules(),
  });

  final VisualPromptRules rules;

  String build(
    StructuredActivity activity, {
    VisualScenePlan? scenePlan,
  }) {
    final plan = scenePlan ?? VisualScenePlan.fromStructured(activity);
    final buf = StringBuffer();
    buf.writeln('Special education illustration for children.');
    buf.writeln('Background: ${plan.background}');
    buf.writeln('Main subject (centered): ${plan.mainSubject}');
    if (plan.elements.isNotEmpty) {
      buf.writeln('Scene elements (only these):');
      for (final e in plan.elements) {
        buf.writeln('- $e');
      }
    }
    buf.writeln('Instruction: ${activity.instruction}');
    buf.writeln('Scene question: ${activity.questionText}');
    if (activity.characters.isNotEmpty) {
      buf.writeln(
        'Characters: ${activity.characters.map((e) => e['name']).join(', ')}',
      );
    }
    if (activity.objects.isNotEmpty) {
      buf.writeln('Objects:');
      for (final o in activity.objects) {
        buf.writeln(
          '- ${o['count'] ?? 1} ${o['type'] ?? 'object'}'
          '${o['location'] != null ? ' (${o['location']})' : ''}',
        );
      }
    }
    if (activity.operation != null) {
      buf.writeln('Operation: ${activity.operation}, answer: ${activity.answer}');
    }
    buf.writeln('Forbidden:');
    for (final f in plan.forbidden) {
      buf.writeln('- $f');
    }
    buf.writeln('Style rules:');
    for (final r in rules.activeRuleLines()) {
      buf.writeln('- $r');
    }
    return buf.toString().trim();
  }
}
