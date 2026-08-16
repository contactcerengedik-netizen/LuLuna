import 'package:flutter_test/flutter_test.dart';

import 'package:luluna/data/models/skill_keys.dart';
import 'package:luluna/features/analytics/domain/analytics_models.dart';
import 'package:luluna/features/analytics/domain/analytics_service.dart';
import 'package:luluna/features/analytics/domain/report_export_service.dart';
import 'package:luluna/features/education/domain/activity_models.dart';

void main() {
  const service = AnalyticsService();

  ActivityAttempt attempt({
    required String studentId,
    required String category,
    required bool correct,
    DateTime? at,
  }) {
    return ActivityAttempt(
      id: 'a_${category}_${correct}_${at?.day ?? 0}',
      studentId: studentId,
      skill: 'mathematics',
      category: category,
      difficulty: 'easy',
      questionId: 'q1',
      givenAnswer: correct ? 'ok' : 'x',
      correct: correct,
      attemptedAt: at ?? DateTime(2026, 8, 1),
    );
  }

  group('AnalyticsService', () {
    test('başarı / hata oranı ve kategori barları', () {
      final attempts = [
        attempt(studentId: 'demo-student-1', category: 'addition', correct: true),
        attempt(studentId: 'demo-student-1', category: 'addition', correct: true),
        attempt(studentId: 'demo-student-1', category: 'addition', correct: false),
        attempt(
          studentId: 'demo-student-1',
          category: 'subtraction',
          correct: false,
        ),
      ];
      final sessions = [
        ActivitySessionEvent(
          id: 's1',
          studentId: 'demo-student-1',
          activityId: 'mathematics_addition',
          skill: 'mathematics',
          category: 'addition',
          difficulty: 'easy',
          startedAt: DateTime(2026, 8, 1, 10),
          finishedAt: DateTime(2026, 8, 1, 10, 5),
          correctCount: 2,
          wrongCount: 1,
          attemptCount: 3,
          score: 66.7,
          durationMs: 300000,
        ),
      ];

      final analytics = service.build(
        studentId: 'demo-student-1',
        attempts: attempts,
        sessions: sessions,
      );

      expect(analytics.completedActivities, 1);
      expect(analytics.successRate, closeTo(0.5, 0.01));
      expect(analytics.errorRate, closeTo(0.5, 0.01));
      expect(analytics.byCategory.length, 2);
      final addition =
          analytics.byCategory.firstWhere((c) => c.categoryId == 'addition');
      expect(addition.successRate, closeTo(2 / 3, 0.01));

      final toplama = analytics.bySkillKey
          .firstWhere((c) => c.categoryId == SkillKeys.addition);
      expect(toplama.correct, 2);
      expect(toplama.wrong, 1);
    });

    test('tarih aralığı filtreler', () {
      final attempts = [
        attempt(
          studentId: 'demo-student-1',
          category: 'addition',
          correct: true,
          at: DateTime(2026, 7, 1),
        ),
        attempt(
          studentId: 'demo-student-1',
          category: 'addition',
          correct: false,
          at: DateTime(2026, 8, 10),
        ),
      ];
      final analytics = service.build(
        studentId: 'demo-student-1',
        attempts: attempts,
        sessions: const [],
        from: DateTime(2026, 8, 1),
        to: DateTime(2026, 8, 31),
      );
      expect(analytics.attempts, hasLength(1));
      expect(analytics.successRate, 0);
    });

    test('demo alias: auth uid denemeleri demo-student-1 ile eşleşir', () {
      final attempts = [
        attempt(studentId: 'auth-uid-xyz', category: 'addition', correct: true),
      ];
      final forAyse = service.build(
        studentId: 'demo-student-1',
        attempts: attempts,
        sessions: const [],
      );
      expect(forAyse.attempts.length, 1);

      final forMehmet = service.build(
        studentId: 'demo-student-2',
        attempts: attempts,
        sessions: const [],
      );
      expect(forMehmet.attempts, isEmpty);
    });

    test('StudentReport + metin export doğru/yanlış içerir', () async {
      final analytics = service.build(
        studentId: 'demo-student-1',
        attempts: [
          attempt(
            studentId: 'demo-student-1',
            category: 'addition',
            correct: true,
          ),
          attempt(
            studentId: 'demo-student-1',
            category: 'five_w1h',
            correct: false,
          ),
        ],
        sessions: const [],
      );
      final report = service.report(
        studentId: 'demo-student-1',
        studentName: 'Ayşe',
        analytics: analytics,
        from: DateTime(2026, 7, 1),
        to: DateTime(2026, 8, 31),
      );
      expect(report.studentName, 'Ayşe');
      expect(report.correctCount, 1);
      expect(report.wrongCount, 1);
      expect(report.successRate, 0.5);

      final text = await TextReportExportService().exportStudentReport(report);
      expect(text, contains('Ayşe'));
      expect(text, contains('Doğru: 1'));
      expect(text, contains('Yanlış: 1'));
      expect(text, contains('Beceri bazlı'));
    });
  });
}
