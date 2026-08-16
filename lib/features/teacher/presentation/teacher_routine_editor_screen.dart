import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/luluna_ui.dart';
import '../../../core/routine/routine_engine.dart';
import '../../daily_life/data/routine_sequence_catalog.dart';

/// Öğretmen: basit rutin seti ekleme formu.
class TeacherRoutineEditorScreen extends StatefulWidget {
  const TeacherRoutineEditorScreen({super.key});

  @override
  State<TeacherRoutineEditorScreen> createState() =>
      _TeacherRoutineEditorScreenState();
}

class _TeacherRoutineEditorScreenState extends State<TeacherRoutineEditorScreen> {
  final _title = TextEditingController();
  final _steps = <TextEditingController>[
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _title.dispose();
    for (final c in _steps) {
      c.dispose();
    }
    super.dispose();
  }

  void _addStep() {
    setState(() => _steps.add(TextEditingController()));
  }

  void _save() {
    final title = _title.text.trim();
    final labels = [
      for (final c in _steps)
        if (c.text.trim().isNotEmpty) c.text.trim(),
    ];
    if (title.isEmpty || labels.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık ve en az 2 adım gerekli.')),
      );
      return;
    }
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    RoutineSequenceCatalog.addCustom(
      RoutineSequenceActivity(
        id: id,
        title: title,
        steps: [
          for (var i = 0; i < labels.length; i++)
            RoutineStep(
              id: 's$i',
              label: labels[i],
              iconName: 'circle',
            ),
        ],
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$title" rutin sıralamaya eklendi.')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: const Text('Rutin Sıralama Ekle'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Rutin adı',
              hintText: 'Örn. Okul dönüşü',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Adımlar (doğru sırada yaz)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _steps.length; i++) ...[
            TextField(
              controller: _steps[i],
              decoration: InputDecoration(
                labelText: 'Adım ${i + 1}',
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextButton.icon(
            onPressed: _addStep,
            icon: const Icon(Icons.add),
            label: const Text('Adım ekle'),
          ),
          const SizedBox(height: 24),
          LulunaPrimaryButton(label: 'Kaydet', onPressed: _save),
        ],
      ),
    );
  }
}
