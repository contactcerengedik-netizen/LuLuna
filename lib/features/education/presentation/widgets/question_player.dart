import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/education_ui.dart';
import '../../../../app/widgets/luluna_ui.dart';
import '../../../../data/models/education_question.dart';
import '../../../../data/models/sequence_question.dart';
import 'education_question_visual.dart';

/// Çoktan seçmeli / tablo sorusu görünümü.
class ChoiceQuestionView extends StatelessWidget {
  const ChoiceQuestionView({
    super.key,
    required this.question,
    required this.onAnswer,
    this.enabled = true,
  });

  final EducationQuestion question;
  final ValueChanged<String> onAnswer;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final type = question.metadata['type'] as String? ?? 'multipleChoice';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question.instruction,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: LulunaColors.primary,
              ),
        ),
        const SizedBox(height: 12),
        EducationQuestionVisual(question: question),
        const SizedBox(height: 12),
        if (type == 'table') ...[
          _SimpleTableCard(question: question),
          const SizedBox(height: 16),
        ],
        LulunaCard(
          child: Text(
            question.questionText,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
          ),
        ),
        const SizedBox(height: 20),
        for (final choice in question.choices) ...[
          EducationBigTile(
            title: choice,
            onTap: enabled ? () => onAnswer(choice) : () {},
            trailing: const Icon(Icons.touch_app_outlined, size: 28),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SimpleTableCard extends StatelessWidget {
  const _SimpleTableCard({required this.question});

  final EducationQuestion question;

  @override
  Widget build(BuildContext context) {
    final headers =
        (question.metadata['headers'] as List?)?.cast<String>() ?? const [];
    final rows = (question.metadata['rows'] as List?) ?? const [];
    return LulunaCard(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 40,
          dataRowMinHeight: 40,
          columns: [
            const DataColumn(label: Text('')),
            for (final h in headers) DataColumn(label: Text(h)),
          ],
          rows: [
            for (final raw in rows)
              () {
                final row = Map<String, dynamic>.from(raw as Map);
                final label = row['label'] as String? ?? '';
                final cells = (row['cells'] as List?) ?? const [];
                return DataRow(
                  cells: [
                    DataCell(Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    )),
                    for (final c in cells)
                      DataCell(Text(c == true ? '✓' : '·')),
                  ],
                );
              }(),
          ],
        ),
      ),
    );
  }
}

/// Sıralama — sürükle-bırak (Reorderable) + dokunarak seçim.
class OrderQuestionView extends StatefulWidget {
  const OrderQuestionView({
    super.key,
    required this.question,
    required this.onAnswer,
    this.enabled = true,
  });

  final EducationQuestion question;
  final ValueChanged<String> onAnswer;
  final bool enabled;

  @override
  State<OrderQuestionView> createState() => _OrderQuestionViewState();
}

class _OrderQuestionViewState extends State<OrderQuestionView> {
  late List<String> _ordered;

  @override
  void initState() {
    super.initState();
    _ordered = _loadItems();
  }

  @override
  void didUpdateWidget(covariant OrderQuestionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _ordered = _loadItems();
    }
  }

  List<String> _loadItems() {
    return List<String>.from(
      (widget.question.metadata['items'] as List?)?.map((e) => '$e') ??
          widget.question.choices,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.question.instruction,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: LulunaColors.primary,
              ),
        ),
        const SizedBox(height: 8),
        EducationQuestionVisual(question: widget.question),
        const SizedBox(height: 8),
        Text(
          widget.question.questionText,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Sürükleyerek sırala',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _ordered.length,
          onReorderItem: (oldIndex, newIndex) {
            if (!widget.enabled) return;
            setState(() {
              final item = _ordered.removeAt(oldIndex);
              _ordered.insert(newIndex, item);
            });
          },
          itemBuilder: (context, index) {
            final item = _ordered[index];
            final iconsRaw = widget.question.metadata['cardIcons'];
            IconData? icon;
            if (iconsRaw is Map && iconsRaw[item] != null) {
              icon = _iconFor('${iconsRaw[item]}');
            }
            return Card(
              key: ValueKey('$index-$item'),
              color: LulunaColors.surfaceContainerLowest,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: LulunaColors.outlineVariant),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: LulunaColors.secondaryContainer,
                  child: icon != null
                      ? Icon(icon, size: 28, color: LulunaColors.primary)
                      : Text(
                          '${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
                title: Text(
                  item,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                trailing: widget.enabled
                    ? const Icon(Icons.drag_handle, size: 28)
                    : null,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        LulunaPrimaryButton(
          label: 'Kontrol et',
          onPressed: widget.enabled
              ? () => widget.onAnswer(SequenceQuestion.encode(_ordered))
              : null,
        ),
      ],
    );
  }

  IconData _iconFor(String name) => switch (name) {
        'person' => Icons.person,
        'sports_soccer' => Icons.sports_soccer,
        'beach_access' => Icons.beach_access,
        'directions_bike' => Icons.directions_bike,
        'park' => Icons.park,
        'menu_book' => Icons.menu_book,
        'home' => Icons.home,
        'edit' => Icons.edit,
        'school' => Icons.school,
        'local_florist' => Icons.local_florist,
        'yard' => Icons.yard,
        'bakery_dining' => Icons.bakery_dining,
        'storefront' => Icons.storefront,
        'soup_kitchen' => Icons.soup_kitchen,
        'kitchen' => Icons.kitchen,
        'pets' => Icons.pets,
        'local_library' => Icons.local_library,
        'castle' => Icons.castle,
        'bedtime' => Icons.bedtime,
        'cleaning_services' => Icons.cleaning_services,
        'checkroom' => Icons.checkroom,
        'backpack' => Icons.backpack,
        'restaurant' => Icons.restaurant,
        'soap' => Icons.soap,
        'favorite' => Icons.favorite,
        'mood' => Icons.mood,
        'wb_sunny' => Icons.wb_sunny,
        'circle' => Icons.circle,
        _ => Icons.touch_app,
      };
}

class QuestionPlayer extends StatelessWidget {
  const QuestionPlayer({
    super.key,
    required this.question,
    required this.onAnswer,
    this.enabled = true,
  });

  final EducationQuestion question;
  final ValueChanged<String> onAnswer;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final type = question.metadata['type'] as String? ?? 'multipleChoice';
    if (type == 'order' || type == 'sequence') {
      return OrderQuestionView(
        question: question,
        onAnswer: onAnswer,
        enabled: enabled,
      );
    }
    return ChoiceQuestionView(
      question: question,
      onAnswer: onAnswer,
      enabled: enabled,
    );
  }
}
