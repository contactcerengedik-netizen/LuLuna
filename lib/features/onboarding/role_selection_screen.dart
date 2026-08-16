import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../app/widgets/education_ui.dart';
import '../../app/widgets/luluna_ui.dart';
import '../../data/models/user_role.dart';
import '../../data/providers.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Geri',
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await ref.read(authStateProvider.notifier).signOut();
            if (context.mounted) context.go('/auth');
          },
        ),
        title: const LulunaLogo(size: 32),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              'Kim olarak devam etmek istiyorsunuz?',
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rolünüz ana ekranı belirler. Her beceri için ayrı seviye tutulur.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                color: LulunaColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            EducationBigTile(
              title: UserRole.student.label,
              subtitle: 'Matematik, Türkçe, puzzle ve diğer çalışmalar.',
              leading: const EducationModuleIcon(icon: Icons.school_outlined),
              onTap: () => _select(context, ref, UserRole.student),
            ),
            const SizedBox(height: 12),
            EducationBigTile(
              title: UserRole.teacher.label,
              subtitle: 'Öğrenci takibi, ödev, rapor ve AI içerik.',
              leading: const EducationModuleIcon(icon: Icons.badge_outlined),
              onTap: () => _select(context, ref, UserRole.teacher),
            ),
            const SizedBox(height: 12),
            EducationBigTile(
              title: UserRole.parent.label,
              subtitle: 'Çocuk profili ile birlikte öğrenci akışına girer (MVP).',
              leading: const EducationModuleIcon(icon: Icons.family_restroom),
              onTap: () => _select(context, ref, UserRole.parent),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _select(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
  ) async {
    await ref.read(appStateProvider.notifier).selectRole(role);
    if (!context.mounted) return;
    switch (role) {
      case UserRole.student:
        context.go('/student');
      case UserRole.teacher:
      case UserRole.admin:
        context.go('/teacher');
      case UserRole.parent:
        context.go('/onboarding/profile');
    }
  }
}
