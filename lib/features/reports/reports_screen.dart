import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/report_stats.dart';
import '../../data/models/user_role.dart';
import '../../data/providers.dart';

/// Gelişim raporları: haftalık stres/tetikleyici grafikleri + AI müdahale
/// oranı + dinamik prompt yönetimi.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final role = ref.watch(appStateProvider).role;
    final ruleCount = ref.watch(appStateProvider).therapistRules.rules.length;
    final stats = ref.watch(reportStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gelişim Raporları')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (stats.isEmpty)
            Card(
              elevation: 0,
              color: scheme.surfaceContainerLow,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Henüz yeterli veri yok. Canlı Asistan akışı veya '
                        'Cihaz bağlantısı → Mock izleme başlatınca grafikler '
                        'dolmaya başlar.',
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            _SummaryRow(stats: stats),
            const SizedBox(height: 16),
            _ChartCard(
              title: 'Saatlik stres yoğunluğu',
              subtitle: 'Gözlemlerin gün içindeki dağılımı',
              child: _HourlyStressChart(hourly: stats.hourlyStress),
            ),
            const SizedBox(height: 12),
            _ChartCard(
              title: 'Haftalık AI müdahale oranı',
              subtitle: 'Son 7 gün · gün başına müdahale sayısı',
              child: _WeeklyInterventionChart(
                weekly: stats.weeklyInterventionRate,
              ),
            ),
            const SizedBox(height: 12),
            _TriggersCard(triggers: stats.triggerCounts),
            const SizedBox(height: 12),
          ],
          Card(
            elevation: 0,
            color: scheme.primaryContainer.withValues(alpha: 0.45),
            child: ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Dinamik prompt yönetimi'),
              subtitle: Text(
                role == UserRole.therapist
                    ? (ruleCount == 0
                        ? 'Henüz kural yok. Asistan davranışını buradan güncelleyin.'
                        : '$ruleCount aktif terapist kuralı.')
                    : 'Terapist kurallarını görüntüleyin veya düzenleyin '
                        '(demo: tüm roller erişebilir).',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/prompt/rules'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            child: ListTile(
              leading: const Icon(Icons.terminal),
              title: const Text('System prompt önizleme'),
              subtitle: const Text(
                'Profil + kurallardan üretilen Gemini system prompt\'unu görün.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/prompt/preview'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.stats});

  final ReportStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SummaryTile(
          label: 'Gözlem',
          value: '${stats.totalObservations}',
          icon: Icons.remove_red_eye_outlined,
        ),
        const SizedBox(width: 8),
        _SummaryTile(
          label: 'Müdahale',
          value: '${stats.totalInterventions}',
          icon: Icons.record_voice_over,
        ),
        const SizedBox(width: 8),
        _SummaryTile(
          label: 'Müd. oranı',
          value: '%${(stats.interventionRatio * 100).round()}',
          icon: Icons.percent,
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            SizedBox(height: 160, child: child),
          ],
        ),
      ),
    );
  }
}

class _HourlyStressChart extends StatelessWidget {
  const _HourlyStressChart({required this.hourly});

  final List<int> hourly;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (hourly.every((v) => v == 0)) {
      return const Center(child: Text('Veri bekleniyor…'));
    }
    final maxVal =
        hourly.reduce((a, b) => a > b ? a : b).toDouble().clamp(1, 9999);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxVal + 1,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 6,
              getTitlesWidget: (value, meta) {
                final h = value.toInt();
                if (h % 6 != 0) return const SizedBox.shrink();
                return Text('$h', style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var h = 0; h < hourly.length; h++)
                FlSpot(h.toDouble(), hourly[h].toDouble()),
            ],
            isCurved: true,
            color: scheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: scheme.primary.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyInterventionChart extends StatelessWidget {
  const _WeeklyInterventionChart({required this.weekly});

  final List<int> weekly;

  static const _dayLabels = ['-6', '-5', '-4', '-3', '-2', 'Dün', 'Bugün'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxVal =
        weekly.fold<int>(0, (a, b) => a > b ? a : b).toDouble().clamp(1, 9999);

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxVal + 1,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= _dayLabels.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _dayLabels[i],
                    style: const TextStyle(fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < weekly.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: weekly[i].toDouble(),
                  color: scheme.tertiary,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TriggersCard extends StatelessWidget {
  const _TriggersCard({required this.triggers});

  final Map<String, int> triggers;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = triggers.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tetikleyici dağılımı',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Text(
                'Henüz tetikleyici algılanmadı.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              ...entries.map((e) {
                final max = entries.first.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          e.key,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: max == 0 ? 0 : e.value / max,
                            minHeight: 10,
                            backgroundColor: scheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${e.value}'),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
