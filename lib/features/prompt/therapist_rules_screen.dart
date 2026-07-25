import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/navigation.dart';
import '../../data/models/therapist_rules.dart';
import '../../data/providers.dart';

/// Terapistin AI davranış kurallarını yerel olarak düzenlediği ekran.
class TherapistRulesScreen extends ConsumerStatefulWidget {
  const TherapistRulesScreen({super.key});

  @override
  ConsumerState<TherapistRulesScreen> createState() =>
      _TherapistRulesScreenState();
}

class _TherapistRulesScreenState extends ConsumerState<TherapistRulesScreen> {
  late List<String> _rules;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rules = [...ref.read(appStateProvider).therapistRules.rules];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref
        .read(appStateProvider.notifier)
        .saveTherapistRules(TherapistRules(rules: _rules));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terapist kuralları kaydedildi')),
      );
      lulunaGoBack(context);
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
          TextButton(onPressed: _save, child: const Text('Kaydet')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Bu kurallar system prompt\'a "öncelikli" olarak enjekte edilir. '
            'Örn: "Kalabalık ortamlarda komut verme, sadece nefes egzersizi yaptır."',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Yeni kural ekle…',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: _add,
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _add(),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          if (_rules.isEmpty)
            Text(
              'Henüz kural yok. Genel davranış kuralları geçerli.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...[
              for (var i = 0; i < _rules.length; i++)
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 14,
                      child:
                          Text('${i + 1}', style: const TextStyle(fontSize: 12)),
                    ),
                    title: Text(_rules[i]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => setState(
                        () => _rules = [..._rules]..removeAt(i),
                      ),
                    ),
                  ),
                ),
            ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
