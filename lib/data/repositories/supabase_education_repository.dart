import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/education_question.dart';
import '../models/skill_level.dart';
import '../models/student_profile.dart';
import '../../features/education/domain/question_selection.dart';
import 'education_repository.dart';
import 'education_row_mapper.dart';

const _studentSelect =
    'id, profile_id, name, birth_date, preferences, accessibility, created_at, '
    'student_skill_levels(skill, skill_key, tier, source, mastery_percent, updated_at), '
    'teacher_student(teacher_id)';

/// Supabase education repository. Hata / boş sonuç çağırana null/[] döner;
/// UI katmanı [FallbackEducationRepository] ile demo’ya düşer.
class SupabaseEducationRepository implements EducationRepository {
  SupabaseEducationRepository(this._client);

  final SupabaseClient _client;
  final Map<String, String> _studentUuidCache = {};

  Future<String?> _resolveStudentUuid(String studentId) async {
    final cached = _studentUuidCache[studentId];
    if (cached != null) return cached;
    try {
      final byId = await _client
          .from('students')
          .select('id')
          .eq('id', studentId)
          .maybeSingle();
      if (byId != null && byId['id'] != null) {
        final id = byId['id'].toString();
        _studentUuidCache[studentId] = id;
        return id;
      }
      final byProfile = await _client
          .from('students')
          .select('id')
          .eq('profile_id', studentId)
          .maybeSingle();
      if (byProfile != null && byProfile['id'] != null) {
        final id = byProfile['id'].toString();
        _studentUuidCache[studentId] = id;
        return id;
      }
    } catch (e) {
      debugPrint('resolveStudentUuid: $e');
    }
    return null;
  }

  @override
  Future<StudentProfile?> studentByUserId(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final row = await _client
          .from('students')
          .select(_studentSelect)
          .eq('profile_id', userId)
          .maybeSingle();
      if (row == null) return null;
      return EducationRowMapper.studentFromRow(
        Map<String, dynamic>.from(row),
      );
    } catch (e, st) {
      debugPrint('SupabaseEducationRepository.studentByUserId: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<List<StudentProfile>> studentsForTeacher(String teacherId) async {
    if (teacherId.isEmpty) return const [];
    try {
      final links = await _client
          .from('teacher_student')
          .select('student_id')
          .eq('teacher_id', teacherId);
      final ids = <String>[
        for (final e in (links as List))
          if (e is Map && e['student_id'] != null) e['student_id'].toString(),
      ];
      if (ids.isEmpty) return const [];
      final rows = await _client
          .from('students')
          .select(_studentSelect)
          .inFilter('id', ids);
      return [
        for (final r in (rows as List))
          if (r is Map)
            EducationRowMapper.studentFromRow(Map<String, dynamic>.from(r)),
      ];
    } catch (e, st) {
      debugPrint('SupabaseEducationRepository.studentsForTeacher: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<List<EducationQuestion>> sampleQuestions({
    required SkillArea skill,
    SkillTier difficulty = SkillTier.easy,
    String? category,
    List<String> excludeIds = const [],
    int count = 10,
  }) async {
    try {
      var query = _client
          .from('activities')
          .select('id, skill, category, title, difficulty, payload, approved')
          .eq('skill', skill.name)
          .eq('difficulty', difficulty.name)
          .eq('approved', true);
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      final rows = await query.limit(40);
      final out = <EducationQuestion>[];
      for (final r in (rows as List)) {
        if (r is! Map) continue;
        final q = EducationRowMapper.questionFromActivityPayload(
          Map<String, dynamic>.from(r),
        );
        if (q != null) out.add(q);
      }
      return QuestionSelection.pickWithoutRecent(
        pool: out,
        recentIds: excludeIds,
        count: count,
      );
    } catch (e, st) {
      debugPrint('SupabaseEducationRepository.sampleQuestions: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> upsertSkillLevel({
    required String studentId,
    required String skillKey,
    required SkillTier tier,
    SkillLevelSource source = SkillLevelSource.teacherSet,
  }) async {
    final uuid = await _resolveStudentUuid(studentId);
    if (uuid == null) {
      throw StateError('Öğrenci bulunamadı: $studentId');
    }
    final row = EducationRowMapper.skillLevelUpsert(
      studentUuid: uuid,
      skillKey: skillKey,
      tier: tier,
      source: source,
    );
    await _client.from('student_skill_levels').upsert(
          row,
          onConflict: 'student_id,skill_key',
        );
  }
}

/// Önce bulut; boş/hata → yerel demo. Kolay geçiş noktası.
class FallbackEducationRepository implements EducationRepository {
  FallbackEducationRepository({
    required this.primary,
    required this.fallback,
  });

  final EducationRepository primary;
  final EducationRepository fallback;

  @override
  Future<StudentProfile?> studentByUserId(String userId) async {
    try {
      final remote = await primary.studentByUserId(userId);
      if (remote != null) return remote;
    } catch (e) {
      debugPrint('Education fallback studentByUserId: $e');
    }
    return fallback.studentByUserId(userId);
  }

  @override
  Future<List<StudentProfile>> studentsForTeacher(String teacherId) async {
    try {
      final remote = await primary.studentsForTeacher(teacherId);
      if (remote.isNotEmpty) return remote;
    } catch (e) {
      debugPrint('Education fallback studentsForTeacher: $e');
    }
    return fallback.studentsForTeacher(teacherId);
  }

  @override
  Future<List<EducationQuestion>> sampleQuestions({
    required SkillArea skill,
    SkillTier difficulty = SkillTier.easy,
    String? category,
    List<String> excludeIds = const [],
    int count = 10,
  }) async {
    try {
      final remote = await primary.sampleQuestions(
        skill: skill,
        difficulty: difficulty,
        category: category,
        excludeIds: excludeIds,
        count: count,
      );
      if (remote.isNotEmpty) return remote;
    } catch (e) {
      debugPrint('Education fallback sampleQuestions: $e');
    }
    return fallback.sampleQuestions(
      skill: skill,
      difficulty: difficulty,
      category: category,
      excludeIds: excludeIds,
      count: count,
    );
  }

  @override
  Future<void> upsertSkillLevel({
    required String studentId,
    required String skillKey,
    required SkillTier tier,
    SkillLevelSource source = SkillLevelSource.teacherSet,
  }) async {
    try {
      await primary.upsertSkillLevel(
        studentId: studentId,
        skillKey: skillKey,
        tier: tier,
        source: source,
      );
    } catch (e) {
      debugPrint('Education fallback upsertSkillLevel: $e');
      await fallback.upsertSkillLevel(
        studentId: studentId,
        skillKey: skillKey,
        tier: tier,
        source: source,
      );
    }
  }
}
