import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luluna/features/analytics/domain/analytics_service.dart';
import 'package:luluna/features/analytics/domain/unified_skill_map.dart';
import 'package:luluna/features/concept_engine/data/concept_repository.dart';
import 'package:luluna/features/concept_engine/data/mock_concept_generators.dart';
import 'package:luluna/features/concept_engine/domain/concept_models.dart';
import 'package:luluna/features/concept_engine/domain/concept_orchestrator.dart';
import 'package:luluna/features/education/domain/activity_models.dart';

void main() {
  group('ConceptModule Faz 17', () {
    test('15+ modül ve studentRoute', () {
      expect(ConceptModule.values.length, greaterThanOrEqualTo(15));
      for (final m in ConceptModule.values) {
        expect(m.studentRoute, startsWith('/student/'));
        expect(m.label, isNotEmpty);
      }
    });

    test('elma → tüm relatedSkills için output + rota', () async {
      SharedPreferences.setMockInitialValues({});
      final concept =
          ConceptRepository.catalog.firstWhere((c) => c.name == 'elma');
      expect(concept.relatedSkills, ConceptModule.values);
      final orch = ConceptOrchestrator(generators: defaultMockGenerators());
      final draft = ConceptAssignment(
        id: 'ca17',
        conceptId: concept.id,
        conceptName: concept.name,
        studentId: 's1',
        teacherId: 't1',
        createdAt: DateTime(2026, 8, 15),
        status: ConceptAssignmentStatus.generating,
        consistencyGroupId: 'cg17',
      );
      final done = await orch.generateForAssignment(
        concept: concept,
        assignment: draft,
      );
      expect(done.outputs.length, ConceptModule.values.length);
      expect(
        done.outputs.every((o) => o.status == ConceptModuleOutputStatus.ready),
        isTrue,
      );
      expect(
        done.outputs.every((o) => o.studentRoute != null),
        isTrue,
      );
      final seeds = done.outputs.map((e) => e.imageSeed).toSet();
      expect(seeds.length, done.outputs.length);
    });
  });

  group('UnifiedAnalytics', () {
    test('15 alan her zaman listelenir', () {
      final scores = UnifiedAnalyticsBuilder.build(const []);
      expect(scores, hasLength(15));
      expect(scores.every((s) => !s.hasData), isTrue);
    });

    test('attempt alanlara map edilir', () {
      final now = DateTime.now();
      final attempts = [
        ActivityAttempt(
          id: '1',
          studentId: 's1',
          skill: 'mathematics',
          category: 'addition',
          difficulty: 'easy',
          questionId: 'q1',
          givenAnswer: '2',
          correct: true,
          attemptedAt: now,
        ),
        ActivityAttempt(
          id: '2',
          studentId: 's1',
          skill: 'communication',
          category: 'aac',
          difficulty: 'easy',
          questionId: 'water',
          givenAnswer: 'Su',
          correct: true,
          attemptedAt: now,
        ),
        ActivityAttempt(
          id: '3',
          studentId: 's1',
          skill: 'visualPerception',
          category: 'match',
          difficulty: 'easy',
          questionId: 'm1',
          givenAnswer: 'ok',
          correct: false,
          attemptedAt: now,
        ),
      ];
      final scores = UnifiedAnalyticsBuilder.build(attempts);
      final math = scores.firstWhere(
        (s) => s.area == UnifiedLearningArea.mathematics,
      );
      final aac = scores.firstWhere((s) => s.area == UnifiedLearningArea.aac);
      final mem = scores.firstWhere(
        (s) => s.area == UnifiedLearningArea.memory,
      );
      expect(math.correct, 1);
      expect(aac.correct, 1);
      expect(mem.wrong, 1);

      const service = AnalyticsService();
      final analytics = service.build(
        studentId: 's1',
        attempts: attempts,
        sessions: const [],
      );
      expect(analytics.byUnifiedArea, hasLength(15));
    });
  });
}
