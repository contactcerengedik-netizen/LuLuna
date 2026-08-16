import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../data/models/skill_keys.dart';
import '../../../data/models/skill_level.dart';
import '../../../data/providers.dart';
import '../domain/activity_models.dart';
import 'activity_session_controller.dart';

class CategoryHubScreen extends ConsumerWidget {
  const CategoryHubScreen({
    super.key,
    required this.title,
    required this.skill,
    required this.categories,
    required this.routePrefix,
  });

  final String title;
  final SkillArea skill;
  final List<ActivityCategoryDef> categories;
  final String routePrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibility = ref.watch(educationAccessibilityProvider);
    final profile = ref.watch(currentStudentProfileProvider).asData?.value;
    final studentId = profile?.id ??
        ref.watch(authStateProvider)?.userId ??
        'demo-student';
    final approved = ref.watch(approvedSkillTiersProvider(studentId));

    return EducationAccessibilityScope(
      textScale: accessibility.textScaleFactor,
      highContrast: accessibility.highContrast,
      child: Scaffold(
        backgroundColor: LulunaColors.surface,
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Geri',
            onPressed: () => context.go('/student'),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              'Bir kategori seç',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Seviyeler öğretmen onayına göre ayarlanır.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LulunaColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            for (final c in categories) ...[
              Builder(
                builder: (context) {
                  final key = SkillKeys.fromCategory(c.id);
                  final tier = key != null
                      ? (approved[key] ?? SkillTier.easy)
                      : (profile?.tierFor(skill) ?? SkillTier.easy);
                  return EducationBigTile(
                    title: c.title,
                    subtitle: accessibility.reducedDistractionMode
                        ? 'Onaylı: ${tier.label}'
                        : '${c.description} · Onaylı: ${tier.label}',
                    leading: EducationModuleIcon(
                      icon: _iconFor(c.iconName),
                    ),
                    onTap: () => context.push(
                      '$routePrefix/${c.id}',
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String name) {
    return switch (name) {
      'looks_one' => Icons.looks_one_outlined,
      'pin' => Icons.pin_outlined,
      'search' => Icons.search,
      'swap_vert' => Icons.swap_vert,
      'repeat' => Icons.repeat,
      'more_horiz' => Icons.more_horiz,
      'add' => Icons.add_circle_outline,
      'remove' => Icons.remove_circle_outline,
      'close' => Icons.close,
      'percent' => Icons.percent,
      'pie_chart' => Icons.pie_chart_outline,
      'menu_book' => Icons.menu_book_outlined,
      'bar_chart' => Icons.bar_chart,
      'table_chart' => Icons.table_chart_outlined,
      'checklist' => Icons.checklist,
      'sort_by_alpha' => Icons.sort_by_alpha,
      'quiz' => Icons.quiz_outlined,
      'compare_arrows' => Icons.compare_arrows,
      'sync_alt' => Icons.sync_alt,
      'record_voice_over' => Icons.record_voice_over_outlined,
      'category' => Icons.category_outlined,
      'view_timeline' => Icons.view_timeline_outlined,
      'reorder' => Icons.reorder,
      _ => Icons.extension_outlined,
    };
  }
}

class DifficultySelectScreen extends ConsumerWidget {
  const DifficultySelectScreen({
    super.key,
    required this.title,
    required this.skill,
    required this.categoryId,
    required this.routePrefix,
  });

  final String title;
  final SkillArea skill;
  final String categoryId;
  final String routePrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibility = ref.watch(educationAccessibilityProvider);
    final profile = ref.watch(currentStudentProfileProvider).asData?.value;
    final studentId = profile?.id ??
        ref.watch(authStateProvider)?.userId ??
        'demo-student';
    final skillKey = SkillKeys.fromCategory(categoryId);
    final approvedMap = ref.watch(approvedSkillTiersProvider(studentId));
    final approved = skillKey != null
        ? (approvedMap[skillKey] ?? SkillTier.easy)
        : (profile?.tierFor(skill) ?? SkillTier.easy);

    return EducationAccessibilityScope(
      textScale: accessibility.textScaleFactor,
      highContrast: accessibility.highContrast,
      child: Scaffold(
        backgroundColor: LulunaColors.surface,
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Seviye seç',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Onaylı seviye: ${approved.label}. '
              'İçerik bu seviyeye göre üretilir; istersen başka seviye seçebilirsin.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: LulunaColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            for (final tier in SkillTier.values) ...[
              EducationBigTile(
                title: tier.label,
                subtitle: tier == approved ? 'Onaylı seviye' : null,
                trailing: SkillTierChip(tier: tier),
                onTap: () => context.push(
                  '$routePrefix/$categoryId/${tier.name}',
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
