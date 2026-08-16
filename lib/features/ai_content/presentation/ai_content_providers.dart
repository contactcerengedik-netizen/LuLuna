import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/env.dart';
import '../../../data/models/skill_keys.dart';
import '../../../data/models/skill_level.dart';
import '../../../data/providers.dart';
import '../../assignments/domain/assignment_models.dart';
import '../../assignments/presentation/assignment_providers.dart';
import '../data/ai_activity_repository.dart';
import '../data/caching_image_generation_service.dart';
import '../data/gemini_ai_services.dart';
import '../data/mock_ai_services.dart';
import '../data/openai_ai_services.dart';
import '../data/pollinations_image_service.dart';
import '../data/question_image_cache.dart';
import '../data/teacher_ai_question_pool.dart';
import '../domain/ai_content_models.dart';
import '../domain/ai_content_services.dart';
import '../domain/educational_content_pipeline.dart';
import '../domain/image_quota_exception.dart';
import '../domain/session_question_batch.dart';

bool get _useGemini {
  if (Env.hasGeminiKey) return true;
  final o = Env.openAiApiKey;
  return o.startsWith('AQ.') || o.startsWith('AIza');
}

bool get _useOpenAi => Env.openAiApiKey.startsWith('sk-');

bool get _mockImagesForQuotaSafety =>
    Env.shouldUseMockImages || (kDebugMode && !Env.forceRealAiImages);

final aiContentServiceProvider = Provider<AiContentService>((ref) {
  if (_useGemini || kIsWeb) return GeminiAiContentService();
  if (_useOpenAi) return OpenAiAiContentService();
  return MockAiContentService();
});

final questionImageCacheProvider = Provider<QuestionImageCache>((ref) {
  return QuestionImageCache(
    ref.watch(sharedPreferencesProvider),
    supabase: ref.watch(supabaseClientProvider),
  );
});

final imageGenerationServiceProvider = Provider<ImageGenerationService>((ref) {
  final cache = ref.watch(questionImageCacheProvider);

  if (_mockImagesForQuotaSafety) {
    debugPrint(
      '[AI Images] DEBUG mock (kota koruması). '
      'Gerçek API: --dart-define=FORCE_REAL_AI_IMAGES=true',
    );
    return CachingImageGenerationService(
      inner: MockImageGenerationService(),
      cache: cache,
    );
  }

  final ImageGenerationService primary;
  if (_useGemini || kIsWeb) {
    primary = GeminiImageGenerationService();
  } else if (_useOpenAi) {
    primary = OpenAiImageGenerationService();
  } else {
    primary = PollinationsImageGenerationService();
  }

  return CachingImageGenerationService(
    inner: primary,
    cache: cache,
    fallback: PollinationsImageGenerationService(),
  );
});

final sessionQuestionBatchProvider =
    Provider<SessionQuestionBatchService?>((ref) {
  final c = ref.watch(aiContentServiceProvider);
  if (c is! SessionQuestionBatchService) return null;
  final batch = c as SessionQuestionBatchService;
  return batch.isConfigured ? batch : null;
});

final educationalContentPipelineProvider =
    Provider<EducationalContentPipeline>((ref) {
  return EducationalContentPipeline(
    content: ref.watch(aiContentServiceProvider),
    images: ref.watch(imageGenerationServiceProvider),
  );
});

final aiActivityRepositoryProvider = Provider<AiActivityRepository>((ref) {
  return AiActivityRepository(ref.watch(sharedPreferencesProvider));
});

final teacherAiQuestionPoolProvider = Provider<TeacherAiQuestionPool>((ref) {
  return TeacherAiQuestionPool(ref.watch(sharedPreferencesProvider));
});

final teacherAiActivitiesProvider =
    NotifierProvider<TeacherAiActivitiesNotifier, List<TeacherAiActivity>>(
  TeacherAiActivitiesNotifier.new,
);

class TeacherAiActivitiesNotifier extends Notifier<List<TeacherAiActivity>> {
  @override
  List<TeacherAiActivity> build() {
    return ref.watch(aiActivityRepositoryProvider).loadAll();
  }

  Future<void> refresh() async {
    state = ref.read(aiActivityRepositoryProvider).loadAll();
  }

  Future<TeacherAiActivity> generate(
    String prompt, {
    SkillTier? suggestedDifficulty,
    String? targetStudentId,
  }) async {
    final id = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    final activity = await ref.read(educationalContentPipelineProvider).generate(
          teacherPrompt: prompt,
          id: id,
          suggestedDifficulty: suggestedDifficulty,
          targetStudentId: targetStudentId,
          deferImageOnQuota: true,
        );
    await ref.read(aiActivityRepositoryProvider).upsert(activity);
    await refresh();
    if (activity.imagePending) {
      throw const ImageQuotaExceededException(
        'Günlük görsel üretim kotası doldu. Soru taslak olarak kaydedildi — '
        'görsel daha sonra eklenebilir.',
      );
    }
    return activity;
  }

  Future<TeacherAiActivity> regenerateImage(String id) async {
    TeacherAiActivity? current;
    for (final e in state) {
      if (e.id == id) current = e;
    }
    if (current == null) throw StateError('Etkinlik bulunamadı');
    try {
      final next = await ref
          .read(educationalContentPipelineProvider)
          .regenerateImage(current);
      await ref.read(aiActivityRepositoryProvider).upsert(next);
      await refresh();
      return next;
    } on ImageQuotaExceededException {
      rethrow;
    }
  }

  Future<void> updateDraft(TeacherAiActivity activity) async {
    await ref.read(aiActivityRepositoryProvider).upsert(activity);
    await refresh();
  }

  Future<void> approve(String id) async {
    final all = [...state];
    final i = all.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final cur = all[i];
    if (!cur.canPublish) {
      throw StateError('Kategori seçilmedi — lütfen skill_key seçin');
    }
    final next = cur.copyWith(
      status: AiActivityStatus.approved,
      approvedAt: DateTime.now(),
    );
    await ref.read(aiActivityRepositoryProvider).upsert(next);
    await refresh();
  }

  Future<void> publish(String id, {String? teacherId}) async {
    final all = [...state];
    final i = all.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final current = all[i];
    if (!current.canPublish) {
      throw StateError('Kategori seçilmedi — lütfen skill_key seçin');
    }
    if (current.status != AiActivityStatus.approved &&
        current.status != AiActivityStatus.published) {
      return;
    }
    final next = current.copyWith(
      status: AiActivityStatus.published,
      approvedAt: current.approvedAt ?? DateTime.now(),
      publishedAt: DateTime.now(),
    );
    await ref.read(aiActivityRepositoryProvider).upsert(next);
    await ref.read(teacherAiQuestionPoolProvider).upsertFromActivity(next);

    // Belirli öğrenciye ata → mevcut ödev sistemi
    final studentId = next.targetStudentId;
    final skillKey = next.skillKey;
    final category = skillKey == null ? null : SkillKeys.toCategory(skillKey);
    if (studentId != null &&
        studentId.isNotEmpty &&
        skillKey != null &&
        category != null) {
      final tid = teacherId ??
          ref.read(authStateProvider)?.userId ??
          'demo-teacher';
      await ref.read(assignmentRepositoryProvider).upsert(
            HomeworkAssignment(
              id: 'asg_${next.id}',
              teacherId: tid,
              title: next.structured.questionText.length > 48
                  ? '${next.structured.questionText.substring(0, 48)}…'
                  : next.structured.questionText,
              skill: SkillKeys.areaFor(skillKey),
              category: category,
              difficulty: next.structured.difficulty,
              questionCount: 1,
              studentIds: [studentId],
              createdAt: DateTime.now(),
            ),
          );
      ref.read(assignmentRefreshProvider.notifier).bump();
    }

    await refresh();
  }
}

final publishedAiActivitiesProvider = Provider<List<TeacherAiActivity>>((ref) {
  return ref
      .watch(teacherAiActivitiesProvider)
      .where((e) => e.isStudentVisible)
      .toList();
});
