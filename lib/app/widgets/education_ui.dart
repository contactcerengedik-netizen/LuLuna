import 'package:flutter/material.dart';

import '../theme.dart';
import '../../data/models/skill_level.dart';

/// Büyük dokunma alanı — öğrenci / öğretmen listeleri (min ~72dp yükseklik).
class EducationBigTile extends StatelessWidget {
  const EducationBigTile({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.trailing,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: semanticLabel ?? title,
      child: Material(
        color: LulunaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 80),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: LulunaColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing ??
                      const Icon(
                        Icons.chevron_right,
                        size: 28,
                        color: LulunaColors.onSurfaceVariant,
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Beceri seviyesi etiketi (Kolay / Orta / Zor).
class SkillTierChip extends StatelessWidget {
  const SkillTierChip({super.key, required this.tier});

  final SkillTier tier;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tier) {
      SkillTier.easy => (
          LulunaColors.secondaryContainer,
          LulunaColors.onSecondaryContainer,
        ),
      SkillTier.medium => (
          LulunaColors.surfaceContainerHigh,
          LulunaColors.primary,
        ),
      SkillTier.hard => (
          LulunaColors.primaryContainer,
          LulunaColors.onPrimary,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        tier.label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// Modül ikon kutusu — sade, tek renk.
class EducationModuleIcon extends StatelessWidget {
  const EducationModuleIcon({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: LulunaColors.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, size: 32, color: LulunaColors.onSecondaryContainer),
    );
  }
}

/// Boş / henüz hazır değil durumları.
class EducationStatusPanel extends StatelessWidget {
  const EducationStatusPanel({
    super.key,
    required this.title,
    required this.body,
    this.icon = Icons.info_outline,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: LulunaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LulunaColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 40, color: LulunaColors.primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: LulunaColors.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

/// Sesli yönerge mimarisi için görünür hazırlık göstergesi (PHASE 2).
class VoiceGuidanceHint extends StatelessWidget {
  const VoiceGuidanceHint({super.key, required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: enabled
          ? 'Sesli yönergeler açık'
          : 'Sesli yönergeler kapalı',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enabled ? Icons.volume_up_outlined : Icons.volume_off_outlined,
            size: 20,
            color: LulunaColors.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            enabled ? 'Sesli yönerge açık' : 'Sesli yönerge kapalı',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: LulunaColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// Erişilebilirlik tercihlerini MediaQuery text scale ile uygular.
class EducationAccessibilityScope extends StatelessWidget {
  const EducationAccessibilityScope({
    super.key,
    required this.textScale,
    required this.highContrast,
    required this.child,
  });

  final double textScale;
  final bool highContrast;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final scaled = mq.copyWith(
      textScaler: TextScaler.linear(
        (mq.textScaler.scale(1) * textScale).clamp(0.9, 1.6),
      ),
      boldText: highContrast || mq.boldText,
    );
    Widget result = MediaQuery(data: scaled, child: child);
    if (highContrast) {
      result = Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: LulunaColors.onSurface,
                displayColor: LulunaColors.primary,
              ),
        ),
        child: result,
      );
    }
    return result;
  }
}
