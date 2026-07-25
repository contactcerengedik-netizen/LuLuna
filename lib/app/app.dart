import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class LulunaApp extends ConsumerWidget {
  const LulunaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Luluna',
      debugShowCheckedModeBanner: false,
      theme: LulunaTheme.light(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
