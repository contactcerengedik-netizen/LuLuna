import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/navigation.dart';
import '../../data/providers.dart';

/// Profil + terapist kurallarından üretilen system prompt'un önizlemesi.
class PromptPreviewScreen extends ConsumerWidget {
  const PromptPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompt = ref.watch(systemPromptProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: lulunaAppBar(
        context,
        title: 'System Prompt',
        actions: [
          if (prompt != null)
            IconButton(
              tooltip: 'Kopyala',
              icon: const Icon(Icons.copy),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: prompt));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Prompt panoya kopyalandı')),
                  );
                }
              },
            ),
        ],
      ),
      body: prompt == null
          ? const Center(
              child: Text('Önce çocuk profilini tamamlayın.'),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Bu metin Gemini çağrısında system prompt olarak kullanılacak. '
                  'Profil veya terapist kuralları değişince otomatik güncellenir.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: SelectableText(
                    prompt,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          height: 1.45,
                        ),
                  ),
                ),
              ],
            ),
    );
  }
}
