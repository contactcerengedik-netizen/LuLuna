import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../education/presentation/activity_session_controller.dart';
import '../data/activity_session_repository.dart';
import '../domain/analytics_models.dart';
import '../domain/analytics_service.dart';
import '../domain/report_export_service.dart';
import 'analytics_refresh.dart';

export 'analytics_refresh.dart';

enum ReportDatePreset { days7, days30, days90, all }

final reportDatePresetProvider =
    NotifierProvider<ReportDatePresetNotifier, ReportDatePreset>(
  ReportDatePresetNotifier.new,
);

class ReportDatePresetNotifier extends Notifier<ReportDatePreset> {
  @override
  ReportDatePreset build() => ReportDatePreset.days30;

  void set(ReportDatePreset value) => state = value;
}

({DateTime? from, DateTime? to}) dateRangeForPreset(ReportDatePreset preset) {
  final now = DateTime.now();
  final end = DateTime(now.year, now.month, now.day);
  return switch (preset) {
    ReportDatePreset.days7 => (
        from: end.subtract(const Duration(days: 6)),
        to: end,
      ),
    ReportDatePreset.days30 => (
        from: end.subtract(const Duration(days: 29)),
        to: end,
      ),
    ReportDatePreset.days90 => (
        from: end.subtract(const Duration(days: 89)),
        to: end,
      ),
    ReportDatePreset.all => (from: null, to: null),
  };
}

final activitySessionRepositoryProvider =
    Provider<ActivitySessionRepository>((ref) {
  return ActivitySessionRepository(ref.watch(sharedPreferencesProvider));
});

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => const AnalyticsService(),
);

final reportExportServiceProvider = Provider<ReportExportService>(
  (ref) => TextReportExportService(),
);

final studentAnalyticsProvider =
    Provider.family<StudentAnalytics, String>((ref, studentId) {
  final attempts = ref.watch(activityAttemptRepositoryProvider).loadAll();
  final sessions = ref.watch(activitySessionRepositoryProvider).loadAll();
  final range = dateRangeForPreset(ref.watch(reportDatePresetProvider));
  ref.watch(analyticsRefreshProvider);
  return ref.watch(analyticsServiceProvider).build(
        studentId: studentId,
        attempts: attempts,
        sessions: sessions,
        from: range.from,
        to: range.to,
      );
});

final teacherAnalyticsOverviewProvider =
    Provider<List<({String id, String name, StudentAnalytics analytics})>>(
  (ref) {
    ref.watch(analyticsRefreshProvider);
    final students =
        ref.watch(teacherStudentsProvider).asData?.value ?? const [];
    final attempts = ref.watch(activityAttemptRepositoryProvider).loadAll();
    final sessions = ref.watch(activitySessionRepositoryProvider).loadAll();
    final range = dateRangeForPreset(ref.watch(reportDatePresetProvider));
    final service = ref.watch(analyticsServiceProvider);
    return [
      for (final s in students)
        (
          id: s.id,
          name: s.name,
          analytics: service.build(
            studentId: s.id,
            attempts: attempts,
            sessions: sessions,
            from: range.from,
            to: range.to,
          ),
        ),
    ];
  },
);
