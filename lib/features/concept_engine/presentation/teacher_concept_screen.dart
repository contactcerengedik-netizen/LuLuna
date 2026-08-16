import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../app/widgets/luluna_ui.dart';
import '../../../data/providers.dart';
import '../data/concept_repository.dart';
import '../domain/concept_models.dart';
import 'concept_providers.dart';

/// Öğretmen: kavram seç → modüllere yay → toplu önizleme/onay.
class TeacherConceptScreen extends ConsumerStatefulWidget {
  const TeacherConceptScreen({super.key});

  @override
  ConsumerState<TeacherConceptScreen> createState() =>
      _TeacherConceptScreenState();
}

class _TeacherConceptScreenState extends ConsumerState<TeacherConceptScreen> {
  Concept? _selected;
  var _busy = false;
  ConceptAssignment? _preview;
  String? _error;

  Future<void> _generate() async {
    final concept = _selected;
    if (concept == null) {
      setState(() => _error = 'Bir kavram seçin.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final students =
          ref.read(teacherStudentsProvider).asData?.value ?? const [];
      final studentId =
          students.isNotEmpty ? students.first.id : 'demo-student-1';
      final teacherId =
          ref.read(authStateProvider)?.userId ?? 'demo-teacher-1';
      final a = await ref.read(conceptAssignmentsProvider.notifier).createAndGenerate(
            concept: concept,
            studentId: studentId,
            teacherId: teacherId,
          );
      if (!mounted) return;
      setState(() {
        _preview = a;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '$e';
      });
    }
  }

  Future<void> _publish() async {
    final id = _preview?.id;
    if (id == null) return;
    await ref.read(conceptAssignmentsProvider.notifier).publish(id);
    final all = ref.read(conceptAssignmentsProvider);
    ConceptAssignment? next;
    for (final a in all) {
      if (a.id == id) next = a;
    }
    setState(() => _preview = next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kavram içerikleri yayınlandı')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignments = ref.watch(conceptAssignmentsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: const Text('Kavram Motoru'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/teacher'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const EducationStatusPanel(
            title: 'Tek kavram → 15 alan',
            body:
                'Örn. “elma” seçildiğinde dinleme, matematik, Türkçe, çizgi, '
                'boyama, eşleştirme, örüntü, veri, hafıza, konuşma, duygu, '
                'rutin, AAC, puzzle… için ayrı içerik üretilir. '
                'Her çıktı kendi görsel seed’ini ve öğrenci rotasını alır.',
            icon: Icons.hub_outlined,
          ),
          const SizedBox(height: 16),
          Text(
            'Kavram seç',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in ConceptRepository.catalog)
                ChoiceChip(
                  label: Text('${c.name} (${c.category.label})'),
                  selected: _selected?.id == c.id,
                  onSelected: (_) => setState(() => _selected = c),
                ),
            ],
          ),
          if (_selected != null) ...[
            const SizedBox(height: 12),
            Text(
              'Modüller: ${_selected!.relatedSkills.map((e) => e.label).join(', ')}',
              style: textTheme.bodyMedium,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: LulunaColors.error)),
          ],
          const SizedBox(height: 12),
          LulunaPrimaryButton(
            label: _busy ? 'Üretiliyor…' : 'Modüllere yay ve üret',
            busy: _busy,
            icon: Icons.auto_awesome,
            onPressed: _busy ? null : _generate,
          ),
          if (_preview != null) ...[
            const SizedBox(height: 24),
            Text(
              'Önizleme / onay — ${_preview!.conceptName}',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Durum: ${_preview!.status.name} · grup: ${_preview!.consistencyGroupId}',
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final o in _preview!.outputs) ...[
              LulunaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.previewTitle ?? o.module.label,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(o.previewBody ?? ''),
                    const SizedBox(height: 4),
                    Text(
                      'Rota: ${o.studentRoute ?? o.module.studentRoute} · '
                      'seed: ${o.imageSeed ?? '—'} · ${o.status.name}',
                      style: textTheme.bodySmall?.copyWith(
                        color: LulunaColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            LulunaPrimaryButton(
              label: 'Toplu yayınla',
              icon: Icons.publish_outlined,
              onPressed: _preview!.status == ConceptAssignmentStatus.published
                  ? null
                  : _publish,
            ),
          ],
          const SizedBox(height: 28),
          Text(
            'Kayıtlı atamalar',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (assignments.isEmpty)
            const EducationStatusPanel(
              title: 'Henüz yok',
              body: 'Yukarıdan bir kavram üretin.',
            )
          else
            for (final a in assignments) ...[
              EducationBigTile(
                title: a.conceptName,
                subtitle: '${a.status.name} · ${a.outputs.length} modül',
                onTap: () => setState(() => _preview = a),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}
