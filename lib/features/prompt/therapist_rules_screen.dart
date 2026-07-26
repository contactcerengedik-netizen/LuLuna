import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/navigation.dart';
import '../../app/theme.dart';
import '../../app/widgets/luluna_ui.dart';
import '../../data/models/therapist_rules.dart';
import '../../data/providers.dart';

/// Terapistin AI davranış kurallarını eşleşmiş veli hesabına kaydettiği ekran.
class TherapistRulesScreen extends ConsumerStatefulWidget {
  const TherapistRulesScreen({super.key});

  @override
  ConsumerState<TherapistRulesScreen> createState() =>
      _TherapistRulesScreenState();
}

class _TherapistRulesScreenState extends ConsumerState<TherapistRulesScreen> {
  late List<String> _rules;
  final _controller = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rules = [...ref.read(appStateProvider).therapistRules.rules];
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(appStateProvider.notifier).refreshTherapistRules();
      if (mounted) {
        setState(() {
          _rules = [...ref.read(appStateProvider).therapistRules.rules];
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Bulut kuralları alınamadı.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(appStateProvider.notifier)
          .saveTherapistRules(TherapistRules(rules: _rules));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kurallar eşleşmiş veli hesabına kaydedildi'),
          ),
        );
        lulunaGoBack(context);
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _add() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _rules = [..._rules, value];
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: lulunaAppBar(
        context,
        title: 'Terapist Kuralları',
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: const Text('Kaydet'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (_busy) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
          ],
          if (_error != null) ...[
            Text(
              _error!,
              style: const TextStyle(color: LulunaColors.error),
            ),
            const SizedBox(height: 12),
          ],
          LulunaCard(
            color: LulunaColors.surfaceContainerLow,
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info, color: LulunaColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: LulunaColors.onSurfaceVariant,
                          ),
                      children: const [
                        TextSpan(
                          text:
                              'Bu kurallar system prompt\'a ',
                        ),
                        TextSpan(
                          text: "'öncelikli'",
                          style: TextStyle(
                            color: LulunaColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' olarak enjekte edilir. Örn: "Kalabalık ortamlarda '
                              'komut verme, sadece nefes egzersizi yaptır."',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              TextField(
                controller: _controller,
                minLines: 4,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Yeni kural ekle…',
                  filled: true,
                  fillColor:
                      LulunaColors.surfaceContainerHighest.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.fromLTRB(16, 16, 64, 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: LulunaColors.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _add(),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Material(
                  color: LulunaColors.primary,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _add,
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.add_circle, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Aktif Kurallar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: LulunaColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_rules.length} Kural',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: LulunaColors.primary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_rules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.gavel,
                    size: 48,
                    color: LulunaColors.outline.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Henüz kural yok. Genel davranış kuralları geçerli.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: LulunaColors.outline,
                        ),
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < _rules.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: LulunaCard(
                  padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            LulunaColors.primary.withValues(alpha: 0.05),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: LulunaColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(_rules[i]),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: LulunaColors.error,
                        ),
                        onPressed: () =>
                            setState(() => _rules = [..._rules]..removeAt(i)),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 16),
          LulunaPrimaryButton(
            label: 'Kaydet ve Uygula',
            icon: Icons.check_circle,
            onPressed: _busy ? null : _save,
            busy: _busy,
          ),
        ],
      ),
    );
  }
}
