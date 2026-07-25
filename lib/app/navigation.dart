import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
}) {
  return AppBar(
    title: Text(title),
    leading: IconButton(
      tooltip: 'Geri',
      icon: const Icon(Icons.arrow_back),
      onPressed: onBack ??
          () => lulunaGoBack(context, fallbackLocation: fallbackLocation),
    ),
    actions: actions,
  );
}
