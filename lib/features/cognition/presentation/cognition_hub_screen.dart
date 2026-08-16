import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../app/widgets/luluna_ui.dart';
import '../../../data/models/data_question.dart';
import '../../../data/models/pattern_question.dart';
import '../../../data/models/sequence_question.dart';
import '../../../data/models/skill_level.dart';
import '../../../data/providers.dart';
import '../../education/domain/activity_models.dart';
import '../../education/presentation/activity_session_controller.dart';
import '../data/data_question_factory.dart';
import '../data/pattern_catalog.dart';

enum CognitionActivity {
  pattern('Örüntü tamamla'),
  oddOne('Farklı olanı bul'),
  eventOrder('Olay sıralama'),
  dataRead('Grafik / çetele / tablo');

  const CognitionActivity(this.label);
  final String label;
}

class CognitionHubScreen extends StatelessWidget {
  const CognitionHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: const Text('Mantık / Veri'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/student'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Bir etkinlik seç',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          for (final a in CognitionActivity.values) ...[
            EducationBigTile(
              title: a.label,
              leading: EducationModuleIcon(
                icon: switch (a) {
                  CognitionActivity.pattern => Icons.grid_view,
                  CognitionActivity.oddOne => Icons.filter_none,
                  CognitionActivity.eventOrder => Icons.view_timeline_outlined,
                  CognitionActivity.dataRead => Icons.bar_chart,
                },
              ),
              onTap: () => context.push('/student/cognition/${a.name}'),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class CognitionPlayScreen extends ConsumerStatefulWidget {
  const CognitionPlayScreen({super.key, required this.activity});

  final CognitionActivity activity;

  @override
  ConsumerState<CognitionPlayScreen> createState() =>
      _CognitionPlayScreenState();
}

class _CognitionPlayScreenState extends ConsumerState<CognitionPlayScreen> {
  late SkillTier _tier;
  PatternQuestion? _pattern;
  SequenceQuestion? _sequence;
  List<String>? _ordered;
  DataQuestion? _data;
  String? _feedback;
  late final DateTime _startedAt;
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _tier = SkillTier.easy;
    _load();
  }

  void _load() {
    _feedback = null;
    _recorded = false;
    switch (widget.activity) {
      case CognitionActivity.pattern:
        _pattern = PatternCatalog.patternFor(_tier);
        _sequence = null;
        _data = null;
      case CognitionActivity.oddOne:
        _pattern = PatternCatalog.oddOneOut();
        _sequence = null;
        _data = null;
      case CognitionActivity.eventOrder:
        _pattern = null;
        _sequence = PatternCatalog.eventOrder();
        _ordered = List<String>.from(_sequence!.items);
        _data = null;
      case CognitionActivity.dataRead:
        _pattern = null;
        _sequence = null;
        final profile = ref.read(currentStudentProfileProvider).asData?.value;
        final studentId =
            profile?.id ?? ref.read(authStateProvider)?.userId ?? '';
        final attempts = ref
            .read(activityAttemptRepositoryProvider)
            .forStudent(studentId);
        _data = DataQuestionFactory.build(
          tier: _tier,
          attempts: attempts,
        );
    }
  }

  Future<void> _record({
    required String questionId,
    required String answer,
    required bool correct,
    required String category,
  }) async {
    if (_recorded) return;
    _recorded = true;
    final profile = ref.read(currentStudentProfileProvider).asData?.value;
    final studentId =
        profile?.id ?? ref.read(authStateProvider)?.userId ?? 'demo-student';
    final now = DateTime.now();
    await ref.read(activityAttemptRepositoryProvider).append(
          ActivityAttempt(
            id: 'cog_${now.millisecondsSinceEpoch}',
            studentId: studentId,
            skill: SkillArea.visualPerception.name,
            category: category,
            difficulty: _tier.name,
            questionId: questionId,
            givenAnswer: answer,
            correct: correct,
            attemptedAt: now,
            durationMs: now.difference(_startedAt).inMilliseconds,
          ),
        );
  }

  void _answerPattern(String choice) {
    final q = _pattern!;
    final ok = q.isCorrect(choice);
    setState(() {
      _feedback = ok ? 'Doğru!' : 'Tekrar dene. Doğru: ${q.correctAnswer}';
    });
    if (ok) {
      _record(
        questionId: q.id,
        answer: choice,
        correct: true,
        category: widget.activity == CognitionActivity.oddOne
            ? 'oddOne'
            : 'patternComplete',
      );
    }
  }

  void _checkSequence() {
    final seq = _sequence!;
    final ordered = _ordered!;
    final ok = seq.isCorrectSequence(ordered);
    setState(() {
      _feedback = ok
          ? 'Doğru sıra!'
          : 'Sıra yanlış. Doğrusu: ${seq.correctItems.join(' → ')}';
    });
    if (ok) {
      _record(
        questionId: 'event-${seq.correctItems.join('-')}',
        answer: SequenceQuestion.encode(ordered),
        correct: true,
        category: 'eventOrder',
      );
    }
  }

  void _answerData(String choice) {
    final q = _data!;
    final ok = q.isCorrect(choice);
    setState(() {
      _feedback = ok ? 'Doğru!' : 'Tekrar dene. Doğru: ${q.correctAnswer}';
    });
    if (ok) {
      _record(
        questionId: q.id,
        answer: choice,
        correct: true,
        category: 'dataRead',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: Text(widget.activity.label),
        actions: [
          if (widget.activity == CognitionActivity.pattern ||
              widget.activity == CognitionActivity.dataRead)
            PopupMenuButton<SkillTier>(
              initialValue: _tier,
              onSelected: (t) => setState(() {
                _tier = t;
                _load();
              }),
              itemBuilder: (_) => [
                for (final t in SkillTier.values)
                  PopupMenuItem(value: t, child: Text(t.label)),
              ],
              icon: const Icon(Icons.tune),
            ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: () => setState(_load),
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
              Expanded(child: _body(context)),
              if (_feedback != null) ...[
                const SizedBox(height: 8),
                LulunaCard(
                  color: _feedback!.startsWith('Doğru')
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    return switch (widget.activity) {
      CognitionActivity.pattern || CognitionActivity.oddOne =>
        _PatternView(question: _pattern!, onAnswer: _answerPattern),
      CognitionActivity.eventOrder => _EventOrderView(
          ordered: _ordered!,
          onReorder: (list) => setState(() => _ordered = list),
          onCheck: _checkSequence,
        ),
      CognitionActivity.dataRead => _DataView(
          question: _data!,
          onAnswer: _answerData,
        ),
    };
  }
}

class _PatternView extends StatelessWidget {
  const _PatternView({required this.question, required this.onAnswer});

  final PatternQuestion question;
  final ValueChanged<String> onAnswer;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(
          question.instruction,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: LulunaColors.primary,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final token in question.displayPattern)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: token == '?'
                      ? LulunaColors.secondaryContainer
                      : LulunaColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: LulunaColors.outlineVariant),
                ),
                child: Text(
                  token,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        for (final c in question.choices) ...[
          EducationBigTile(
            title: c,
            onTap: () => onAnswer(c),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _EventOrderView extends StatelessWidget {
  const _EventOrderView({
    required this.ordered,
    required this.onReorder,
    required this.onCheck,
  });

  final List<String> ordered;
  final ValueChanged<List<String>> onReorder;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Olayları doğru sıraya koy',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: LulunaColors.primary,
              ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ReorderableListView.builder(
            itemCount: ordered.length,
            onReorderItem: (oldIndex, newIndex) {
              final next = List<String>.from(ordered);
              final item = next.removeAt(oldIndex);
              next.insert(newIndex, item);
              onReorder(next);
            },
            itemBuilder: (context, index) {
              final item = ordered[index];
              return ListTile(
                key: ValueKey('$index-$item'),
                tileColor: LulunaColors.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: LulunaColors.outlineVariant),
                ),
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(
                  item,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                trailing: const Icon(Icons.drag_handle),
              );
            },
          ),
        ),
        LulunaPrimaryButton(label: 'Kontrol et', onPressed: onCheck),
      ],
    );
  }
}

class _DataView extends StatelessWidget {
  const _DataView({required this.question, required this.onAnswer});

  final DataQuestion question;
  final ValueChanged<String> onAnswer;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(
          question.instruction,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: LulunaColors.primary,
              ),
        ),
        if (question.fromAttempts) ...[
          const SizedBox(height: 4),
          Text(
            'Senin etkinlik özetinden',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LulunaColors.onSurfaceVariant,
                ),
          ),
        ],
        const SizedBox(height: 12),
        LulunaCard(child: _DataViz(question: question)),
        const SizedBox(height: 16),
        Text(
          question.questionText,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        for (final c in question.choices) ...[
          EducationBigTile(title: c, onTap: () => onAnswer(c)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _DataViz extends StatelessWidget {
  const _DataViz({required this.question});

  final DataQuestion question;

  @override
  Widget build(BuildContext context) {
    return switch (question.displayAs) {
      DataDisplayAs.tally => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final e in question.dataset.entries) ...[
              Text(
                e.key,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(_tallyMarks(e.value), style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 8),
            ],
          ],
        ),
      DataDisplayAs.table => DataTable(
          columns: const [
            DataColumn(label: Text('Ad')),
            DataColumn(label: Text('Adet')),
          ],
          rows: [
            for (final e in question.dataset.entries)
              DataRow(
                cells: [
                  DataCell(Text(e.key)),
                  DataCell(Text('${e.value}')),
                ],
              ),
          ],
        ),
      DataDisplayAs.barChart => _BarChart(dataset: question.dataset),
    };
  }

  String _tallyMarks(int n) {
    final groups = n ~/ 5;
    final rem = n % 5;
    return '${'卌 ' * groups}${'|' * rem}'.trim();
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.dataset});

  final Map<String, int> dataset;

  @override
  Widget build(BuildContext context) {
    final maxV = dataset.values.fold<int>(1, (a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final e in dataset.entries) ...[
          Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  e.key,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth * (e.value / maxV).clamp(0.08, 1.0);
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: w,
                        height: 28,
                        decoration: BoxDecoration(
                          color: LulunaColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '${e.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
