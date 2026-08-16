import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/providers.dart';

/// Eski rol seçim ekranı — artık giriş yolu auth öncesinde seçilir.
/// Buraya düşülürse oturumu kapatıp auth'a yönlendirir (güvenlik).
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authStateProvider.notifier).signOut();
      await ref.read(appStateProvider.notifier).clearRole();
      ref.read(loginPathProvider.notifier).clear();
      if (mounted) context.go('/auth');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: LulunaColors.surface,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
