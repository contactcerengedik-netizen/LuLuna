import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/education_ui.dart';
import '../../../../app/widgets/luluna_ui.dart';
import '../../../../data/models/education_question.dart';
import '../../../../data/models/sequence_question.dart';

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
            return ListTile(
              key: ValueKey('$index-$item'),
              tileColor: LulunaColors.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: LulunaColors.outlineVariant),
              ),
              leading: CircleAvatar(
                backgroundColor: LulunaColors.secondaryContainer,
                child: Text('${index + 1}'),
              ),
              title: Text(
                item,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
              trailing: widget.enabled
                  ? const Icon(Icons.drag_handle)
                  : null,
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
