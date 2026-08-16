import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/widgets/education_ui.dart';
import '../../../app/widgets/luluna_ui.dart';
import '../../../data/models/skill_keys.dart';
import '../../../data/models/skill_level.dart';
import '../../../data/providers.dart';
import '../../education/data/student_skill_level_repository.dart';
import '../domain/ai_content_models.dart';
import '../domain/image_quota_exception.dart';
import 'ai_content_providers.dart';
import 'ai_mock_scene_preview.dart';

/// Faz 19: doğal dil → skill_key + soru + görsel → önizleme → onay → yayın.
class TeacherAiContentScreen extends ConsumerStatefulWidget {
  const TeacherAiContentScreen({super.key});

  @override
  ConsumerState<TeacherAiContentScreen> createState() =>
      _TeacherAiContentScreenState();
}

class _TeacherAiContentScreenState
    extends ConsumerState<TeacherAiContentScreen> {
  final _prompt = TextEditingController(
    text: 'Deniz için toplama ile ilgili, elma temalı bir soru hazırla',
  );
  var _busy = false;
  var _regenBusy = false;
  String? _error;
  TeacherAiActivity? _preview;

  /// false = genel havuz; true = belirli öğrenci
  var _assignToStudent = false;
  String? _selectedStudentId;
  SkillTier? _manualDifficulty;

  final _instruction = TextEditingController();
  final _question = TextEditingController();
  final _answer = TextEditingController();
  final _choices = TextEditingController();
  String? _editSkillKey;

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
    _editSkillKey = a.skillKey;
    _assignToStudent = a.targetStudentId != null;
    _selectedStudentId = a.targetStudentId;
  }

  SkillTier? _suggestedTierForStudent(String? studentId) {
    if (studentId == null) return _manualDifficulty;
    final repo = StudentSkillLevelRepository(
      ref.read(sharedPreferencesProvider),
    );
    // Varsayılan: toplama seviyesi veya genel orta
    return repo.tierFor(studentId, SkillKeys.addition) ??
        _manualDifficulty ??
        SkillTier.medium;
  }

  Future<void> _generate() async {
    final text = _prompt.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Bir yönerge yazın.');
      return;
    }
    if (_assignToStudent &&
        (_selectedStudentId == null || _selectedStudentId!.isEmpty)) {
      setState(() => _error = 'Öğrenci seçin veya genel havuza geçin.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final suggested = _assignToStudent
          ? _suggestedTierForStudent(_selectedStudentId)
          : _manualDifficulty;
      final activity = await ref.read(teacherAiActivitiesProvider.notifier).generate(
            text,
            suggestedDifficulty: suggested,
            targetStudentId: _assignToStudent ? _selectedStudentId : null,
          );
      if (!mounted) return;
      setState(() {
        _bindEditors(activity);
        _busy = false;
        if (activity.needsCategoryReview) {
          _error =
              'Kategori seçilmedi veya AI emin değil — lütfen aşağıdan skill_key seçin.';
        }
      });
    } on ImageQuotaExceededException catch (e) {
      if (!mounted) return;
      final all = ref.read(teacherAiActivitiesProvider);
      TeacherAiActivity? draft;
      for (final a in all) {
        if (a.teacherPrompt == text || a.imagePending) draft = a;
      }
      setState(() {
        _busy = false;
        _error = e.message;
        if (draft != null) _bindEditors(draft);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        final msg = '$e';
        if (ImageQuotaExceededException.matches(e)) {
          _error =
              'Günlük görsel üretim kotası doldu, yarın tekrar deneyin.';
        } else if (msg.contains('404') || msg.contains('bulunamadı')) {
          _error =
              'Gemini modeli bulunamadı (404). '
              'config/gemini.json → GEMINI_MODEL=gemini-3.5-flash '
              '(eski gemini-2.0-flash kapatıldı). Uygulamayı yeniden başlatın.';
        } else if (msg.contains('DioException')) {
          _error = 'Ağ/API hatası: ${_shortError(msg)}';
        } else {
          _error = 'Üretim başarısız: ${_shortError(msg)}';
        }
      });
    }
  }

  static String _shortError(String msg) {
    final one = msg.replaceAll('\n', ' ').trim();
    return one.length > 220 ? '${one.substring(0, 220)}…' : one;
  }

  Future<void> _saveEdits() async {
    final current = _preview;
    if (current == null) return;
    final choices = _choices.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final skill = _editSkillKey;
    final needsReview = skill == null || !SkillKeys.mvp.contains(skill);
    final updated = current.copyWith(
      structured: current.structured.copyWith(
        instruction: _instruction.text.trim(),
        questionText: _question.text.trim(),
        answer: _answer.text.trim(),
        choices: choices,
      ),
      skillKey: skill,
      clearSkillKey: needsReview,
      needsCategoryReview: needsReview,
      targetStudentId: _assignToStudent ? _selectedStudentId : null,
      clearTargetStudent: !_assignToStudent,
      confidence: needsReview ? 0 : (current.confidence < 0.6 ? 0.8 : current.confidence),
    );
    await ref.read(teacherAiActivitiesProvider.notifier).updateDraft(updated);
    setState(() {
      _preview = updated;
      _error = needsReview
          ? 'Kategori seçilmedi, lütfen seçin.'
          : null;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Taslak güncellendi')),
    );
  }

  Future<void> _regenerateImage() async {
    final id = _preview?.id;
    if (id == null) return;
    setState(() {
      _regenBusy = true;
      _error = null;
    });
    try {
      final next = await ref
          .read(teacherAiActivitiesProvider.notifier)
          .regenerateImage(id);
      if (!mounted) return;
      setState(() {
        _bindEditors(next);
        _regenBusy = false;
      });
    } on ImageQuotaExceededException catch (e) {
      if (!mounted) return;
      setState(() {
        _regenBusy = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _regenBusy = false;
        _error = 'Görsel yenilenemedi: $e';
      });
    }
  }

  Future<void> _approve() async {
    final id = _preview?.id;
    if (id == null) return;
    await _saveEdits();
    try {
      await ref.read(teacherAiActivitiesProvider.notifier).approve(id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
      return;
    }
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
    try {
      await ref.read(teacherAiActivitiesProvider.notifier).publish(id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
      return;
    }
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
              ? (next?.targetStudentId != null
                  ? 'Yayınlandı ve öğrenciye atandı'
                  : 'Yayınlandı — havuza eklendi')
              : 'Önce kategori seçip onaylayın',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activities = ref.watch(teacherAiActivitiesProvider);
    final students =
        ref.watch(teacherStudentsProvider).asData?.value ?? const [];
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: const Text('AI ile Soru Oluştur'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/teacher'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const EducationStatusPanel(
            title: 'Faz 19 — otomatik kategori',
            body:
                'Tek prompt → soru + görsel + skill_key önerisi. '
                'Öğrenciye gitmez; Önizleme → Onay → Yayın zorunlu. '
                'Düşük güven veya bilinmeyen kategoride siz seçersiniz.',
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
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Örn. Deniz için toplama, elma temalı bir soru hazırla',
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Belirli öğrenciye ata'),
            subtitle: Text(
              _assignToStudent
                  ? 'Öğrencinin skill seviyesine göre zorluk önerilir'
                  : 'Genel havuza ekle (zorluğu siz seçebilirsiniz)',
            ),
            value: _assignToStudent,
            onChanged: (v) => setState(() {
              _assignToStudent = v;
              if (!v) _selectedStudentId = null;
            }),
          ),
          if (_assignToStudent) ...[
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _selectedStudentId,
              decoration: const InputDecoration(labelText: 'Öğrenci'),
              items: [
                for (final s in students)
                  DropdownMenuItem(
                    value: s.id,
                    child: Text(s.name),
                  ),
              ],
              onChanged: (v) => setState(() => _selectedStudentId = v),
            ),
          ] else ...[
            DropdownButtonFormField<SkillTier>(
              // ignore: deprecated_member_use
              value: _manualDifficulty,
              decoration: const InputDecoration(
                labelText: 'Zorluk (opsiyonel öneri)',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('AI seçsin')),
                for (final t in SkillTier.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (v) => setState(() => _manualDifficulty = v),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: LulunaColors.error)),
          ],
          const SizedBox(height: 12),
          LulunaPrimaryButton(
            label: _busy ? 'Oluşturuluyor…' : 'Oluştur',
            busy: _busy,
            icon: Icons.play_arrow,
            onPressed: _busy ? null : _generate,
          ),
          if (_preview != null) ...[
            const SizedBox(height: 28),
            Text(
              'Önizleme (düzenlenebilir)',
              style:
                  textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Durum: ${_preview!.statusLabel}'
              '${_preview!.imagePending ? ' · görsel bekliyor' : ''}',
              style: textTheme.bodyMedium?.copyWith(
                color: LulunaColors.onSurfaceVariant,
              ),
            ),
            Text(
              'AI güveni: ${(_preview!.confidence * 100).round()}%'
              '${_preview!.needsCategoryReview ? ' — kategori seçilmedi' : ''}',
              style: textTheme.bodySmall?.copyWith(
                color: _preview!.needsCategoryReview
                    ? LulunaColors.error
                    : LulunaColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            LulunaCard(
              color: LulunaColors.secondaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AiMockScenePreview(activity: _preview!),
                  if (_preview!.imagePending)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Görsel daha sonra eklenecek (kota). '
                        'Soruyu yine de düzenleyip onaylayabilirsiniz.',
                      ),
                    ),
                  TextButton.icon(
                    onPressed: _regenBusy ? null : _regenerateImage,
                    icon: _regenBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Görseli yeniden üret'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _editSkillKey != null &&
                      SkillKeys.mvp.contains(_editSkillKey)
                  ? _editSkillKey
                  : null,
              decoration: InputDecoration(
                labelText: _preview!.needsCategoryReview
                    ? 'Kategori seçilmedi — lütfen seçin'
                    : 'Kategori (skill_key)',
                errorText: _preview!.needsCategoryReview
                    ? 'AI emin değil veya geçersiz kategori'
                    : null,
              ),
              items: [
                for (final k in SkillKeys.mvp)
                  DropdownMenuItem(
                    value: k,
                    child: Text('${SkillKeys.label(k)} ($k)'),
                  ),
              ],
              onChanged: (v) => setState(() {
                _editSkillKey = v;
                if (_preview != null && v != null) {
                  _preview = _preview!.copyWith(
                    skillKey: v,
                    needsCategoryReview: false,
                    confidence: _preview!.confidence < 0.6
                        ? 0.8
                        : _preview!.confidence,
                  );
                }
              }),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<SkillTier>(
              // ignore: deprecated_member_use
              value: _preview!.structured.difficulty,
              decoration: const InputDecoration(labelText: 'Zorluk'),
              items: [
                for (final t in SkillTier.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (v) {
                if (v == null || _preview == null) return;
                setState(() {
                  _preview = _preview!.copyWith(
                    structured: _preview!.structured.copyWith(difficulty: v),
                  );
                });
              },
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
                    onPressed: (_preview!.status == AiActivityStatus.preview ||
                                _preview!.status == AiActivityStatus.draft ||
                                _preview!.status ==
                                    AiActivityStatus.pendingRetry) &&
                            (_editSkillKey != null ||
                                !_preview!.needsCategoryReview)
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
              body: 'Yukarıdan bir yönerge yazıp Oluştur’a basın.',
            )
          else
            for (final a in activities) ...[
              EducationBigTile(
                title: a.structured.questionText,
                subtitle:
                    '${a.statusLabel} · ${a.skillKey != null ? SkillKeys.label(a.skillKey!) : 'kategori yok'} · ${a.structured.difficulty.label}',
                onTap: () => setState(() => _bindEditors(a)),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}
