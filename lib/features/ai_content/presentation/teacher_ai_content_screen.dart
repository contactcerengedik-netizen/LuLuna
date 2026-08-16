import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../app/widgets/luluna_ui.dart';
import '../domain/ai_content_models.dart';
import 'ai_content_providers.dart';
import 'ai_mock_scene_preview.dart';

/// Öğretmen: doğal dil → pipeline → önizleme → onay → yayın.
class TeacherAiContentScreen extends ConsumerStatefulWidget {
  const TeacherAiContentScreen({super.key});

  @override
  ConsumerState<TeacherAiContentScreen> createState() =>
      _TeacherAiContentScreenState();
}

class _TeacherAiContentScreenState
    extends ConsumerState<TeacherAiContentScreen> {
  final _prompt = TextEditingController(
    text:
        'Ayşe\'nin elinde 3 yumurta var.\n'
        'Buzdolabında 5 yumurta var.\n'
        'Ayşe 3 yumurtayı buzdolabına koyuyor.\n'
        'Kaç yumurta oldu?',
  );
  var _busy = false;
  String? _error;
  TeacherAiActivity? _preview;

  final _instruction = TextEditingController();
  final _question = TextEditingController();
  final _answer = TextEditingController();
  final _choices = TextEditingController();

  @override
  void dispose() {
    _prompt.dispose();
    _instruction.dispose();
    _question.dispose();
    _answer.dispose();
    _choices.dispose();
    super.dispose();
  }

  void _bindEditors(TeacherAiActivity a) {
    _preview = a;
    _instruction.text = a.structured.instruction;
    _question.text = a.structured.questionText;
    _answer.text = a.structured.answer;
    _choices.text = a.structured.choices.join(', ');
  }

  Future<void> _generate() async {
    final text = _prompt.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Bir yönerge yazın.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final activity =
          await ref.read(teacherAiActivitiesProvider.notifier).generate(text);
      if (!mounted) return;
      setState(() {
        _bindEditors(activity);
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Üretim başarısız: $e';
      });
    }
  }

  Future<void> _saveEdits() async {
    final current = _preview;
    if (current == null) return;
    final choices = _choices.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final updated = current.copyWith(
      structured: current.structured.copyWith(
        instruction: _instruction.text.trim(),
        questionText: _question.text.trim(),
        answer: _answer.text.trim(),
        choices: choices,
      ),
    );
    await ref.read(teacherAiActivitiesProvider.notifier).updateDraft(updated);
    setState(() => _preview = updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Taslak güncellendi')),
    );
  }

  Future<void> _approve() async {
    final id = _preview?.id;
    if (id == null) return;
    await _saveEdits();
    await ref.read(teacherAiActivitiesProvider.notifier).approve(id);
    final all = ref.read(teacherAiActivitiesProvider);
    TeacherAiActivity? next;
    for (final a in all) {
      if (a.id == id) next = a;
    }
    setState(() => _preview = next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Onaylandı — henüz öğrenciye gitmedi')),
    );
  }

  Future<void> _publish() async {
    final id = _preview?.id;
    if (id == null) return;
    await ref.read(teacherAiActivitiesProvider.notifier).publish(id);
    final all = ref.read(teacherAiActivitiesProvider);
    TeacherAiActivity? next;
    for (final a in all) {
      if (a.id == id) next = a;
    }
    setState(() => _preview = next);
    if (!mounted) return;
    final ok = next?.isStudentVisible == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Yayınlandı — öğrenciler görebilir'
              : 'Önce onaylayın, sonra yayınlayın',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activities = ref.watch(teacherAiActivitiesProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: const Text('AI ile Etkinlik Oluştur'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/teacher'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const EducationStatusPanel(
            title: 'Mock AI modu',
            body:
                'API anahtarı olmadan pipeline çalışır. '
                'Öğrenci yalnızca Yayınla sonrası görür '
                '(Önizleme → Onay → Yayın).',
            icon: Icons.auto_awesome,
          ),
          const SizedBox(height: 16),
          Text(
            'Öğretmen yönergesi',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _prompt,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Doğal dilde etkinlik anlat…',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: LulunaColors.error)),
          ],
          const SizedBox(height: 12),
          LulunaPrimaryButton(
            label: _busy ? 'Üretiliyor…' : 'Üret (pipeline)',
            busy: _busy,
            icon: Icons.play_arrow,
            onPressed: _busy ? null : _generate,
          ),
          if (_preview != null) ...[
            const SizedBox(height: 28),
            Text(
              'Öğretmen önizleme',
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Durum: ${_preview!.statusLabel}',
              style: textTheme.bodyMedium?.copyWith(
                color: LulunaColors.onSurfaceVariant,
              ),
            ),
            if (_preview!.analysis != null) ...[
              const SizedBox(height: 8),
              Text(
                'Analiz: kişiler ${_preview!.analysis!.people.join(', ')} · '
                'nesneler ${_preview!.analysis!.objects.join(', ')} · '
                'sayılar ${_preview!.analysis!.numbers.join(', ')}'
                '${_preview!.analysis!.operation != null ? ' · ${_preview!.analysis!.operation}' : ''}',
                style: textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            LulunaCard(
              color: LulunaColors.secondaryContainer,
              child: AiMockScenePreview(activity: _preview!),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              title: const Text('Görsel prompt (JSON’dan)'),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              children: [
                Text(
                  _preview!.visualPrompt,
                  style: textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Yönerge', style: textTheme.labelLarge),
            TextField(controller: _instruction),
            const SizedBox(height: 8),
            Text('Soru', style: textTheme.labelLarge),
            TextField(controller: _question, maxLines: 3),
            const SizedBox(height: 8),
            Text('Doğru cevap', style: textTheme.labelLarge),
            TextField(controller: _answer),
            const SizedBox(height: 8),
            Text('Şıklar (virgülle)', style: textTheme.labelLarge),
            TextField(controller: _choices),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _saveEdits,
              child: const Text('Düzenlemeyi kaydet'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _preview!.status == AiActivityStatus.preview ||
                            _preview!.status == AiActivityStatus.draft
                        ? _approve
                        : null,
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Onayla'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LulunaPrimaryButton(
                    label: 'Yayınla',
                    icon: Icons.publish_outlined,
                    onPressed: _preview!.status == AiActivityStatus.approved
                        ? _publish
                        : null,
                  ),
                ),
              ],
            ),
            if (_preview!.isStudentVisible)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Bu etkinlik öğrenciler için görünür.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: LulunaColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else if (_preview!.status == AiActivityStatus.approved)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Onaylı — yayınlayınca öğrenci görür.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: LulunaColors.onSurfaceVariant,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 28),
          Text(
            'Kayıtlı etkinlikler',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (activities.isEmpty)
            const EducationStatusPanel(
              title: 'Henüz yok',
              body: 'Yukarıdan bir yönerge üretin.',
            )
          else
            for (final a in activities) ...[
              EducationBigTile(
                title: a.structured.questionText,
                subtitle: '${a.statusLabel} · ${a.structured.difficulty.label}',
                onTap: () => setState(() => _bindEditors(a)),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}
