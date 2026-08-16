import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../data/concept_repository.dart';
import '../data/mock_concept_generators.dart';
import '../domain/concept_models.dart';
import '../domain/concept_orchestrator.dart';

final conceptRepositoryProvider = Provider<ConceptRepository>((ref) {
  return ConceptRepository(ref.watch(sharedPreferencesProvider));
});

final conceptOrchestratorProvider = Provider<ConceptOrchestrator>((ref) {
  return ConceptOrchestrator(generators: defaultMockGenerators());
});

final conceptAssignmentsProvider =
    NotifierProvider<ConceptAssignmentsNotifier, List<ConceptAssignment>>(
  ConceptAssignmentsNotifier.new,
);

class ConceptAssignmentsNotifier extends Notifier<List<ConceptAssignment>> {
  @override
  List<ConceptAssignment> build() {
    return ref.watch(conceptRepositoryProvider).loadAssignments();
  }

  Future<void> refresh() async {
    state = ref.read(conceptRepositoryProvider).loadAssignments();
  }

  /// Öğretmen kavram seçer → modüllere üretim → onay bekler.
  Future<ConceptAssignment> createAndGenerate({
    required Concept concept,
    required String studentId,
    required String teacherId,
  }) async {
    final id = 'ca_${DateTime.now().millisecondsSinceEpoch}';
    final groupId = 'cg_$id';
    var assignment = ConceptAssignment(
      id: id,
      conceptId: concept.id,
      conceptName: concept.name,
      studentId: studentId,
      teacherId: teacherId,
      createdAt: DateTime.now(),
      status: ConceptAssignmentStatus.generating,
      consistencyGroupId: groupId,
    );
    await ref.read(conceptRepositoryProvider).upsertAssignment(assignment);
    await refresh();

    assignment = await ref.read(conceptOrchestratorProvider).generateForAssignment(
          concept: concept,
          assignment: assignment,
        );
    await ref.read(conceptRepositoryProvider).upsertAssignment(assignment);
    await refresh();
    return assignment;
  }

  Future<void> publish(String assignmentId) async {
    final all = [...state];
    final i = all.indexWhere((e) => e.id == assignmentId);
    if (i < 0) return;
    final publishedOutputs = [
      for (final o in all[i].outputs)
        o.copyWith(status: ConceptModuleOutputStatus.published),
    ];
    final next = all[i].copyWith(
      status: ConceptAssignmentStatus.published,
      outputs: publishedOutputs,
    );
    await ref.read(conceptRepositoryProvider).upsertAssignment(next);
    await refresh();
  }
}
