import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../app/widgets/luluna_ui.dart';
import '../../../data/models/categorization_question.dart';
import '../../../data/models/skill_level.dart';
import '../../../data/providers.dart';
import '../../education/domain/activity_models.dart';
import '../../education/presentation/activity_session_controller.dart';
import '../data/categorization_catalog.dart';

class CategorizationHubScreen extends StatelessWidget {
  const CategorizationHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: const Text('Eşleştirme'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/student'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Nesneleri doğru gruba sürükle',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kolay: renk/şekil · Zor: kavram (yenebilir…)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: LulunaColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          for (final tier in SkillTier.values) ...[
            EducationBigTile(
              title: tier.label,
              subtitle: switch (tier) {
                SkillTier.easy => 'Görsel benzerlik',
                SkillTier.medium => 'Büyüklük',
                SkillTier.hard => 'Kavramsal sınıflandırma',
              },
              leading: const EducationModuleIcon(icon: Icons.category_outlined),
              onTap: () =>
                  context.push('/student/categorize/${tier.name}'),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class CategorizationPlayScreen extends ConsumerStatefulWidget {
  const CategorizationPlayScreen({super.key, required this.tier});

  final SkillTier tier;

  @override
  ConsumerState<CategorizationPlayScreen> createState() =>
      _CategorizationPlayScreenState();
}

class _CategorizationPlayScreenState
    extends ConsumerState<CategorizationPlayScreen> {
  late CategorizationQuestion _question;
  final Map<String, String> _placed = {};
  String? _feedback;
  late final DateTime _startedAt;
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _question = CategorizationCatalog.forTier(widget.tier);
  }

  List<CategorizationItem> get _tray => [
        for (final i in _question.items)
          if (!_placed.containsKey(i.id)) i,
      ];

  Future<void> _check() async {
    final ok = _question.isCorrect(_placed);
    setState(() {
      _feedback = ok
          ? 'Doğru! ${_question.score(_placed)}/${_question.items.length}'
          : 'Bazıları yanlış. Skor: '
              '${_question.score(_placed)}/${_question.items.length}';
    });
    if (ok && !_recorded) {
      _recorded = true;
      final profile = ref.read(currentStudentProfileProvider).asData?.value;
      final studentId =
          profile?.id ?? ref.read(authStateProvider)?.userId ?? 'demo-student';
      final now = DateTime.now();
      await ref.read(activityAttemptRepositoryProvider).append(
            ActivityAttempt(
              id: 'cat_${now.millisecondsSinceEpoch}',
              studentId: studentId,
              skill: SkillArea.visualPerception.name,
              category: 'categorization',
              difficulty: widget.tier.name,
              questionId: _question.id,
              givenAnswer: _placed.entries
                  .map((e) => '${e.key}:${e.value}')
                  .join('|'),
              correct: true,
              attemptedAt: now,
              durationMs: now.difference(_startedAt).inMilliseconds,
            ),
          );
    }
  }

  IconData _icon(String name) => switch (name) {
        'apple' => Icons.apple,
        'favorite' => Icons.favorite,
        'cloud' => Icons.cloud_outlined,
        'water' => Icons.water_drop_outlined,
        'circle' => Icons.circle_outlined,
        'wb_sunny' => Icons.wb_sunny_outlined,
        'crop_square' => Icons.crop_square,
        'menu_book' => Icons.menu_book_outlined,
        'pets' => Icons.pets,
        'directions_bus' => Icons.directions_bus_outlined,
        'bug_report' => Icons.bug_report_outlined,
        'radio_button_checked' => Icons.radio_button_checked,
        'bakery_dining' => Icons.bakery_dining_outlined,
        'landscape' => Icons.landscape_outlined,
        'edit' => Icons.edit_outlined,
        'auto_fix_high' => Icons.auto_fix_high,
        'soup_kitchen' => Icons.soup_kitchen_outlined,
        'dinner_dining' => Icons.dinner_dining_outlined,
        _ => Icons.category_outlined,
      };

  Widget _itemChip(CategorizationItem item, {bool dragging = false}) {
    final tint = item.tintArgb != null ? Color(item.tintArgb!) : null;
    return Material(
      elevation: dragging ? 4 : 0,
      color: LulunaColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tint ?? LulunaColors.outlineVariant,
            width: tint != null ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon(item.iconName), color: tint ?? LulunaColors.primary),
            const SizedBox(width: 8),
            Text(
              item.label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: Text(_question.instruction),
        actions: [
          IconButton(
            tooltip: 'Sıfırla',
            onPressed: () => setState(() {
              _placed.clear();
              _feedback = null;
              _recorded = false;
              _question = CategorizationCatalog.forTier(
                widget.tier,
                index: DateTime.now().millisecond,
              );
            }),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Öğeler',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in _tray)
                    Draggable<String>(
                      data: item.id,
                      feedback: _itemChip(item, dragging: true),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _itemChip(item),
                      ),
                      child: _itemChip(item),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  children: [
                    for (final cat in _question.categories) ...[
                      Expanded(
                        child: _CategoryBucket(
                          title: cat,
                          children: [
                            for (final item in _question.items)
                              if (_placed[item.id] == cat)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Draggable<String>(
                                    data: item.id,
                                    feedback:
                                        _itemChip(item, dragging: true),
                                    childWhenDragging: const SizedBox.shrink(),
                                    child: _itemChip(item),
                                    onDragCompleted: () {},
                                  ),
                                ),
                          ],
                          onAccept: (id) {
                            setState(() {
                              _placed[id] = cat;
                              _feedback = null;
                              _recorded = false;
                            });
                          },
                        ),
                      ),
                      if (cat != _question.categories.last)
                        const SizedBox(width: 12),
                    ],
                  ],
                ),
              ),
              if (_feedback != null) ...[
                const SizedBox(height: 8),
                LulunaCard(
                  color: _question.isCorrect(_placed)
                      ? LulunaColors.secondaryContainer
                      : LulunaColors.surfaceContainer,
                  child: Text(
                    _feedback!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              LulunaPrimaryButton(
                label: 'Kontrol et',
                onPressed: _placed.length == _question.items.length
                    ? _check
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBucket extends StatelessWidget {
  const _CategoryBucket({
    required this.title,
    required this.children,
    required this.onAccept,
  });

  final String title;
  final List<Widget> children;
  final ValueChanged<String> onAccept;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => onAccept(d.data),
      builder: (context, candidate, rejected) {
        final highlight = candidate.isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: highlight
                ? LulunaColors.secondaryContainer
                : LulunaColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlight
                  ? LulunaColors.primary
                  : LulunaColors.outlineVariant,
              width: highlight ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: LulunaColors.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: children.isEmpty
                        ? [
                            Text(
                              'Buraya bırak',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: LulunaColors.onSurfaceVariant,
                                  ),
                            ),
                          ]
                        : children,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
