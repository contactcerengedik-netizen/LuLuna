import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/education_question.dart';
import '../../../data/models/skill_level.dart';
import '../../../data/models/student_profile.dart';
import '../../../data/providers.dart';
import '../../analytics/data/activity_session_repository.dart';
import '../../analytics/domain/analytics_models.dart';
import '../../analytics/presentation/analytics_refresh.dart';
import '../../assignments/presentation/assignment_providers.dart';
import '../data/activity_attempt_repository.dart';
import '../data/student_skill_level_repository.dart';
import '../domain/activity_engine.dart';
import '../domain/activity_models.dart';
import '../domain/level_suggestion.dart';
import '../../language/data/language_question_generator.dart';
import '../../mathematics/data/math_question_generator.dart';

final activityAttemptRepositoryProvider =
    Provider<ActivityAttemptRepository>((ref) {
  return ActivityAttemptRepository(ref.watch(sharedPreferencesProvider));
});

final studentSkillLevelRepositoryProvider =
    Provider<StudentSkillLevelRepository>((ref) {
  return StudentSkillLevelRepository(ref.watch(sharedPreferencesProvider));
});

final skillLevelRefreshProvider =
    NotifierProvider<SkillLevelRefreshNotifier, int>(
  SkillLevelRefreshNotifier.new,
);

class SkillLevelRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final mathQuestionGeneratorProvider = Provider<MathQuestionGenerator>(
  (ref) => MathQuestionGenerator(),
);

final languageQuestionGeneratorProvider = Provider<LanguageQuestionGenerator>(
  (ref) => LanguageQuestionGenerator(),
);

final levelSuggestionEngineProvider = Provider<LevelSuggestionEngine>(
  (ref) => const LevelSuggestionEngine(),
);

/// Öğrenci için onaylı skill_key → tier haritası (repo + profil birleşimi).
final approvedSkillTiersProvider =
    Provider.family<Map<String, SkillTier>, String>((ref, studentId) {
  ref.watch(skillLevelRefreshProvider);
  final fromRepo =
      ref.watch(studentSkillLevelRepositoryProvider).tiersByKey(studentId);
  final profile = ref.watch(teacherStudentsProvider).asData?.value;
  StudentProfile? match;
  if (profile != null) {
    for (final s in profile) {
      if (s.id == studentId) {
        match = s;
        break;
      }
    }
  }
  match ??= ref.watch(currentStudentProfileProvider).asData?.value;
  final merged = <String, SkillTier>{};
  if (match != null) {
    for (final row in match.skillLevels) {
      merged[row.effectiveSkillKey] = row.tier;
    }
  }
  merged.addAll(fromRepo);
  return merged;
});

/// Öğretmen paneli: sistem önerileri (otomatik uygulanmaz).
final levelSuggestionsProvider =
    Provider.family<List<LevelSuggestion>, String>((ref, studentId) {
  ref.watch(skillLevelRefreshProvider);
  final attempts =
      ref.watch(activityAttemptRepositoryProvider).forStudent(studentId);
  final current = ref.watch(approvedSkillTiersProvider(studentId));
  return ref.watch(levelSuggestionEngineProvider).suggestAll(
        attempts: attempts,
        studentId: studentId,
        currentBySkillKey: current,
      );
});

class ActivityLaunchArgs {
  const ActivityLaunchArgs({
    required this.skill,
    required this.category,
    required this.difficulty,
    this.count = 5,
    this.assignmentId,
  });

  final SkillArea skill;
  final String category;
  final SkillTier difficulty;
  final int count;
  final String? assignmentId;
}

class ActivitySessionState {
  const ActivitySessionState({
    required this.engine,
    required this.startedAt,
    this.lastFeedback,
    this.finished = false,
    this.result,
    this.assignmentId,
  });

  final ActivityEngine engine;
  final DateTime startedAt;
  final AnswerEvaluation? lastFeedback;
  final bool finished;
  final ActivitySessionResult? result;
  final String? assignmentId;

  EducationQuestion get current => engine.current;
  int get index => engine.index;
  int get total => engine.total;
}

class ActivitySessionNotifier extends Notifier<ActivitySessionState?> {
  @override
  ActivitySessionState? build() => null;

  void start(ActivityLaunchArgs args) {
    // Öğretmen listesi demo-student-*; denemeler auth uid ile de gelebilir.
    // Profil id varsa onu kullan (demo’da genelde auth uid).
    final authId = ref.read(authStateProvider)?.userId ?? 'demo-student';
    final profileId =
        ref.read(currentStudentProfileProvider).asData?.value?.id;
    final studentId =
        (profileId != null && profileId.isNotEmpty) ? profileId : authId;
    final generator = args.skill == SkillArea.mathematics
        ? ref.read(mathQuestionGeneratorProvider)
        : ref.read(languageQuestionGeneratorProvider);
    final questions = generator.generate(
      category: args.category,
      difficulty: args.difficulty,
      count: args.count,
    );
    final engine = ActivityEngine(
      studentId: studentId,
      questions: questions,
    )..markQuestionStarted();
    state = ActivitySessionState(
      engine: engine,
      startedAt: DateTime.now(),
      assignmentId: args.assignmentId,
    );
  }

  Future<AnswerEvaluation?> submit(String answer) async {
    final current = state;
    if (current == null || current.finished) return null;
    final eval = current.engine.submit(answer);
    await ref.read(activityAttemptRepositoryProvider).append(eval.attempt);
    unawaited(ref.read(educationProgressSyncProvider).pushAttempt(eval.attempt));
    if (eval.finished) {
      final result = current.engine.result();
      final event = ActivitySessionEvent.fromResult(
        id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
        studentId: current.engine.studentId,
        activityId: '${result.skill}_${result.category}',
        result: result,
        startedAt: current.startedAt,
      );
      await ActivitySessionRepository(ref.read(sharedPreferencesProvider))
          .append(event);
      unawaited(ref.read(educationProgressSyncProvider).pushSession(event));
      ref.read(analyticsRefreshProvider.notifier).bump();
      await ref.read(assignmentRepositoryProvider).markCompletedMatching(
            studentId: current.engine.studentId,
            skillName: result.skill,
            category: result.category,
            difficulty: result.difficulty,
            questionCount: result.total,
          );
      ref.read(assignmentRefreshProvider.notifier).bump();
      state = ActivitySessionState(
        engine: current.engine,
        startedAt: current.startedAt,
        lastFeedback: eval,
        finished: true,
        result: result,
        assignmentId: current.assignmentId,
      );
    } else {
      current.engine.markQuestionStarted();
      state = ActivitySessionState(
        engine: current.engine,
        startedAt: current.startedAt,
        lastFeedback: eval,
        assignmentId: current.assignmentId,
      );
    }
    return eval;
  }

  void clearFeedback() {
    final current = state;
    if (current == null) return;
    state = ActivitySessionState(
      engine: current.engine,
      startedAt: current.startedAt,
      finished: current.finished,
      result: current.result,
      assignmentId: current.assignmentId,
    );
  }

  void reset() => state = null;
}

final activitySessionProvider =
    NotifierProvider<ActivitySessionNotifier, ActivitySessionState?>(
  ActivitySessionNotifier.new,
);
