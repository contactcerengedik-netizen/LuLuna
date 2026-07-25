import 'assistant_log.dart';

/// Loglardan üretilen özet istatistikler. Terapist raporları bu modeli tüketir.
class ReportStats {
  const ReportStats({
    required this.hourlyStress,
    required this.triggerCounts,
    required this.weeklyInterventionRate,
    required this.totalObservations,
    required this.totalInterventions,
    required this.totalPraises,
  });

  /// 0–23 saat başına stres/gözlem yoğunluğu (24 elemanlı).
  final List<int> hourlyStress;

  /// Tetikleyici anahtar kelime → görülme sayısı.
  final Map<String, int> triggerCounts;

  /// Son 7 gün için gün başına müdahale sayısı (7 elemanlı, en eski → en yeni).
  final List<int> weeklyInterventionRate;

  final int totalObservations;
  final int totalInterventions;
  final int totalPraises;

  /// Müdahale / gözlem oranı (0–1). Gözlem yoksa 0.
  double get interventionRatio =>
      totalObservations == 0 ? 0 : totalInterventions / totalObservations;

  bool get isEmpty =>
      totalObservations == 0 &&
      totalInterventions == 0 &&
      totalPraises == 0;

  static const empty = ReportStats(
    hourlyStress: [],
    triggerCounts: {},
    weeklyInterventionRate: [0, 0, 0, 0, 0, 0, 0],
    totalObservations: 0,
    totalInterventions: 0,
    totalPraises: 0,
  );
}

/// Bilinen tetikleyici anahtar kelimeler; gözlem metninde aranır.
const kTriggerKeywords = <String>[
  'köpek',
  'kalabalık',
  'gürültü',
  'yüksek ses',
  'kırmızı',
  'karanlık',
];

/// Log listesinden istatistik üretir (saf fonksiyon → kolay test edilir).
ReportStats buildReportStats(
  List<AssistantLog> logs, {
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final hourly = List<int>.filled(24, 0);
  final triggers = <String, int>{};
  final weekly = List<int>.filled(7, 0);

  var observations = 0;
  var interventions = 0;
  var praises = 0;

  for (final log in logs) {
    switch (log.type) {
      case LogType.observation:
        observations++;
        hourly[log.timestamp.hour]++;
        final lower = log.message.toLowerCase();
        for (final keyword in kTriggerKeywords) {
          if (lower.contains(keyword)) {
            triggers[keyword] = (triggers[keyword] ?? 0) + 1;
          }
        }
      case LogType.intervention:
        interventions++;
        final dayDiff = _dayIndex(reference, log.timestamp);
        if (dayDiff != null) weekly[dayDiff]++;
      case LogType.praise:
        praises++;
      case LogType.system:
        break;
    }
  }

  return ReportStats(
    hourlyStress: hourly,
    triggerCounts: triggers,
    weeklyInterventionRate: weekly,
    totalObservations: observations,
    totalInterventions: interventions,
    totalPraises: praises,
  );
}

/// [ts] son 7 güne düşüyorsa 0..6 indeks (0 = 6 gün önce, 6 = bugün).
int? _dayIndex(DateTime reference, DateTime ts) {
  final refDay = DateTime(reference.year, reference.month, reference.day);
  final tsDay = DateTime(ts.year, ts.month, ts.day);
  final diff = refDay.difference(tsDay).inDays;
  if (diff < 0 || diff > 6) return null;
  return 6 - diff;
}
