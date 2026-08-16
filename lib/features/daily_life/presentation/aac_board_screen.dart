import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/communication/communication_board.dart';
import '../../../data/models/skill_level.dart';
import '../../../data/providers.dart';
import '../../education/domain/activity_models.dart';
import '../../education/presentation/activity_session_controller.dart';

class AacBoardScreen extends ConsumerStatefulWidget {
  const AacBoardScreen({super.key});

  @override
  ConsumerState<AacBoardScreen> createState() => _AacBoardScreenState();
}

class _AacBoardScreenState extends ConsumerState<AacBoardScreen> {
  static const _prefsKey = 'aac_usage_v1';
  late CommunicationBoard _board;
  String? _lastSpoken;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _board = CommunicationBoard(cards: CommunicationBoard.defaultCards());
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        _board.setUsageCounts({
          for (final e in map.entries)
            e.key: e.value is int
                ? e.value as int
                : int.tryParse('${e.value}') ?? 0,
        });
      } catch (_) {}
    }
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _saveUsage() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_prefsKey, jsonEncode(_board.usageSnapshot()));
  }

  Future<void> _onTap(CommCard card) async {
    final tapped = _board.tap(card.id);
    if (tapped == null) return;
    setState(() => _lastSpoken = tapped.label);
    await _saveUsage();
    try {
      await ref.read(speechServiceProvider).speak(tapped.label);
    } catch (_) {}
    final profile = ref.read(currentStudentProfileProvider).asData?.value;
    final studentId =
        profile?.id ?? ref.read(authStateProvider)?.userId ?? 'demo-student';
    final now = DateTime.now();
    await ref.read(activityAttemptRepositoryProvider).append(
          ActivityAttempt(
            id: 'aac_${now.millisecondsSinceEpoch}',
            studentId: studentId,
            skill: SkillArea.communication.name,
            category: 'aac',
            difficulty: SkillTier.easy.name,
            questionId: tapped.id,
            givenAnswer: tapped.label,
            correct: true,
            attemptedAt: now,
          ),
        );
  }

  IconData _icon(String name) => switch (name) {
        'water_drop' => Icons.water_drop_outlined,
        'restaurant' => Icons.restaurant_outlined,
        'handshake' => Icons.handshake_outlined,
        'wc' => Icons.wc_outlined,
        'pause_circle' => Icons.pause_circle_outline,
        'thumb_up' => Icons.thumb_up_outlined,
        'thumb_down' => Icons.thumb_down_outlined,
        'add_circle' => Icons.add_circle_outline,
        _ => Icons.chat_bubble_outline,
      };

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cards = _board.cardsSorted;
    return Scaffold(
      backgroundColor: LulunaColors.surface,
      appBar: AppBar(
        title: const Text('AAC panosu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(speechServiceProvider).stop();
            context.go('/student/daily-life');
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Dokununca sesli söylenir. Sık kullandığın öne çıkar.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LulunaColors.onSurfaceVariant,
                    ),
              ),
              if (_lastSpoken != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Söylenen: “$_lastSpoken”',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, i) {
                    final c = cards[i];
                    return Material(
                      color: LulunaColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _onTap(c),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_icon(c.iconName), size: 40),
                              const SizedBox(height: 8),
                              Text(
                                c.label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '×${c.usageCount}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: LulunaColors.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
