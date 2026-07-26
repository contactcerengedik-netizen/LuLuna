import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation.dart';
import '../../app/theme.dart';
import '../../app/widgets/luluna_ui.dart';
import '../../data/models/child_profile.dart';
import '../../data/models/user_role.dart';
import '../../data/providers.dart';
import 'parent_voice_recorder_card.dart';

class ChildProfileScreen extends ConsumerStatefulWidget {
  const ChildProfileScreen({super.key});

  @override
  ConsumerState<ChildProfileScreen> createState() =>
      _ChildProfileScreenState();
}

class _ChildProfileScreenState extends ConsumerState<ChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late List<String> _triggers;
  late List<String> _calmingItems;
  late VoiceTone _voiceTone;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(appStateProvider).profile;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _triggers = [...?existing?.triggers];
    _calmingItems = [...?existing?.calmingItems];
    _voiceTone = existing?.voiceTone ?? VoiceTone.compassionate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = ChildProfile(
      name: _nameController.text.trim(),
      triggers: _triggers,
      calmingItems: _calmingItems,
      voiceTone: _voiceTone,
    );
    await ref.read(appStateProvider.notifier).saveProfile(profile);
    if (!mounted) return;

    // Ayarlardan gelindiyse stack'e geri dön; onboarding ise ana ekran.
    if (context.canPop()) {
      lulunaGoBack(context);
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: lulunaAppBar(
        context,
        title: 'Çocuk Profili',
        fallbackLocation: '/onboarding/role',
        onBack: () async {
          final hasProfile = ref.read(appStateProvider).profile != null;
          // Sadece onboarding'de (profil yokken) rolü sıfırla.
          if (!hasProfile) {
            await ref.read(appStateProvider.notifier).clearRole();
          }
          if (context.mounted) {
            lulunaGoBack(
              context,
              fallbackLocation: hasProfile ? '/home' : '/onboarding/role',
            );
          }
        },
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                'Bu bilgiler yapay zekanın system prompt\'una otomatik '
                'eklenir ve yönlendirmeler buna göre kişiselleşir.',
                textAlign: TextAlign.center,
                style: textTheme.labelMedium?.copyWith(
                  color: LulunaColors.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Çocuğun adı',
                  prefixIcon: Icon(Icons.child_care),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Lütfen bir isim girin'
                    : null,
              ),
              const SizedBox(height: 24),
              LulunaCard(
                child: _ChipListEditor(
                  title: 'Fobiler ve tetikleyiciler',
                  hint: 'Yeni ekle...',
                  items: _triggers,
                  onChanged: (items) => setState(() => _triggers = items),
                ),
              ),
              const SizedBox(height: 24),
              LulunaCard(
                child: _ChipListEditor(
                  title: 'Onu sakinleştiren şeyler',
                  hint: 'Yeni ekle...',
                  items: _calmingItems,
                  onChanged: (items) => setState(() => _calmingItems = items),
                ),
              ),
              const SizedBox(height: 24),
              LulunaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asistanın ses tonu',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LulunaSegmentedTabs(
                      labels: [
                        for (final tone in VoiceTone.values) tone.label,
                      ],
                      index: VoiceTone.values.indexOf(_voiceTone),
                      onChanged: (i) =>
                          setState(() => _voiceTone = VoiceTone.values[i]),
                    ),
                  ],
                ),
              ),
              if (ref.watch(appStateProvider).role == UserRole.parent) ...[
                const SizedBox(height: 24),
                const ParentVoiceRecorderCard(),
              ],
              const SizedBox(height: 32),
              LulunaPrimaryButton(
                label: 'Kaydet ve Başla',
                icon: Icons.check,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Metin girip "+" ile chip listesine ekleme yapılan basit editör.
class _ChipListEditor extends StatefulWidget {
  const _ChipListEditor({
    required this.title,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final String title;
  final String hint;
  final List<String> items;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_ChipListEditor> createState() => _ChipListEditorState();
}

class _ChipListEditorState extends State<_ChipListEditor> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    widget.onChanged([...widget.items, value]);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: LulunaColors.surfaceContainerLowest,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add, color: LulunaColors.primary),
              onPressed: _add,
            ),
          ),
          onSubmitted: (_) => _add(),
        ),
        if (widget.items.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in widget.items)
                Chip(
                  label: Text(item),
                  backgroundColor: LulunaColors.secondaryContainer,
                  labelStyle: const TextStyle(
                    color: LulunaColors.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                  deleteIconColor: LulunaColors.onSecondaryContainer,
                  side: BorderSide.none,
                  onDeleted: () => widget.onChanged(
                    [...widget.items]..remove(item),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
