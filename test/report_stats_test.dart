import 'package:flutter_test/flutter_test.dart';
import 'package:luluna/data/models/assistant_log.dart';
import 'package:luluna/data/models/report_stats.dart';

void main() {
  final base = DateTime(2026, 7, 25, 10);

  AssistantLog log(LogType type, String message, DateTime ts) =>
      AssistantLog(timestamp: ts, type: type, message: message);

  test('boş log listesi empty stats üretir', () {
    final stats = buildReportStats(const [], now: base);
    expect(stats.isEmpty, isTrue);
    expect(stats.interventionRatio, 0);
    expect(stats.weeklyInterventionRate, hasLength(7));
  });

  test('yerel ve uzak loglar birleştirilirken tekrarlar temizlenir', () {
    final duplicate = log(LogType.observation, 'Önde köpek var', base);
    final remoteOnly = log(
      LogType.intervention,
      'Sakin bir nefes al.',
      base.add(const Duration(seconds: 1)),
    );

    final merged = mergeAssistantLogs([duplicate], [duplicate, remoteOnly]);

    expect(merged, hasLength(2));
    expect(merged.first.message, 'Sakin bir nefes al.');
    expect(buildReportStats(merged, now: base).totalObservations, 1);
  });

  test('gözlem/müdahale/pekiştireç sayıları doğru toplanır', () {
    final logs = [
      log(LogType.observation, 'Önde köpek var', base),
      log(LogType.observation, 'Kalabalık arttı', base),
      log(LogType.intervention, 'Korkma', base),
      log(LogType.praise, 'Harikasın!', base),
      log(LogType.system, 'bağlandı', base),
    ];
    final stats = buildReportStats(logs, now: base);

    expect(stats.totalObservations, 2);
    expect(stats.totalInterventions, 1);
    expect(stats.totalPraises, 1);
    expect(stats.interventionRatio, closeTo(0.5, 0.001));
  });

  test('tetikleyici anahtar kelimeler gözlemden sayılır', () {
    final logs = [
      log(LogType.observation, 'Önde bir KÖPEK', base),
      log(LogType.observation, 'köpek yine geldi', base),
      log(LogType.observation, 'çok gürültü var', base),
    ];
    final stats = buildReportStats(logs, now: base);

    expect(stats.triggerCounts['köpek'], 2);
    expect(stats.triggerCounts['gürültü'], 1);
    expect(stats.triggerCounts.containsKey('kırmızı'), isFalse);
  });

  test('saatlik dağılım gözlem saatine göre dolar', () {
    final logs = [
      log(LogType.observation, 'x', DateTime(2026, 7, 25, 9)),
      log(LogType.observation, 'y', DateTime(2026, 7, 25, 9)),
      log(LogType.observation, 'z', DateTime(2026, 7, 25, 14)),
    ];
    final stats = buildReportStats(logs, now: base);

    expect(stats.hourlyStress[9], 2);
    expect(stats.hourlyStress[14], 1);
    expect(stats.hourlyStress[0], 0);
  });

  test('haftalık müdahaleler doğru güne yerleşir', () {
    final logs = [
      log(LogType.intervention, 'bugün', base),
      log(LogType.intervention, 'dün', base.subtract(const Duration(days: 1))),
      log(
        LogType.intervention,
        'eski',
        base.subtract(const Duration(days: 10)),
      ),
    ];
    final stats = buildReportStats(logs, now: base);

    expect(stats.weeklyInterventionRate[6], 1); // bugün
    expect(stats.weeklyInterventionRate[5], 1); // dün
    // 10 gün önceki pencere dışında kalır
    expect(stats.weeklyInterventionRate.reduce((a, b) => a + b), 2);
  });
}
