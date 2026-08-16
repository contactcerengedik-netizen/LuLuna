import '../domain/concept_models.dart';
import '../domain/concept_orchestrator.dart';

/// Faz 17: tüm ConceptModule değerleri için generator — gerçek rota/içerik bağları.
class MockConceptModuleGenerator implements ConceptModuleGenerator {
  MockConceptModuleGenerator(this.module);

  @override
  final ConceptModule module;

  @override
  Future<ConceptModuleOutput> generate({
    required Concept concept,
    required ConceptAssignment assignment,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final seed =
        '${assignment.consistencyGroupId ?? assignment.id}_${module.name}_${concept.name}';
    return ConceptModuleOutput(
      id: '${assignment.id}_${module.name}',
      module: module,
      status: ConceptModuleOutputStatus.ready,
      generatedContentId: 'gen_$seed',
      imageSeed: seed,
      studentRoute: module.studentRoute,
      previewTitle: '${module.label}: ${concept.name}',
      previewBody: _body(concept),
    );
  }

  String _body(Concept concept) {
    final n = concept.name;
    return switch (module) {
      ConceptModule.counting =>
        'Kaç tane $n? (görsel seed ayrı; rota: matematik)',
      ConceptModule.mathematics =>
        '$n ile somut toplama / çarpma / kesir taslağı',
      ConceptModule.turkish =>
        '“$n” — kavram, eş/zıt, 5N1K, sıralama taslağı',
      ConceptModule.listening =>
        'Sesli cümle → $n görselini seç (dinleme)',
      ConceptModule.puzzle => '$n sahnesinden 3–5 parça puzzle',
      ConceptModule.matching =>
        '$n ile sınıflandırma / kategorileme kartları',
      ConceptModule.coloring =>
        '$n kontur boyama (CanvasEngine, flood-fill yok)',
      ConceptModule.tracing =>
        '$n harf/şekil path takibi (PathTracingEngine)',
      ConceptModule.pattern =>
        '$n temalı örüntü tamamlama / olay sıralama',
      ConceptModule.data =>
        '$n sayımlarıyla çetele / tablo / grafik sorusu',
      ConceptModule.memory =>
        '$n kart eşleştirme + kısa süreli bellek',
      ConceptModule.speech =>
        'Dialogue: “$n de” → STT keyword eşleşmesi',
      ConceptModule.emotion =>
        'Duygu diyaloğu — $n bağlamında sosyal destek',
      ConceptModule.routine =>
        'First–Then rutinde $n adımı / görsel ipucu',
      ConceptModule.aac =>
        'AAC kartı: “$n istiyorum” (usageCount sıralı)',
    };
  }
}

List<ConceptModuleGenerator> defaultMockGenerators() => [
      for (final m in ConceptModule.values) MockConceptModuleGenerator(m),
    ];
