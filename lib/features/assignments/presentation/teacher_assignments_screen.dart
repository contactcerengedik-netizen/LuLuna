import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../app/widgets/luluna_ui.dart';
import '../../../data/models/skill_level.dart';
import '../../../data/models/student_profile.dart';
import '../../../data/providers.dart';
import '../../analytics/domain/analytics_service.dart';
import '../../language/data/language_categories.dart';
import '../../mathematics/data/math_categories.dart';
import '../domain/assignment_models.dart';
import 'assignment_providers.dart';

class TeacherAssignmentsScreen extends ConsumerWidget {
  const TeacherAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(teacherAssignmentsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: const Text('Ödevler'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/teacher'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Ödev ata'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Text(
            'Atanan ödevler',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Öğrenci ana ekranında “Bugünkü Çalışmalarım” olarak görünür.',
            style: textTheme.bodyMedium?.copyWith(
              color: LulunaColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          if (list.isEmpty)
            const EducationStatusPanel(
              title: 'Henüz ödev yok',
              body: 'Sağ alttan yeni ödev oluştur.',
              icon: Icons.assignment_outlined,
            )
          else
            for (final a in list) ...[
              LulunaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${a.skill.label} · ${AnalyticsService.categoryLabel(a.category)} · '
                      '${a.difficulty.label} · ${a.questionCount} soru',
                      style: textTheme.bodyMedium?.copyWith(
                        color: LulunaColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tamamlayan: ${a.completedStudentIds.length}/${a.studentIds.length}',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          await ref
                              .read(assignmentRepositoryProvider)
                              .delete(a.id);
                          ref.read(assignmentRefreshProvider.notifier).bump();
                        },
                        child: const Text('Sil'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Future<void> _openCreateSheet(BuildContext context, WidgetRef ref) async {
    final students =
        ref.read(teacherStudentsProvider).asData?.value ?? const [];
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Öğrenci listesi boş')),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: LulunaColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CreateAssignmentSheet(students: students),
    );
  }
}

class _CreateAssignmentSheet extends ConsumerStatefulWidget {
  const _CreateAssignmentSheet({required this.students});

  final List<StudentProfile> students;

  @override
  ConsumerState<_CreateAssignmentSheet> createState() =>
      _CreateAssignmentSheetState();
}

class _CreateAssignmentSheetState
    extends ConsumerState<_CreateAssignmentSheet> {
  SkillArea _skill = SkillArea.mathematics;
  String? _category;
  SkillTier _difficulty = SkillTier.medium;
  var _questionCount = 10;
  final _selected = <String>{};
  final _titleCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _category = MathCategories.all.first.id;
    _selected.addAll(widget.students.map((e) => e.id));
    _syncTitle();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  List<({String id, String title})> get _categories {
    if (_skill == SkillArea.language) {
      return [
        for (final c in LanguageCategories.all) (id: c.id, title: c.title),
      ];
    }
    return [
      for (final c in MathCategories.all) (id: c.id, title: c.title),
    ];
  }

  void _syncTitle() {
    final cat = AnalyticsService.categoryLabel(_category ?? '');
    _titleCtrl.text = '$cat – ${_difficulty.label}';
  }

  Future<void> _save() async {
    if (_selected.isEmpty || _category == null) return;
    final teacherId =
        ref.read(authStateProvider)?.userId ?? 'demo-teacher-1';
    final assignment = HomeworkAssignment(
      id: 'hw_${DateTime.now().millisecondsSinceEpoch}',
      teacherId: teacherId,
      title: _titleCtrl.text.trim().isEmpty
          ? 'Ödev'
          : _titleCtrl.text.trim(),
      skill: _skill,
      category: _category!,
      difficulty: _difficulty,
      questionCount: _questionCount,
      studentIds: _selected.toList(),
      createdAt: DateTime.now(),
    );
    await ref.read(assignmentRepositoryProvider).upsert(assignment);
    ref.read(assignmentRefreshProvider.notifier).bump();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Yeni ödev',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Başlık'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SkillArea>(
              // ignore: deprecated_member_use
              value: _skill,
              decoration: const InputDecoration(labelText: 'Beceri'),
              items: const [
                DropdownMenuItem(
                  value: SkillArea.mathematics,
                  child: Text('Matematik'),
                ),
                DropdownMenuItem(
                  value: SkillArea.language,
                  child: Text('Türkçe'),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _skill = v;
                  _category = _categories.first.id;
                  _syncTitle();
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [
                for (final c in _categories)
                  DropdownMenuItem(value: c.id, child: Text(c.title)),
              ],
              onChanged: (v) {
                setState(() {
                  _category = v;
                  _syncTitle();
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SkillTier>(
              // ignore: deprecated_member_use
              value: _difficulty,
              decoration: const InputDecoration(labelText: 'Zorluk'),
              items: [
                for (final t in SkillTier.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _difficulty = v;
                  _syncTitle();
                });
              },
            ),
            const SizedBox(height: 12),
            Text('Soru sayısı: $_questionCount'),
            Slider(
              value: _questionCount.toDouble(),
              min: 5,
              max: 20,
              divisions: 3,
              label: '$_questionCount',
              onChanged: (v) => setState(() => _questionCount = v.round()),
            ),
            const SizedBox(height: 8),
            Text(
              'Öğrenciler',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final s in widget.students)
              CheckboxListTile(
                value: _selected.contains(s.id),
                title: Text(s.name),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (on) {
                  setState(() {
                    if (on == true) {
                      _selected.add(s.id);
                    } else {
                      _selected.remove(s.id);
                    }
                  });
                },
              ),
            const SizedBox(height: 12),
            LulunaPrimaryButton(
              label: 'Kaydet',
              onPressed: _selected.isEmpty ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
