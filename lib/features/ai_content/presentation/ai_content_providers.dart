import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../data/ai_activity_repository.dart';
import '../data/mock_ai_services.dart';
import '../domain/ai_content_models.dart';
import '../domain/ai_content_services.dart';
import '../domain/educational_content_pipeline.dart';

final aiContentServiceProvider = Provider<AiContentService>(
  (ref) => MockAiContentService(),
);

final imageGenerationServiceProvider = Provider<ImageGenerationService>(
  (ref) => MockImageGenerationService(),
);

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

  Future<TeacherAiActivity> generate(String prompt) async {
    final id = 'ai_${DateTime.now().millisecondsSinceEpoch}';
    final activity = await ref
        .read(educationalContentPipelineProvider)
        .generate(teacherPrompt: prompt, id: id);
    await ref.read(aiActivityRepositoryProvider).upsert(activity);
    await refresh();
    return activity;
  }

  Future<void> updateDraft(TeacherAiActivity activity) async {
    await ref.read(aiActivityRepositoryProvider).upsert(activity);
    await refresh();
  }

  Future<void> approve(String id) async {
    final all = [...state];
    final i = all.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final next = all[i].copyWith(
      status: AiActivityStatus.approved,
      approvedAt: DateTime.now(),
    );
    await ref.read(aiActivityRepositoryProvider).upsert(next);
    await refresh();
  }

  Future<void> publish(String id) async {
    final all = [...state];
    final i = all.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final current = all[i];
    // Yayın için önce onay gerekir.
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
    await refresh();
  }
}

final publishedAiActivitiesProvider = Provider<List<TeacherAiActivity>>((ref) {
  return ref
      .watch(teacherAiActivitiesProvider)
      .where((e) => e.isStudentVisible)
      .toList();
});
