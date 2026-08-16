import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../data/models/skill_level.dart';
import '../../../data/providers.dart';
import '../../analytics/presentation/analytics_providers.dart';

/// Öğretmen paneli — öğrenci listesi + araçlar.
class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(teacherStudentsProvider);
    final overview = ref.watch(teacherAnalyticsOverviewProvider);
    final accessibility = ref.watch(educationAccessibilityProvider);
    final textTheme = Theme.of(context).textTheme;

    String successFor(String id) {
      for (final row in overview) {
        if (row.id == id) {
          if (row.analytics.attempts.isEmpty) return 'Veri yok';
          return 'Başarı ${(row.analytics.successRate * 100).toStringAsFixed(0)}%';
        }
      }
      return 'Veri yok';
    }

    return EducationAccessibilityScope(
      textScale: accessibility.textScaleFactor,
      highContrast: accessibility.highContrast,
      child: Scaffold(
        backgroundColor: LulunaColors.surface,
        appBar: AppBar(
          title: const Text('Öğretmen Paneli'),
          actions: [
            IconButton(
              tooltip: 'Çıkış',
              onPressed: () async {
                await ref.read(authStateProvider.notifier).signOut();
                if (context.mounted) context.go('/auth');
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              'Öğrencilerim',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bir öğrenciyi seçerek beceri seviyelerini gör.',
              style: textTheme.bodyMedium?.copyWith(
                color: LulunaColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            studentsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => EducationStatusPanel(
                title: 'Yüklenemedi',
                body: '$e',
                icon: Icons.error_outline,
              ),
              data: (students) {
                if (students.isEmpty) {
                  return const EducationStatusPanel(
                    title: 'Henüz öğrenci yok',
                    body: 'Demo modunda örnek öğrenciler burada görünür.',
                  );
                }
                return Column(
                  children: [
                    for (final s in students) ...[
                      EducationBigTile(
                        title: s.name,
                        subtitle: [
                          successFor(s.id),
                          if (s.skillLevels.isNotEmpty)
                            s.skillLevels
                                .where(
                                  (e) =>
                                      e.skill == SkillArea.mathematics ||
                                      e.skill == SkillArea.language ||
                                      e.skill == SkillArea.puzzle,
                                )
                                .map(
                                  (e) =>
                                      '${e.skill.label}: ${e.tier.label}',
                                )
                                .take(2)
                                .join(' · '),
                        ].where((e) => e.isNotEmpty).join(' · '),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: LulunaColors.secondaryContainer,
                          foregroundColor: LulunaColors.onSecondaryContainer,
                          child: Text(
                            s.name.isNotEmpty
                                ? s.name.characters.first.toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        onTap: () =>
                            context.push('/teacher/student/${s.id}'),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            Text(
              'Araçlar',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ödev, AI içerik ve raporlar hazır; performans Raporlar’da.',
              style: textTheme.bodyMedium?.copyWith(
                color: LulunaColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            EducationBigTile(
              title: 'Ödevler',
              subtitle: 'Öğrenciye aktivite ata',
              leading: const EducationModuleIcon(
                icon: Icons.assignment_outlined,
              ),
              onTap: () => context.push('/teacher/assignments'),
            ),
            const SizedBox(height: 12),
            EducationBigTile(
              title: 'Kavram Motoru',
              subtitle: 'Tek kavram → 15 alana yay',
              leading: const EducationModuleIcon(icon: Icons.hub_outlined),
              onTap: () => context.push('/teacher/concepts'),
            ),
            const SizedBox(height: 12),
            EducationBigTile(
              title: 'AI ile Etkinlik Oluştur',
              subtitle: 'Önizle ve onayla',
              leading: const EducationModuleIcon(icon: Icons.auto_awesome),
              onTap: () => context.push('/teacher/ai-content'),
            ),
            const SizedBox(height: 12),
            EducationBigTile(
              title: 'Raporlar',
              subtitle: '15 alan birleşik analytics',
              leading: const EducationModuleIcon(
                icon: Icons.insights_outlined,
              ),
              onTap: () => context.push('/teacher/reports'),
            ),
          ],
        ),
      ),
    );
  }
}
