import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../data/assignment_repository.dart';
import '../domain/assignment_models.dart';

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return AssignmentRepository(ref.watch(sharedPreferencesProvider));
});

final assignmentRefreshProvider =
    NotifierProvider<AssignmentRefreshNotifier, int>(
  AssignmentRefreshNotifier.new,
);

class AssignmentRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final teacherAssignmentsProvider = Provider<List<HomeworkAssignment>>((ref) {
  ref.watch(assignmentRefreshProvider);
  final uid = ref.watch(authStateProvider)?.userId ?? 'demo-teacher-1';
  return ref.watch(assignmentRepositoryProvider).forTeacher(uid);
});

final studentAssignmentsProvider = Provider<List<HomeworkAssignment>>((ref) {
  ref.watch(assignmentRefreshProvider);
  final authId = ref.watch(authStateProvider)?.userId ?? '';
  final profileId =
      ref.watch(currentStudentProfileProvider).asData?.value?.id ?? authId;
  return ref.watch(assignmentRepositoryProvider).forStudent(profileId);
});

final studentOpenAssignmentsProvider = Provider<List<HomeworkAssignment>>((ref) {
  ref.watch(assignmentRefreshProvider);
  final authId = ref.watch(authStateProvider)?.userId ?? '';
  final profileId =
      ref.watch(currentStudentProfileProvider).asData?.value?.id ?? authId;
  return ref.watch(assignmentRepositoryProvider).openForStudent(profileId);
});
