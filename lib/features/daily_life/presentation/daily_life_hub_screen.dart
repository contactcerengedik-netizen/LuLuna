import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../data/routine_sequence_catalog.dart';
import '../data/scenario_catalog.dart';

class DailyLifeHubScreen extends StatelessWidget {
  const DailyLifeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final routines = RoutineSequenceCatalog.all;
    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: const Text('Günlük Yaşam'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/student'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Rutin Sıralama',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Adımları sürükleyerek doğru sıraya koy',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: LulunaColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          for (final r in routines) ...[
            EducationBigTile(
              title: r.title,
              subtitle: '${r.steps.length} adım · sürükle-bırak',
              leading: const EducationModuleIcon(icon: Icons.reorder),
              onTap: () => context.push(
                '/student/daily-life/routine?id=${r.id}',
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          EducationBigTile(
            title: 'AAC panosu',
            subtitle: 'Dokun → ses; sık kullanılan önde',
            leading: const EducationModuleIcon(icon: Icons.grid_view),
            onTap: () => context.push('/student/daily-life/aac'),
          ),
          const SizedBox(height: 24),
          Text(
            'Senaryolar',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          for (final s in ScenarioCatalog.all) ...[
            EducationBigTile(
              title: s.title,
              subtitle: s.description,
              leading: EducationModuleIcon(icon: _iconFor(s.id)),
              onTap: () => context.push('/student/daily-life/${s.id}'),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(String id) => switch (id) {
        'restaurant' => Icons.restaurant_outlined,
        'market' => Icons.storefront_outlined,
        'grocery' => Icons.local_convenience_store_outlined,
        'bakery' => Icons.cake_outlined,
        _ => Icons.handshake_outlined,
      };
}
