import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luluna/features/ai_content/data/mock_ai_services.dart';
import 'package:luluna/features/ai_content/domain/question_image_spec.dart';
import 'package:luluna/features/concept_engine/data/concept_repository.dart';
import 'package:luluna/features/concept_engine/data/mock_concept_generators.dart';
import 'package:luluna/features/concept_engine/domain/concept_models.dart';
import 'package:luluna/features/concept_engine/domain/concept_orchestrator.dart';
import 'package:luluna/features/dialogue/domain/dialogue_models.dart';

void main() {
  group('QuestionImageSpec / Kural A', () {
    test('aynı grupta her soru farklı assetPath', () async {
      final images = MockImageGenerationService();
      const group = 'cg_test';
      final a = await images.generateImageForQuestion(
        const QuestionImageSpec(
          sceneDescription: '3 elma',
          questionId: 'q1',
          consistencyGroupId: group,
        ),
      );
      final b = await images.generateImageForQuestion(
        const QuestionImageSpec(
          sceneDescription: '5 elma',
          questionId: 'q2',
          consistencyGroupId: group,
        ),
      );
      expect(a.assetPath, isNotNull);
      expect(b.assetPath, isNotNull);
      expect(a.assetPath, isNot(b.assetPath));
      expect(a.assetPath, contains(group));
      expect(b.assetPath, contains(group));
    });
  });

  group('ConceptOrchestrator', () {
    test('elma → ilgili modüllere ready çıktı', () async {
      SharedPreferences.setMockInitialValues({});
      final concept = ConceptRepository.catalog.firstWhere((c) => c.name == 'elma');
      final orch = ConceptOrchestrator(generators: defaultMockGenerators());
      final draft = ConceptAssignment(
        id: 'ca1',
        conceptId: concept.id,
        conceptName: concept.name,
        studentId: 's1',
        teacherId: 't1',
        createdAt: DateTime(2026, 8, 15),
        status: ConceptAssignmentStatus.generating,
        consistencyGroupId: 'cg1',
      );
      final done = await orch.generateForAssignment(
        concept: concept,
        assignment: draft,
      );
      expect(done.status, ConceptAssignmentStatus.readyForReview);
      expect(done.outputs.length, concept.relatedSkills.length);
      expect(
        done.outputs.every((o) => o.status == ConceptModuleOutputStatus.ready),
        isTrue,
      );
      final seeds = done.outputs.map((e) => e.imageSeed).toSet();
      expect(seeds.length, done.outputs.length);
    });
  });

  group('DialogueRunnerEngine', () {
    test('free_speech keyword eşleşmesi', () {
      final dlg = Dialogue.forConcept(conceptName: 'elma', conceptId: 'c_elma');
      final eng = DialogueRunnerEngine(dlg);
      expect(eng.current.responseType, DialogueResponseType.freeSpeech);
      final bad = eng.submitSpeech('araba');
      expect(bad.correct, isFalse);
      expect(eng.index, 0);
      final ok = eng.submitSpeech('Bu bir ELMA');
      expect(ok.correct, isTrue);
      expect(eng.index, 1);
    });

    test('choice doğru ilerletir', () {
      final dlg = Dialogue.forConcept(conceptName: 'elma', conceptId: 'c_elma');
      final eng = DialogueRunnerEngine(dlg);
      eng.submitSpeech('elma');
      final wrong = eng.submitChoice('masa');
      expect(wrong.correct, isFalse);
      final right = eng.submitChoice('elma');
      expect(right.correct, isTrue);
      eng.skipNone();
      expect(eng.isComplete, isTrue);
    });

    test('matchesKeywords', () {
      expect(
        DialogueRunnerEngine.matchesKeywords('elma de', ['elma']),
        isTrue,
      );
      expect(
        DialogueRunnerEngine.matchesKeywords('kedi', ['elma']),
        isFalse,
      );
    });
  });
}
