import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/analytics/domain/analytics_models.dart';
import '../../features/education/domain/activity_models.dart';
import '../repositories/education_row_mapper.dart';

/// Aktivite denemelerini buluta yazma (best-effort).
abstract class EducationProgressSync {
  Future<void> pushAttempt(ActivityAttempt attempt);
  Future<void> pushSession(ActivitySessionEvent session);
}

class NoopEducationProgressSync implements EducationProgressSync {
  const NoopEducationProgressSync();

  @override
  Future<void> pushAttempt(ActivityAttempt attempt) async {}

  @override
  Future<void> pushSession(ActivitySessionEvent session) async {}
}

class SupabaseEducationProgressSync implements EducationProgressSync {
  SupabaseEducationProgressSync(this._client);

  final SupabaseClient _client;
  final Map<String, String> _studentIdCache = {};

  Future<String?> _resolveStudentUuid(String localStudentId) async {
    final cached = _studentIdCache[localStudentId];
    if (cached != null) return cached;
    try {
      // Önce students.id olarak dene
      final byId = await _client
          .from('students')
          .select('id')
          .eq('id', localStudentId)
          .maybeSingle();
      if (byId != null && byId['id'] != null) {
        final id = byId['id'].toString();
        _studentIdCache[localStudentId] = id;
        return id;
      }
      final byProfile = await _client
          .from('students')
          .select('id')
          .eq('profile_id', localStudentId)
          .maybeSingle();
      if (byProfile != null && byProfile['id'] != null) {
        final id = byProfile['id'].toString();
        _studentIdCache[localStudentId] = id;
        return id;
      }
    } catch (e) {
      debugPrint('resolveStudentUuid: $e');
    }
    return null;
  }

  @override
  Future<void> pushAttempt(ActivityAttempt attempt) async {
    final uuid = await _resolveStudentUuid(attempt.studentId);
    if (uuid == null) return;
    try {
      await _client.from('attempt_answers').insert(
            EducationRowMapper.attemptAnswerInsert(
              studentUuid: uuid,
              skill: attempt.skill,
              category: attempt.category,
              difficulty: attempt.difficulty,
              questionId: attempt.questionId,
              givenAnswer: attempt.givenAnswer,
              correct: attempt.correct,
              attemptedAt: attempt.attemptedAt,
              durationMs: attempt.durationMs,
              deviationScore: attempt.deviationScore,
            ),
          );
    } catch (e) {
      debugPrint('pushAttempt: $e');
    }
  }

  @override
  Future<void> pushSession(ActivitySessionEvent session) async {
    final uuid = await _resolveStudentUuid(session.studentId);
    if (uuid == null) return;
    try {
      await _client.from('activity_attempts').insert(
            EducationRowMapper.sessionInsert(
              studentUuid: uuid,
              skill: session.skill,
              category: session.category,
              difficulty: session.difficulty,
              startedAt: session.startedAt,
              finishedAt: session.finishedAt,
              correctCount: session.correctCount,
              wrongCount: session.wrongCount,
              attemptCount: session.attemptCount,
              score: session.score,
              durationMs: session.durationMs,
            ),
          );
    } catch (e) {
      debugPrint('pushSession: $e');
    }
  }
}
