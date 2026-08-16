import 'concept_models.dart';

/// Modül içeriği üretici — kavram motoru orkestre eder, modüller bağımsızdır.
abstract class ConceptModuleGenerator {
  ConceptModule get module;

  Future<ConceptModuleOutput> generate({
    required Concept concept,
    required ConceptAssignment assignment,
  });
}

/// Kavram → ilgili modüllere üretim isteği dağıtır (event-driven orkestrasyon).
class ConceptOrchestrator {
  ConceptOrchestrator({
    required List<ConceptModuleGenerator> generators,
  }) : _byModule = {
          for (final g in generators) g.module: g,
        };

  final Map<ConceptModule, ConceptModuleGenerator> _byModule;

  /// Kavramın relatedSkills listesine göre generator’ları çalıştırır.
  Future<ConceptAssignment> generateForAssignment({
    required Concept concept,
    required ConceptAssignment assignment,
  }) async {
    final targets = concept.relatedSkills.isEmpty
        ? ConceptModule.values
        : concept.relatedSkills;
    final outputs = <ConceptModuleOutput>[];
    for (final module in targets) {
      final gen = _byModule[module];
      if (gen == null) {
        outputs.add(
          ConceptModuleOutput(
            id: '${assignment.id}_${module.name}_skip',
            module: module,
            status: ConceptModuleOutputStatus.pending,
            previewTitle: module.label,
            previewBody: 'Generator bağlı değil — defaultMockGenerators güncelle.',
          ),
        );
        continue;
      }
      outputs.add(
        await gen.generate(concept: concept, assignment: assignment),
      );
    }
    return assignment.copyWith(
      status: ConceptAssignmentStatus.readyForReview,
      outputs: outputs,
    );
  }
}
