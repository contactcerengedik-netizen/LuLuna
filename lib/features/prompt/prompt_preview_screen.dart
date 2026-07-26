import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/navigation.dart';
import '../../app/theme.dart';
import '../../app/widgets/luluna_ui.dart';
import '../../data/providers.dart';

/// Profil + terapist kurallarından üretilen system prompt'un önizlemesi.
class PromptPreviewScreen extends ConsumerWidget {
  const PromptPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompt = ref.watch(systemPromptProvider);

    return Scaffold(
      appBar: lulunaAppBar(
        context,
        title: 'System Prompt',
        actions: [
          if (prompt != null)
            IconButton(
              tooltip: 'Kopyala',
              icon: const Icon(Icons.copy, color: LulunaColors.primary),
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
              padding: const EdgeInsets.all(16),
              children: [
                LulunaCard(
                  color: LulunaColors.surfaceContainer,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 20,
                        color: LulunaColors.secondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Bu metin Gemini çağrısında system prompt olarak '
                          'kullanılacak. Profil veya terapist kuralları '
                          'değişince otomatik güncellenir.',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: LulunaColors.onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          LulunaColors.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: SelectableText(
                    prompt,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          height: 1.45,
                          color: LulunaColors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: LulunaColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SYNC STATUS: REAL-TIME',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: LulunaColors.outline,
                            letterSpacing: 1.2,
                          ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
