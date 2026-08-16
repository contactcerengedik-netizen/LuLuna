import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../domain/concept_models.dart';
import 'concept_providers.dart';

/// Öğrenci: yayınlanmış kavram içeriklerine modül rotalarıyla erişim.
class StudentConceptActivitiesScreen extends ConsumerWidget {
  const StudentConceptActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final published = ref
        .watch(conceptAssignmentsProvider)
        .where((a) => a.status == ConceptAssignmentStatus.published)
        .toList();

    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: const Text('Kavram etkinlikleri'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/student'),
        ),
      ),
      body: published.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: EducationStatusPanel(
                title: 'Henüz yayın yok',
                body:
                    'Öğretmen Kavram Motoru’ndan içerik yayınlayınca '
                    'burada modül linkleri görünür.',
                icon: Icons.hub_outlined,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final a in published) ...[
                  Text(
                    a.conceptName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  for (final o in a.outputs.where(
                    (e) => e.status == ConceptModuleOutputStatus.published ||
                        e.status == ConceptModuleOutputStatus.ready,
                  )) ...[
                    EducationBigTile(
                      title: o.previewTitle ?? o.module.label,
                      subtitle: o.previewBody,
                      leading: EducationModuleIcon(
                        icon: Icons.extension_outlined,
                      ),
                      onTap: () {
                        final route =
                            o.studentRoute ?? o.module.studentRoute;
                        context.push(route);
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 16),
                ],
              ],
            ),
    );
  }
}
