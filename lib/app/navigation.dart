import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme.dart';

/// Ortak geri davranışı: stack varsa pop, yoksa güvenli yedek rotaya git.
void lulunaGoBack(
  BuildContext context, {
  String fallbackLocation = '/home',
}) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallbackLocation);
  }
}

/// Geri ok'u her zaman gösteren AppBar (GoRouter stack boş olsa bile).
PreferredSizeWidget lulunaAppBar(
  BuildContext context, {
  required String title,
  List<Widget>? actions,
  String fallbackLocation = '/home',
  VoidCallback? onBack,
  Color? titleColor,
}) {
  return AppBar(
    title: Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: titleColor ?? LulunaColors.primary,
            fontWeight: FontWeight.w600,
          ),
    ),
    leading: IconButton(
      tooltip: 'Geri',
      icon: const Icon(Icons.arrow_back, color: LulunaColors.primary),
      onPressed: onBack ??
          () => lulunaGoBack(context, fallbackLocation: fallbackLocation),
    ),
    actions: actions,
  );
}
