import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../app/widgets/luluna_ui.dart';
import '../../../data/models/skill_keys.dart';
import '../../../data/models/skill_level.dart';
import '../../../data/models/student_profile.dart';
import '../../../data/providers.dart';
import '../../analytics/presentation/analytics_providers.dart';
import '../../analytics/presentation/teacher_reports_screen.dart';
import '../../education/domain/level_suggestion.dart';
import '../../education/presentation/activity_session_controller.dart';

/// Öğrenci detay — onaylı seviye + sistem önerisi (otomatik uygulanmaz).
class TeacherStudentDetailScreen extends ConsumerWidget {
  const TeacherStudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  static const _focusKeys = SkillKeys.mvp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teacherStudentsProvider);
    final accessibility = ref.watch(educationAccessibilityProvider);
    final approved = ref.watch(approvedSkillTiersProvider(studentId));
    final suggestions = ref.watch(levelSuggestionsProvider(studentId));
    final textTheme = Theme.of(context).textTheme;

    return EducationAccessibilityScope(
      textScale: accessibility.textScaleFactor,
      highContrast: accessibility.highContrast,
      child: Scaffold(
        backgroundColor: LulunaColors.surface,
        appBar: AppBar(
          title: const Text('Öğrenci'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Geri',
            onPressed: () => context.pop(),
          ),
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (list) {
            StudentProfile? student;
            for (final s in list) {
              if (s.id == studentId) {
                student = s;
                break;
              }
            }
            student ??= list.isNotEmpty ? list.first : null;
            if (student == null) {
              return const Center(child: Text('Öğrenci bulunamadı'));
            }
            final s = student;
            final analytics = ref.watch(studentAnalyticsProvider(studentId));
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: LulunaColors.secondaryContainer,
                      foregroundColor: LulunaColors.onSecondaryContainer,
                      child: Text(
                        s.name.isNotEmpty
                            ? s.name.characters.first.toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (s.birthDate != null)
                            Text(
                              'Doğum: ${s.birthDate!.year}',
                              style: textTheme.bodyMedium?.copyWith(
                                color: LulunaColors.onSurfaceVariant,
                              ),
                            ),
                          Text(
                            analytics.attempts.isEmpty
                                ? 'Henüz deneme yok'
                                : 'Başarı: ${(analytics.successRate * 100).toStringAsFixed(0)}% · '
                                    '${analytics.attempts.length} deneme',
                            style: textTheme.bodyMedium?.copyWith(
                              color: LulunaColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Performans',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                LulunaCard(
                  child: AnalyticsSkillBars(
                    items: analytics.bySkillKey.isNotEmpty
                        ? analytics.bySkillKey
                        : analytics.byCategory,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Beceri seviyeleri',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sistem önerir; sen onaylarsın. Öğrenci yalnızca onaylı '
                  'seviyeyi görür.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: LulunaColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                for (final key in _focusKeys) ...[
                  _SkillLevelCard(
                    studentId: studentId,
                    skillKey: key,
                    approved: approved[key] ?? SkillTier.easy,
                    suggestion: _suggestionFor(suggestions, key),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  static LevelSuggestion? _suggestionFor(
    List<LevelSuggestion> list,
    String key,
  ) {
    for (final s in list) {
      if (s.skillKey == key) return s;
    }
    return null;
  }
}

class _SkillLevelCard extends ConsumerWidget {
  const _SkillLevelCard({
    required this.studentId,
    required this.skillKey,
    required this.approved,
    required this.suggestion,
  });

  final String studentId;
  final String skillKey;
  final SkillTier approved;
  final LevelSuggestion? suggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final suggested = suggestion?.suggestedLevel ?? approved;
    final differs = suggestion?.differsFromCurrent == true;
    final reason = suggestion?.reason ?? '';

    return LulunaCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  SkillKeys.label(skillKey),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SkillTierChip(tier: approved),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Onaylı: ${approved.label}',
            style: textTheme.bodyMedium,
          ),
          Text(
            differs
                ? 'Önerilen: ${suggested.label}'
                : 'Önerilen: mevcut seviye uygun',
            style: textTheme.bodyMedium?.copyWith(
              color: differs
                  ? LulunaColors.primary
                  : LulunaColors.onSurfaceVariant,
              fontWeight: differs ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              reason,
              style: textTheme.bodySmall?.copyWith(
                color: LulunaColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tier in SkillTier.values)
                ChoiceChip(
                  label: Text(tier.label),
                  selected: approved == tier,
                  onSelected: (_) => _setLevel(ref, tier),
                ),
              if (differs)
                FilledButton(
                  onPressed: () => _setLevel(ref, suggested),
                  child: Text('Öneriyi onayla (${suggested.label})'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _setLevel(WidgetRef ref, SkillTier tier) async {
    await ref.read(studentSkillLevelRepositoryProvider).setTeacherLevel(
          studentId: studentId,
          skillKey: skillKey,
          tier: tier,
        );
    // Best-effort bulut senkronu (Supabase yoksa demo no-op / fallback).
    try {
      await ref.read(educationRepositoryProvider).upsertSkillLevel(
            studentId: studentId,
            skillKey: skillKey,
            tier: tier,
          );
    } catch (_) {}
    ref.read(skillLevelRefreshProvider.notifier).bump();
  }
}
