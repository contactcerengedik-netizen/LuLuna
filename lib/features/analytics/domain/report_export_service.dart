import '../domain/analytics_models.dart';

/// PDF export ileride; şimdilik metin özeti.
abstract class ReportExportService {
  Future<String> exportStudentReport(StudentReport report);
}

class TextReportExportService implements ReportExportService {
  @override
  Future<String> exportStudentReport(StudentReport report) async {
    final buf = StringBuffer()
      ..writeln('LuLuna Öğrenci Raporu')
      ..writeln('Öğrenci: ${report.studentName}')
      ..writeln(
        'Tarih: ${report.dateRangeStart.toIso8601String().substring(0, 10)}'
        ' → ${report.dateRangeEnd.toIso8601String().substring(0, 10)}',
      )
      ..writeln('Tamamlanan etkinlik: ${report.completedActivities}')
      ..writeln('Doğru: ${report.correctCount} · Yanlış: ${report.wrongCount}')
      ..writeln(
        'Başarı: ${(report.successRate * 100).toStringAsFixed(0)}%',
      )
      ..writeln(
        'Hata: ${(report.errorRate * 100).toStringAsFixed(0)}%',
      )
      ..writeln('--- Beceri bazlı başarı ---');
    for (final s in report.skillScores) {
      buf.writeln(
        '${s.label}: ${(s.successRate * 100).toStringAsFixed(0)}% '
        '(${s.correct}/${s.attempts})',
      );
    }
    if (report.teacherNotes.isNotEmpty) {
      buf.writeln('Notlar: ${report.teacherNotes}');
    }
    return buf.toString();
  }
}
