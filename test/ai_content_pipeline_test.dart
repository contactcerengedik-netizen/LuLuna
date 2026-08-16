import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luluna/data/models/skill_level.dart';
import 'package:luluna/features/ai_content/data/ai_activity_repository.dart';
import 'package:luluna/features/ai_content/data/mock_ai_services.dart';
import 'package:luluna/features/ai_content/domain/ai_content_models.dart';
import 'package:luluna/features/ai_content/domain/ai_content_services.dart';
import 'package:luluna/features/ai_content/domain/educational_content_pipeline.dart';

void main() {
  group('SpecialEducationVisualPromptBuilder', () {
    test('kuralları ve sahne planını prompta ekler', () {
      const activity = StructuredActivity(
        activityType: 'math_addition',
        difficulty: SkillTier.medium,
        instruction: 'Çöz',
        questionText: '3+5',
        answer: '8',
        objects: [
          {'type': 'egg', 'count': 3},
          {'type': 'egg', 'count': 5},
        ],
        operation: 'addition',
      );
      final plan = VisualScenePlan.fromStructured(activity);
      final prompt = SpecialEducationVisualPromptBuilder().build(
        activity,
        scenePlan: plan,
      );
      expect(prompt, contains('sade, düz arka plan'));
      expect(prompt, contains('egg'));
      expect(prompt, contains('Scene elements'));
      expect(prompt, contains('Forbidden'));
    });
  });

  group('EducationalContentPipeline', () {
    test('analiz kişi/nesne/sayı çıkarır', () {
      final pipeline = EducationalContentPipeline(
        content: MockAiContentService(),
        images: MockImageGenerationService(),
      );
      final a = pipeline.analyzePrompt(
        'Ayşe elinde 3 yumurta, buzdolabında 5 yumurta',
      );
      expect(a.people, contains('Ayşe'));
      expect(a.objects, contains('yumurta'));
      expect(a.numbers, containsAll([3, 5]));
      expect(a.operation, 'addition');
    });

    test('yumurta promptu structured + preview üretir', () async {
      final pipeline = EducationalContentPipeline(
        content: MockAiContentService(),
        images: MockImageGenerationService(),
      );
      final activity = await pipeline.generate(
        teacherPrompt:
            'Ayşe elinde 3 yumurta, buzdolabında 5 yumurta, toplam kaç?',
        id: 't1',
      );
      expect(activity.status, AiActivityStatus.preview);
      expect(activity.structured.answer, '8');
      expect(activity.structured.choices, contains('8'));
      expect(activity.image.isMock, isTrue);
      expect(activity.visualPrompt, contains('Special education'));
      expect(activity.analysis, isNotNull);
      expect(activity.scenePlan, isNotNull);
      expect(activity.isStudentVisible, isFalse);
    });

    test('validation nesne sayısı uyumsuzluğunu yakalar', () {
      final pipeline = EducationalContentPipeline(
        content: MockAiContentService(),
        images: MockImageGenerationService(),
      );
      const bad = StructuredActivity(
        activityType: 'math_addition',
        difficulty: SkillTier.easy,
        instruction: 'x',
        questionText: 'y',
        answer: '10',
        operation: 'addition',
        objects: [
          {'type': 'a', 'count': 2},
          {'type': 'b', 'count': 2},
        ],
      );
      final v = pipeline.validate(bad);
      expect(v.ok, isFalse);
      expect(v.issues.first, contains('uyuşmuyor'));
    });
  });

  group('AiActivityRepository onay/yayın', () {
    test('önizleme ve onay öğrencide görünmez; yalnızca publish', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = AiActivityRepository(prefs);
      final pipeline = EducationalContentPipeline(
        content: MockAiContentService(),
        images: MockImageGenerationService(),
      );
      final draft = await pipeline.generate(
        teacherPrompt: '2 + 2 kaç?',
        id: 'a1',
      );
      await repo.upsert(draft);
      expect(repo.publishedForStudents(), isEmpty);

      await repo.upsert(
        draft.copyWith(
          status: AiActivityStatus.approved,
          approvedAt: DateTime.now(),
        ),
      );
      expect(repo.publishedForStudents(), isEmpty);

      await repo.upsert(
        draft.copyWith(
          status: AiActivityStatus.published,
          approvedAt: DateTime.now(),
          publishedAt: DateTime.now(),
        ),
      );
      expect(repo.publishedForStudents(), hasLength(1));
    });
  });
}
