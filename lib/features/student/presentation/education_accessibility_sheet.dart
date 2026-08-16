import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/luluna_ui.dart';
import '../../../data/models/student_profile.dart';
import '../../../data/providers.dart';

Future<void> showEducationAccessibilitySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: LulunaColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const EducationAccessibilitySheet(),
  );
}

/// Öğrenci erişilebilirlik tercihleri — sesli yönerge mimarisine hazır.
class EducationAccessibilitySheet extends ConsumerWidget {
  const EducationAccessibilitySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(educationAccessibilityProvider);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: LulunaColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Erişilebilirlik',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bu ayarlar yalnızca bu cihazda saklanır.',
              style: textTheme.bodyMedium?.copyWith(
                color: LulunaColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sesli yönergeler'),
              subtitle: const Text('Etkinliklerde ses desteğine hazır'),
              value: settings.voiceInstructions,
              onChanged: (v) => ref
                  .read(educationAccessibilityProvider.notifier)
                  .update(settings.copyWith(voiceInstructions: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Yüksek kontrast'),
              value: settings.highContrast,
              onChanged: (v) => ref
                  .read(educationAccessibilityProvider.notifier)
                  .update(settings.copyWith(highContrast: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Az dikkat dağıtma'),
              subtitle: const Text('İkincil metinleri sadeleştirir'),
              value: settings.reducedDistractionMode,
              onChanged: (v) => ref
                  .read(educationAccessibilityProvider.notifier)
                  .update(settings.copyWith(reducedDistractionMode: v)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ses efektleri'),
              value: settings.soundEnabled,
              onChanged: (v) => ref
                  .read(educationAccessibilityProvider.notifier)
                  .update(settings.copyWith(soundEnabled: v)),
            ),
            const SizedBox(height: 8),
            Text('Yazı boyutu', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<TextScale>(
              segments: const [
                ButtonSegment(value: TextScale.small, label: Text('Küçük')),
                ButtonSegment(value: TextScale.medium, label: Text('Orta')),
                ButtonSegment(value: TextScale.large, label: Text('Büyük')),
              ],
              selected: {settings.textSize},
              onSelectionChanged: (set) {
                ref
                    .read(educationAccessibilityProvider.notifier)
                    .update(settings.copyWith(textSize: set.first));
              },
            ),
            const SizedBox(height: 24),
            LulunaPrimaryButton(
              label: 'Tamam',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
