import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../app/widgets/luluna_ui.dart';
import '../../../data/models/skill_level.dart';
import '../../../data/providers.dart';
import 'education_accessibility_sheet.dart';

/// Öğrenci ana ekranı — MVP: Matematik, Türkçe, Puzzle.
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  static const _modules = <_ModuleCardData>[
    _ModuleCardData(
      title: 'Matematik',
      subtitle: 'Dört işlem ve kesirler',
      skill: SkillArea.mathematics,
      icon: Icons.calculate_outlined,
      route: '/student/math',
    ),
    _ModuleCardData(
      title: 'Türkçe',
      subtitle: '5N1K ve zıt kavramlar',
      skill: SkillArea.language,
      icon: Icons.menu_book_outlined,
      route: '/student/language',
    ),
    _ModuleCardData(
      title: 'Puzzle',
      subtitle: 'Parçaları yerine yerleştir',
      skill: SkillArea.puzzle,
      icon: Icons.extension_outlined,
      route: '/student/puzzle',
    ),
    _ModuleCardData(
      title: 'Çizgi / Motor',
      subtitle: 'Nokta birleştir, harf ve sayı takip',
      skill: SkillArea.tracing,
      icon: Icons.gesture,
      route: '/student/tracing',
    ),
    _ModuleCardData(
      title: 'Boyama',
      subtitle: 'Fırça ile boya (doldur yok)',
      skill: SkillArea.coloring,
      icon: Icons.palette_outlined,
      route: '/student/coloring',
    ),
    _ModuleCardData(
      title: 'Eşleştirme',
      subtitle: 'Gruplara sürükle-bırak',
      skill: SkillArea.visualPerception,
      icon: Icons.category_outlined,
      route: '/student/categorize',
    ),
    _ModuleCardData(
      title: 'Mantık / Veri',
      subtitle: 'Örüntü, sıralama, grafik okuma',
      skill: SkillArea.visualPerception,
      icon: Icons.psychology_outlined,
      route: '/student/cognition',
    ),
    _ModuleCardData(
      title: 'Hafıza / Dikkat',
      subtitle: 'Kart eşleştir, kısa bakıp hatırla',
      skill: SkillArea.visualPerception,
      icon: Icons.memory,
      route: '/student/memory',
    ),
    _ModuleCardData(
      title: 'Konuşma / Sosyal',
      subtitle: 'Telaffuz, iletişim, duygu diyaloğu',
      skill: SkillArea.communication,
      icon: Icons.record_voice_over_outlined,
      route: '/student/speech',
    ),
    _ModuleCardData(
      title: 'Günlük Yaşam',
      subtitle: 'Rutin, AAC, senaryolar',
      skill: SkillArea.dailyLife,
      icon: Icons.home_outlined,
      route: '/student/daily-life',
    ),
    _ModuleCardData(
      title: 'Kavram etkinlikleri',
      subtitle: 'Öğretmenin yayınladığı içerikler',
      skill: SkillArea.language,
      icon: Icons.hub_outlined,
      route: '/student/concepts',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final accessibility = ref.watch(educationAccessibilityProvider);
    final profileAsync = ref.watch(currentStudentProfileProvider);
    final textTheme = Theme.of(context).textTheme;
    final name = auth?.displayName?.trim().isNotEmpty == true
        ? auth!.displayName!.trim()
        : profileAsync.asData?.value?.name;
    final reduce = accessibility.reducedDistractionMode;

    return EducationAccessibilityScope(
      textScale: accessibility.textScaleFactor,
      highContrast: accessibility.highContrast,
      child: Scaffold(
        backgroundColor: LulunaColors.surface,
        appBar: AppBar(
          title: const LulunaLogo(size: 36),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Erişilebilirlik',
              onPressed: () => showEducationAccessibilitySheet(context),
              icon: const Icon(Icons.accessibility_new),
            ),
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
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                name == null || name.isEmpty ? 'Merhaba' : 'Merhaba, $name',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: LulunaColors.primary,
                ),
              ),
              if (!reduce) ...[
                const SizedBox(height: 8),
                Text(
                  'Bugün ne çalışmak istersin?',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: LulunaColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: VoiceGuidanceHint(
                    enabled: accessibility.voiceInstructions,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              for (final m in _modules) ...[
                EducationBigTile(
                  title: m.title,
                  subtitle: reduce ? null : m.subtitle,
                  leading: EducationModuleIcon(icon: m.icon),
                  trailing: profileAsync.when(
                    data: (p) => SkillTierChip(
                      tier: p?.tierFor(m.skill) ?? SkillTier.easy,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  onTap: () => context.push(m.route),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCardData {
  const _ModuleCardData({
    required this.title,
    required this.subtitle,
    required this.skill,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final SkillArea skill;
  final IconData icon;
  final String route;
}
