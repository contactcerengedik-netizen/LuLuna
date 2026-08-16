import 'package:flutter_test/flutter_test.dart';

import 'package:luluna/data/models/education_question.dart';
import 'package:luluna/data/models/skill_level.dart';
import 'package:luluna/data/models/student_profile.dart';
import 'package:luluna/data/repositories/education_demo_repository.dart';
import 'package:luluna/data/repositories/education_repository.dart';
import 'package:luluna/data/repositories/education_row_mapper.dart';
import 'package:luluna/data/repositories/supabase_education_repository.dart';
import 'package:luluna/data/services/education_progress_sync.dart';
import 'package:luluna/features/analytics/domain/analytics_models.dart';
import 'package:luluna/features/education/domain/activity_models.dart';

class _EmptyPrimary implements EducationRepository {
  @override
  Future<StudentProfile?> studentByUserId(String userId) async => null;

  @override
  Future<List<StudentProfile>> studentsForTeacher(String teacherId) async =>
      const [];

  @override
  Future<List<EducationQuestion>> sampleQuestions({
    required SkillArea skill,
    SkillTier difficulty = SkillTier.easy,
  }) async =>
      const [];

  @override
  Future<void> upsertSkillLevel({
    required String studentId,
    required String skillKey,
    required SkillTier tier,
    SkillLevelSource source = SkillLevelSource.teacherSet,
  }) async {}
}

class _ThrowingPrimary implements EducationRepository {
  @override
  Future<StudentProfile?> studentByUserId(String userId) async {
    throw StateError('cloud down');
  }

  @override
  Future<List<StudentProfile>> studentsForTeacher(String teacherId) async {
    throw StateError('cloud down');
  }

  @override
  Future<List<EducationQuestion>> sampleQuestions({
    required SkillArea skill,
    SkillTier difficulty = SkillTier.easy,
  }) async {
    throw StateError('cloud down');
  }

  @override
  Future<void> upsertSkillLevel({
    required String studentId,
    required String skillKey,
    required SkillTier tier,
    SkillLevelSource source = SkillLevelSource.teacherSet,
  }) async {
    throw StateError('cloud down');
  }
}

void main() {
  group('EducationRowMapper', () {
    test('studentFromRow skill + teacher join', () {
      final profile = EducationRowMapper.studentFromRow({
        'id': 'stu-1',
        'name': 'Ayşe',
        'birth_date': '2015-03-12',
        'created_at': '2026-01-01T00:00:00.000Z',
        'preferences': {'theme': 'calm'},
        'accessibility': {'highContrast': true},
        'student_skill_levels': [
          {
            'skill': 'mathematics',
            'tier': 'easy',
            'mastery_percent': 40,
          },
        ],
        'teacher_student': [
          {'teacher_id': 'teach-1'},
        ],
      });
      expect(profile.id, 'stu-1');
      expect(profile.name, 'Ayşe');
      expect(profile.teacherIds, ['teach-1']);
      expect(profile.tierFor(SkillArea.mathematics), SkillTier.easy);
      expect(profile.skillLevels.first.masteryPercent, 40);
      expect(profile.accessibility.highContrast, isTrue);
    });

    test('studentFromRow skill_key + source', () {
      final profile = EducationRowMapper.studentFromRow({
        'id': 'stu-1',
        'name': 'Ayşe',
        'student_skill_levels': [
          {
            'skill': 'mathematics',
            'skill_key': 'toplama',
            'tier': 'medium',
            'source': 'teacherSet',
            'mastery_percent': 70,
          },
        ],
        'teacher_student': [],
      });
      expect(profile.skillLevels.single.effectiveSkillKey, 'toplama');
      expect(profile.skillLevels.single.tier, SkillTier.medium);
      expect(profile.skillLevels.single.source, SkillLevelSource.teacherSet);
    });

    test('skillLevelUpsert alanları', () {
      final row = EducationRowMapper.skillLevelUpsert(
        studentUuid: 's1',
        skillKey: '5n1k',
        tier: SkillTier.hard,
      );
      expect(row['skill_key'], '5n1k');
      expect(row['skill'], 'language');
      expect(row['tier'], 'hard');
      expect(row['source'], 'teacherSet');
    });

    test('questionFromActivityPayload', () {
      final q = EducationRowMapper.questionFromActivityPayload({
        'id': 'act-1',
        'skill': 'mathematics',
        'category': 'addition',
        'title': 'Toplama',
        'difficulty': 'easy',
        'payload': {
          'instruction': 'Topla',
          'questionText': '2+2',
          'choices': ['3', '4'],
          'correctAnswer': '4',
        },
      });
      expect(q, isNotNull);
      expect(q!.correctAnswer, '4');
      expect(q.isCorrect('4'), isTrue);
    });

    test('attemptAnswerInsert / sessionInsert alanları', () {
      final a = EducationRowMapper.attemptAnswerInsert(
        studentUuid: 's1',
        skill: 'mathematics',
        category: 'addition',
        difficulty: 'easy',
        questionId: 'q1',
        givenAnswer: '4',
        correct: true,
        attemptedAt: DateTime(2026, 8, 1),
      );
      expect(a['student_id'], 's1');
      expect(a['correct'], isTrue);

      final s = EducationRowMapper.sessionInsert(
        studentUuid: 's1',
        skill: 'mathematics',
        category: 'addition',
        difficulty: 'easy',
        startedAt: DateTime(2026, 8, 1, 10),
        finishedAt: DateTime(2026, 8, 1, 10, 5),
        correctCount: 3,
        wrongCount: 1,
        attemptCount: 4,
        score: 75,
        durationMs: 300000,
      );
      expect(s['correct_count'], 3);
      expect(s['category'], 'addition');
    });
  });

  group('FallbackEducationRepository', () {
    test('boş bulutta demo’ya düşer', () async {
      final repo = FallbackEducationRepository(
        primary: _EmptyPrimary(),
        fallback: InMemoryEducationRepository(),
      );
      final student = await repo.studentByUserId('uid-1');
      expect(student, isNotNull);
      expect(student!.name, 'Ayşe');
      final list = await repo.studentsForTeacher('t1');
      expect(list.length, 2);
      final qs = await repo.sampleQuestions(skill: SkillArea.mathematics);
      expect(qs, isNotEmpty);
    });

    test('hata durumunda demo’ya düşer', () async {
      final repo = FallbackEducationRepository(
        primary: _ThrowingPrimary(),
        fallback: InMemoryEducationRepository(),
      );
      final student = await repo.studentByUserId('x');
      expect(student?.name, 'Ayşe');
    });
  });

  group('NoopEducationProgressSync', () {
    test('hata vermez', () async {
      const sync = NoopEducationProgressSync();
      await sync.pushAttempt(
        ActivityAttempt(
          id: '1',
          studentId: 's',
          skill: 'mathematics',
          category: 'addition',
          difficulty: 'easy',
          questionId: 'q',
          givenAnswer: '1',
          correct: false,
          attemptedAt: DateTime(2026, 8, 1),
        ),
      );
      await sync.pushSession(
        ActivitySessionEvent(
          id: 'sess',
          studentId: 's',
          activityId: 'a',
          skill: 'mathematics',
          category: 'addition',
          difficulty: 'easy',
          startedAt: DateTime(2026, 8, 1),
          finishedAt: DateTime(2026, 8, 1, 0, 5),
          correctCount: 1,
          wrongCount: 0,
          attemptCount: 1,
          score: 100,
          durationMs: 5000,
        ),
      );
    });
  });
}
