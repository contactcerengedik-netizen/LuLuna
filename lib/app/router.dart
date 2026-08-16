import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/skill_level.dart';
import '../data/models/user_role.dart';
import '../data/providers.dart';
import '../features/ai_content/presentation/student_ai_activities_screen.dart';
import '../features/ai_content/presentation/teacher_ai_content_screen.dart';
import '../features/analytics/presentation/teacher_reports_screen.dart';
import '../features/assignments/presentation/teacher_assignments_screen.dart';
import '../features/auth/auth_gate_screen.dart';
import '../features/categorization/presentation/categorization_hub_screen.dart';
import '../features/cognition/presentation/cognition_hub_screen.dart';
import '../features/coloring/presentation/coloring_screen.dart';
import '../features/concept_engine/presentation/student_concept_activities_screen.dart';
import '../features/concept_engine/presentation/teacher_concept_screen.dart';
import '../features/daily_life/presentation/aac_board_screen.dart';
import '../features/daily_life/presentation/daily_life_hub_screen.dart';
import '../features/daily_life/presentation/routine_play_screen.dart';
import '../features/daily_life/presentation/scenario_play_screen.dart';
import '../features/education/presentation/activity_session_screen.dart';
import '../features/language/data/language_categories.dart';
import '../features/language/presentation/language_hub_screen.dart';
import '../features/mathematics/data/math_categories.dart';
import '../features/mathematics/presentation/math_hub_screen.dart';
import '../features/memory/presentation/memory_hub_screen.dart';
import '../features/onboarding/child_profile_screen.dart';
import '../features/onboarding/kvkk_consent_screen.dart';
import '../features/onboarding/permissions_intro_screen.dart';
import '../features/onboarding/role_selection_screen.dart';
import '../features/puzzle/presentation/puzzle_hub_screen.dart';
import '../features/social_speech/data/social_dialogue_catalog.dart';
import '../features/social_speech/presentation/social_speech_hub_screen.dart';
import '../features/student/presentation/student_home_screen.dart';
import '../features/teacher/presentation/teacher_dashboard_screen.dart';
import '../features/teacher/presentation/teacher_student_detail_screen.dart';
import '../features/tracing/domain/tracing_analyzer.dart';
import '../features/tracing/presentation/tracing_hub_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(appStateProvider, (_, _) => refresh.value++);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/auth',
    refreshListenable: refresh,
    // Auth → KVKK → izinler → rol → student | teacher
    // parent (MVP): öğrenci akışına düşer
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final app = ref.read(appStateProvider);
      final loc = state.matchedLocation;

      final onAuth = loc == '/auth';
      final onConsent = loc == '/onboarding/consent';
      final onRole = loc == '/onboarding/role';
      final onProfile = loc == '/onboarding/profile';
      final onPermissions = loc == '/onboarding/permissions';
      final onStudent = loc.startsWith('/student');
      final onTeacher = loc.startsWith('/teacher');

      if (auth == null) {
        return onAuth ? null : '/auth';
      }

      if (!auth.isReady) {
        return onConsent ? null : '/onboarding/consent';
      }

      final permsSeen = ref.read(permissionsServiceProvider).introSeen;
      if (!permsSeen) {
        return onPermissions ? null : '/onboarding/permissions';
      }

      if (app.role == null) {
        return onRole ? null : '/onboarding/role';
      }

      if (app.role == UserRole.student || app.role == UserRole.parent) {
        if (app.role == UserRole.parent &&
            app.profile == null &&
            !onProfile &&
            !onRole) {
          return '/onboarding/profile';
        }
        if (onAuth || onConsent || onPermissions || onRole || onProfile) {
          return '/student';
        }
        if (onStudent) return null;
        if (onTeacher) return '/student';
        return '/student';
      }

      if (app.role == UserRole.teacher || app.role == UserRole.admin) {
        if (onAuth || onConsent || onPermissions || onRole || onProfile) {
          return '/teacher';
        }
        if (onTeacher) return null;
        if (onStudent) return '/teacher';
        return '/teacher';
      }

      return '/student';
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthGateScreen(),
      ),
      GoRoute(
        path: '/onboarding/consent',
        builder: (context, state) => const KvkkConsentScreen(),
      ),
      GoRoute(
        path: '/onboarding/role',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding/profile',
        builder: (context, state) => const ChildProfileScreen(),
      ),
      GoRoute(
        path: '/onboarding/permissions',
        builder: (context, state) => const PermissionsIntroScreen(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: '/student/ai-activities',
        builder: (context, state) => const StudentAiActivitiesScreen(),
      ),
      GoRoute(
        path: '/student/concepts',
        builder: (context, state) => const StudentConceptActivitiesScreen(),
      ),
      GoRoute(
        path: '/student/math',
        builder: (context, state) => const MathHubScreen(),
      ),
      GoRoute(
        path: '/student/math/:category',
        builder: (context, state) {
          final category = state.pathParameters['category'] ?? 'addition';
          return MathDifficultyScreen(categoryId: category);
        },
      ),
      GoRoute(
        path: '/student/math/:category/:tier',
        builder: (context, state) {
          final category = state.pathParameters['category'] ?? 'addition';
          final tierName = state.pathParameters['tier'] ?? 'easy';
          final tier =
              SkillTier.values.asNameMap()[tierName] ?? SkillTier.easy;
          final title =
              MathCategories.byId(category)?.title ?? 'Matematik';
          final count =
              int.tryParse(state.uri.queryParameters['count'] ?? '') ?? 5;
          final assignmentId = state.uri.queryParameters['assignmentId'];
          return ActivitySessionScreen(
            skill: SkillArea.mathematics,
            category: category,
            difficulty: tier,
            title: title,
            exitRoute: '/student/math',
            count: count.clamp(1, 30),
            assignmentId: assignmentId,
          );
        },
      ),
      GoRoute(
        path: '/student/language',
        builder: (context, state) => const LanguageHubScreen(),
      ),
      GoRoute(
        path: '/student/language/:category',
        builder: (context, state) {
          final category = state.pathParameters['category'] ?? 'antonyms';
          return LanguageDifficultyScreen(categoryId: category);
        },
      ),
      GoRoute(
        path: '/student/language/:category/:tier',
        builder: (context, state) {
          final category = state.pathParameters['category'] ?? 'antonyms';
          final tierName = state.pathParameters['tier'] ?? 'easy';
          final tier =
              SkillTier.values.asNameMap()[tierName] ?? SkillTier.easy;
          final title =
              LanguageCategories.byId(category)?.title ?? 'Türkçe';
          final count =
              int.tryParse(state.uri.queryParameters['count'] ?? '') ?? 5;
          final assignmentId = state.uri.queryParameters['assignmentId'];
          return ActivitySessionScreen(
            skill: SkillArea.language,
            category: category,
            difficulty: tier,
            title: title,
            exitRoute: '/student/language',
            count: count.clamp(1, 30),
            assignmentId: assignmentId,
          );
        },
      ),
      GoRoute(
        path: '/student/daily-life',
        builder: (context, state) => const DailyLifeHubScreen(),
      ),
      GoRoute(
        path: '/student/daily-life/routine',
        builder: (context, state) => const RoutinePlayScreen(),
      ),
      GoRoute(
        path: '/student/daily-life/aac',
        builder: (context, state) => const AacBoardScreen(),
      ),
      GoRoute(
        path: '/student/daily-life/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'restaurant';
          return ScenarioPlayScreen(scenarioId: id);
        },
      ),
      GoRoute(
        path: '/student/puzzle',
        builder: (context, state) => const PuzzleHubScreen(),
      ),
      GoRoute(
        path: '/student/puzzle/:pieces',
        builder: (context, state) {
          final n = int.tryParse(state.pathParameters['pieces'] ?? '') ?? 3;
          final pieces = (n == 5 || n == 10) ? n : 3;
          return PuzzlePlayScreen(pieceCount: pieces);
        },
      ),
      GoRoute(
        path: '/student/tracing',
        builder: (context, state) => const TracingHubScreen(),
      ),
      GoRoute(
        path: '/student/tracing/:kind',
        builder: (context, state) {
          final name = state.pathParameters['kind'] ?? 'letter';
          final kind = TracingActivityKind.fromRoute(name);
          return TracingPlayScreen(kind: kind);
        },
      ),
      GoRoute(
        path: '/student/coloring',
        builder: (context, state) => const ColoringScreen(),
      ),
      GoRoute(
        path: '/student/categorize',
        builder: (context, state) => const CategorizationHubScreen(),
      ),
      GoRoute(
        path: '/student/categorize/:tier',
        builder: (context, state) {
          final tierName = state.pathParameters['tier'] ?? 'easy';
          final tier =
              SkillTier.values.asNameMap()[tierName] ?? SkillTier.easy;
          return CategorizationPlayScreen(tier: tier);
        },
      ),
      GoRoute(
        path: '/student/cognition',
        builder: (context, state) => const CognitionHubScreen(),
      ),
      GoRoute(
        path: '/student/cognition/:activity',
        builder: (context, state) {
          final name = state.pathParameters['activity'] ?? 'pattern';
          final activity = CognitionActivity.values.asNameMap()[name] ??
              CognitionActivity.pattern;
          return CognitionPlayScreen(activity: activity);
        },
      ),
      GoRoute(
        path: '/student/memory',
        builder: (context, state) => const MemoryHubScreen(),
      ),
      GoRoute(
        path: '/student/memory/:mode',
        builder: (context, state) {
          final name = state.pathParameters['mode'] ?? 'match';
          final mode =
              MemoryMode.values.asNameMap()[name] ?? MemoryMode.match;
          return MemoryPlayScreen(mode: mode);
        },
      ),
      GoRoute(
        path: '/student/speech',
        builder: (context, state) => const SocialSpeechHubScreen(),
      ),
      GoRoute(
        path: '/student/speech/:module',
        builder: (context, state) {
          final name = state.pathParameters['module'] ?? 'pronunciation';
          final module = SocialSpeechModule.values.asNameMap()[name] ??
              SocialSpeechModule.pronunciation;
          return SocialSpeechPlayScreen(module: module);
        },
      ),
      GoRoute(
        path: '/teacher',
        builder: (context, state) => const TeacherDashboardScreen(),
      ),
      GoRoute(
        path: '/teacher/student/:id',
        builder: (context, state) => TeacherStudentDetailScreen(
          studentId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/teacher/assignments',
        builder: (context, state) => const TeacherAssignmentsScreen(),
      ),
      GoRoute(
        path: '/teacher/ai-content',
        builder: (context, state) => const TeacherAiContentScreen(),
      ),
      GoRoute(
        path: '/teacher/concepts',
        builder: (context, state) => const TeacherConceptScreen(),
      ),
      GoRoute(
        path: '/teacher/reports',
        builder: (context, state) => const TeacherReportsScreen(),
      ),
    ],
  );
});
