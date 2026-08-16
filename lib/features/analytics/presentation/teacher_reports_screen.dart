import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../app/widgets/luluna_ui.dart';
import '../domain/analytics_models.dart';
import 'analytics_providers.dart';

class TeacherReportsScreen extends ConsumerWidget {
  const TeacherReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(teacherAnalyticsOverviewProvider);
    final preset = ref.watch(reportDatePresetProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: const Text('Raporlar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/teacher'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Öğrenci performansı',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Öğrenci, tarih aralığı, doğru/yanlış ve beceri bazlı başarı.',
            style: textTheme.bodyMedium?.copyWith(
              color: LulunaColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in ReportDatePreset.values)
                ChoiceChip(
                  label: Text(_presetLabel(p)),
                  selected: preset == p,
                  onSelected: (_) =>
                      ref.read(reportDatePresetProvider.notifier).set(p),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (overview.isEmpty)
            const EducationStatusPanel(
              title: 'Veri yok',
              body: 'Öğrenciler etkinlik çözdükçe burada özet görünür.',
            )
          else
            for (final row in overview) ...[
              LulunaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            row.name,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          row.analytics.attempts.isEmpty
                              ? '—'
                              : '${(row.analytics.successRate * 100).toStringAsFixed(0)}%',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: LulunaColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Etkinlik: ${row.analytics.completedActivities} · '
                      'Doğru: ${row.analytics.attempts.where((e) => e.correct).length} · '
                      'Yanlış: ${row.analytics.attempts.where((e) => !e.correct).length} · '
                      'Hata: ${row.analytics.attempts.isEmpty ? 0 : (row.analytics.errorRate * 100).toStringAsFixed(0)}%',
                      style: textTheme.bodyMedium?.copyWith(
                        color: LulunaColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '15 öğrenme alanı',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final c in row.analytics.byUnifiedArea)
                          Chip(
                            label: Text(
                              c.attempts > 0
                                  ? '${c.label}: '
                                      '${(c.successRate * 100).toStringAsFixed(0)}%'
                                  : '${c.label}: —',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: c.attempts > 0
                                ? LulunaColors.secondaryContainer
                                : LulunaColors.surfaceContainer,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Beceri bazlı',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (row.analytics.bySkillKey.isEmpty &&
                        row.analytics.byCategory.isEmpty)
                      Text(
                        'Henüz kategori verisi yok',
                        style: textTheme.bodySmall,
                      )
                    else
                      for (final c in (row.analytics.bySkillKey.isNotEmpty
                              ? row.analytics.bySkillKey
                              : row.analytics.byCategory)
                          .take(6)) ...[
                        _SkillBar(perf: c),
                        const SizedBox(height: 8),
                      ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.push(
                              '/teacher/student/${row.id}',
                            ),
                            child: const Text('Detay'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _createReport(
                              context,
                              ref,
                              studentId: row.id,
                              name: row.name,
                              analytics: row.analytics,
                            ),
                            child: const Text('Rapor Oluştur'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  String _presetLabel(ReportDatePreset p) => switch (p) {
        ReportDatePreset.days7 => '7 gün',
        ReportDatePreset.days30 => '30 gün',
        ReportDatePreset.days90 => '90 gün',
        ReportDatePreset.all => 'Tümü',
      };

  Future<void> _createReport(
    BuildContext context,
    WidgetRef ref, {
    required String studentId,
    required String name,
    required StudentAnalytics analytics,
  }) async {
    final range = dateRangeForPreset(ref.read(reportDatePresetProvider));
    final report = ref.read(analyticsServiceProvider).report(
          studentId: studentId,
          studentName: name,
          analytics: analytics,
          from: range.from,
          to: range.to,
        );
    final text =
        await ref.read(reportExportServiceProvider).exportStudentReport(report);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LulunaColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Öğrenci raporu',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: SingleChildScrollView(
                  child: SelectableText(text),
                ),
              ),
              const SizedBox(height: 16),
              LulunaPrimaryButton(
                label: 'Panoya kopyala',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rapor panoya kopyalandı')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SkillBar extends StatelessWidget {
  const _SkillBar({required this.perf});

  final CategoryPerformance perf;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${perf.label} (${perf.correct} doğru / ${perf.wrong} yanlış)',
              ),
            ),
            Text('${(perf.successRate * 100).toStringAsFixed(0)}%'),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: perf.successRate.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: LulunaColors.surfaceContainer,
          ),
        ),
      ],
    );
  }
}

/// Öğrenci detayında kullanılan progress satırı.
class AnalyticsSkillBars extends StatelessWidget {
  const AnalyticsSkillBars({super.key, required this.items});

  final List<CategoryPerformance> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('Henüz performans verisi yok.');
    }
    return Column(
      children: [
        for (final c in items) ...[
          _SkillBar(perf: c),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
