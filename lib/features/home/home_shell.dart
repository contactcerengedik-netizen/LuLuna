import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_role.dart';
import '../../data/providers.dart';
import '../assistant/live_assistant_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Terapist varsayılan sekme: Raporlar (liste indeksi 0).
    final role = ref.read(appStateProvider).role;
    if (role == UserRole.therapist) {
      _index = 0;
    }
    unawaited(
      ref
          .read(appStateProvider.notifier)
          .refreshTherapistRules()
          .catchError((_) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(logPersistenceBridgeProvider);
    final role = ref.watch(appStateProvider).role;
    final isTherapist = role == UserRole.therapist;

    final pages = isTherapist
        ? const <Widget>[ReportsScreen(), SettingsScreen()]
        : const <Widget>[
            DashboardScreen(),
            LiveAssistantScreen(),
            ReportsScreen(),
            SettingsScreen(),
          ];

    final destinations = isTherapist
        ? const [
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Raporlar',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Ayarlar',
            ),
          ]
        : const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Panel',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum),
              label: 'Asistan',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Raporlar',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Ayarlar',
            ),
          ];

    final safeIndex = _index.clamp(0, pages.length - 1);

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: destinations,
      ),
    );
  }
}
