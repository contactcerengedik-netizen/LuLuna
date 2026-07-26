import 'package:flutter/material.dart';

import '../theme.dart';

/// Luluna ay/marka logosu (Stitch crescent + L).
class LulunaLogo extends StatelessWidget {
  const LulunaLogo({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: LulunaColors.primary,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: LulunaColors.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        Icons.nightlight_round,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}

/// Beyaz kart + 1px outline (Stitch Surface Level 1).
class LulunaCard extends StatelessWidget {
  const LulunaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? LulunaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LulunaColors.outlineVariant),
      ),
      child: child,
    );
  }
}

/// Giriş/Kayıt segmented control.
class LulunaSegmentedTabs extends StatelessWidget {
  const LulunaSegmentedTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: LulunaColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Material(
                color: i == index
                    ? LulunaColors.surfaceContainerLowest
                    : Colors.transparent,
                elevation: i == index ? 1 : 0,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onChanged(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: i == index
                                ? LulunaColors.primary
                                : LulunaColors.onSurfaceVariant,
                            fontWeight:
                                i == index ? FontWeight.w600 : FontWeight.w500,
                          ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LulunaIconBadge extends StatelessWidget {
  const LulunaIconBadge({
    super.key,
    required this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 40,
  });

  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? LulunaColors.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: foregroundColor ?? LulunaColors.onSecondaryContainer,
      ),
    );
  }
}

/// Ayarlar bölüm başlığı (uppercase label).
class LulunaSectionLabel extends StatelessWidget {
  const LulunaSectionLabel(
    this.text, {
    super.key,
    this.color,
  });

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.4,
              color: color ?? LulunaColors.onSurfaceVariant,
            ),
      ),
    );
  }
}

/// Gruplanmış ayarlar listesi.
class LulunaSettingsGroup extends StatelessWidget {
  const LulunaSettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LulunaColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: LulunaColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 68,
                color: LulunaColors.outlineVariant.withValues(alpha: 0.35),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class LulunaSettingsTile extends StatelessWidget {
  const LulunaSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconBackground,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconBackground;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: LulunaIconBadge(
        icon: icon,
        backgroundColor: iconBackground,
        foregroundColor: iconColor,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: titleColor ?? LulunaColors.onSurface,
            ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: Theme.of(context).textTheme.labelSmall,
            ),
      trailing: trailing,
    );
  }
}

class LulunaPrimaryButton extends StatelessWidget {
  const LulunaPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : (icon == null
            ? Text(label)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 8),
                  Text(label),
                ],
              ));

    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: child,
    );
  }
}
