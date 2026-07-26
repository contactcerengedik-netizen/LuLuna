import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Luluna',
                      textAlign: TextAlign.center,
                      style: textTheme.displaySmall?.copyWith(
                        color: LulunaColors.primaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Yapay zeka destekli giyilebilir yol arkadaşı',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: LulunaColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Kim olarak devam etmek istiyorsunuz?',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'İlk girişte rolünüzü seçmeniz gerekir. '
                      'Bu seçim asistan deneyimini ve paneli kişiselleştirir.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: LulunaColors.onSurfaceVariant
                            .withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _RoleCard(
                      role: UserRole.parent,
                      icon: Icons.family_restroom,
                      description:
                          'Çocuğunuzun profilini oluşturun, canlı akışı '
                          'izleyin ve kriz anlarında müdahale edin.',
                    ),
                    const SizedBox(height: 16),
                    _RoleCard(
                      role: UserRole.therapist,
                      icon: Icons.psychology,
                      description:
                          'Gelişim raporlarını inceleyin ve asistanın '
                          'davranış kurallarını güncelleyin.',
                    ),
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Yardıma mı ihtiyacınız var? ',
                          style: textTheme.labelMedium?.copyWith(
                            color: LulunaColors.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Destek Merkezi yakında eklenecek.',
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: LulunaColors.primaryContainer,
                            textStyle: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Destek Merkezi'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoleCard extends ConsumerWidget {
  const _RoleCard({
    required this.role,
    required this.icon,
    required this.description,
  });

  final UserRole role;
  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: LulunaColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: LulunaColors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await ref.read(appStateProvider.notifier).selectRole(role);
          if (!context.mounted) return;
          if (role == UserRole.therapist) {
            context.go('/pairing');
          } else {
            context.go('/onboarding/profile');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              LulunaIconBadge(
                icon: icon,
                size: 48,
                backgroundColor: LulunaColors.secondaryContainer,
                foregroundColor: LulunaColors.onSecondaryContainer,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: LulunaColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: LulunaColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
