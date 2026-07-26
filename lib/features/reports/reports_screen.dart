import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../app/widgets/luluna_ui.dart';
import '../../data/models/report_stats.dart';
import '../../data/models/user_role.dart';
import '../../data/providers.dart';

/// Gelişim raporları: haftalık stres/tetikleyici grafikleri + AI müdahale
/// oranı + dinamik prompt yönetimi.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(appStateProvider).role;
    final ruleCount = ref.watch(appStateProvider).therapistRules.rules.length;
    final stats = ref.watch(reportStatsProvider);
    final remoteHistory = ref.watch(remoteAssistantLogsProvider);
    final cloudEnabled = ref.watch(supabaseClientProvider) != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gelişim Raporları'),
        actions: [
          if (cloudEnabled)
            IconButton(
              tooltip: 'Bulut geçmişini yenile',
              onPressed: () => ref.invalidate(remoteAssistantLogsProvider),
              icon: const Icon(Icons.cloud_sync_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (remoteHistory.isLoading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
          ],
          if (remoteHistory.hasError) ...[
            LulunaCard(
              color: LulunaColors.errorContainer,
              child: Row(
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    color: LulunaColors.onErrorContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bulut raporları alınamadı',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: LulunaColors.onErrorContainer,
                                  ),
                        ),
                        Text(
                          'Yerel veriler gösteriliyor. Bağlantıyı kontrol edip '
                          'yenileme düğmesine dokunun.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: LulunaColors.onErrorContainer,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (stats.isEmpty)
            LulunaCard(
              child: Row(
                children: [
                  LulunaIconBadge(icon: Icons.info_outline),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Henüz yeterli veri yok. Canlı Asistan veya Cihaz '
                      'bağlantısı ile izleme başlatınca grafikler dolar.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
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
          if (role == UserRole.therapist)
            Material(
              color: LulunaColors.secondaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push('/prompt/rules'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: LulunaColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_note,
                          color: LulunaColors.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dinamik prompt yönetimi',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: LulunaColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              ruleCount == 0
                                  ? 'Henüz kural yok. Asistan davranışını buradan güncelleyin.'
                                  : '$ruleCount aktif terapist kuralı.',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: LulunaColors.outline,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Material(
            color: LulunaColors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/prompt/preview'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: LulunaColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.terminal,
                        color: LulunaColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'System prompt önizleme',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: LulunaColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            'Profil + kurallardan üretilen Gemini system prompt\'unu görün.',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: LulunaColors.outline,
                    ),
                  ],
                ),
              ),
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
          icon: Icons.visibility_outlined,
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
    return Expanded(
      child: LulunaCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: LulunaColors.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: LulunaColors.primary,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: LulunaColors.onSurfaceVariant,
                  ),
            ),
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
    return LulunaCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: LulunaColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: LulunaColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 160, child: child),
        ],
      ),
    );
  }
}

class _HourlyStressChart extends StatelessWidget {
  const _HourlyStressChart({required this.hourly});

  final List<int> hourly;

  @override
  Widget build(BuildContext context) {
    if (hourly.every((v) => v == 0)) {
      return const Center(child: Text('Veri bekleniyor…'));
    }
    final maxVal = hourly
        .reduce((a, b) => a > b ? a : b)
        .toDouble()
        .clamp(1, 9999);

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
                return Text(
                  '$h',
                  style: const TextStyle(
                    fontSize: 10,
                    color: LulunaColors.onSurfaceVariant,
                  ),
                );
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
            color: LulunaColors.primaryContainer,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: LulunaColors.primaryContainer.withValues(alpha: 0.15),
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
    final maxVal = weekly
        .fold<int>(0, (a, b) => a > b ? a : b)
        .toDouble()
        .clamp(1, 9999);

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
                final isToday = i == weekly.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _dayLabels[i],
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                      color: isToday
                          ? LulunaColors.primary
                          : LulunaColors.onSurfaceVariant,
                    ),
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
                  color: i == weekly.length - 1
                      ? LulunaColors.primary
                      : LulunaColors.secondaryContainer.withValues(alpha: 0.55),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
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
    final entries = triggers.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return LulunaCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tetikleyici dağılımı',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: LulunaColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            Text(
              'Henüz tetikleyici algılanmadı.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...entries.map((e) {
              final max = entries.first.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.key,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                        Text(
                          '${e.value}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: LulunaColors.primary,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: max == 0 ? 0 : e.value / max,
                        minHeight: 8,
                        backgroundColor: LulunaColors.surfaceContainer,
                        color: LulunaColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
