import 'dart:math';

/// Hafıza–dikkat motoru (v3 Faz 14).
/// Kart eşleştirme + kısa süreli gösterim; doğru/yanlış + tepki süresi.
class MemoryCardFace {
  const MemoryCardFace({
    required this.pairId,
    required this.label,
    required this.iconName,
  });

  final String pairId;
  final String label;
  final String iconName;
}

class MemoryCard {
  MemoryCard({
    required this.id,
    required this.face,
  });

  final String id;
  final MemoryCardFace face;
  bool faceUp = false;
  bool matched = false;
}

class MemoryMatchResult {
  const MemoryMatchResult({
    required this.matched,
    required this.reactionMs,
    required this.boardComplete,
  });

  final bool matched;
  final int reactionMs;
  final bool boardComplete;
}

class MemoryFlashResult {
  const MemoryFlashResult({
    required this.correct,
    required this.reactionMs,
  });

  final bool correct;
  final int reactionMs;
}

class MemoryEngine {
  MemoryEngine({
    required List<MemoryCardFace> faces,
    this.displayDurationMs = 3000,
    this.pairCount = 4,
    Random? random,
  }) : _rng = random ?? Random(42) {
    reset(faces: faces, pairCount: pairCount);
  }

  final Random _rng;
  int displayDurationMs;
  int pairCount;

  final List<MemoryCard> cards = [];
  final List<int> _openIndexes = [];
  final List<int> _reactionSamples = [];

  int correctCount = 0;
  int wrongCount = 0;
  DateTime? _flipStartedAt;
  bool inputLocked = false;

  /// Flash mode state
  List<MemoryCardFace> _flashShown = const [];
  MemoryCardFace? _flashTarget;
  DateTime? _flashAskAt;
  bool flashRevealing = false;

  List<int> get reactionSamples => List.unmodifiable(_reactionSamples);

  double? get averageReactionMs {
    if (_reactionSamples.isEmpty) return null;
    final sum = _reactionSamples.fold<int>(0, (a, b) => a + b);
    return sum / _reactionSamples.length;
  }

  void reset({
    List<MemoryCardFace>? faces,
    int? pairCount,
    int? displayDurationMs,
  }) {
    if (pairCount != null) this.pairCount = pairCount;
    if (displayDurationMs != null) this.displayDurationMs = displayDurationMs;
    final pool = faces ?? _defaultPool();
    final selected = [...pool]..shuffle(_rng);
    final take = selected.take(this.pairCount).toList();
    final deck = <MemoryCard>[];
    var i = 0;
    for (final f in take) {
      deck.add(MemoryCard(id: 'a$i', face: f));
      deck.add(MemoryCard(id: 'b$i', face: f));
      i++;
    }
    deck.shuffle(_rng);
    cards
      ..clear()
      ..addAll(deck);
    _openIndexes.clear();
    _reactionSamples.clear();
    correctCount = 0;
    wrongCount = 0;
    _flipStartedAt = null;
    inputLocked = false;
    _flashShown = const [];
    _flashTarget = null;
    _flashAskAt = null;
    flashRevealing = false;
  }

  /// İlk açık kart; ikinci ile eşleşme dener.
  MemoryMatchResult? flip(int index) {
    if (inputLocked) return null;
    if (index < 0 || index >= cards.length) return null;
    final card = cards[index];
    if (card.matched || card.faceUp) return null;

    card.faceUp = true;
    if (_openIndexes.isEmpty) {
      _openIndexes.add(index);
      _flipStartedAt = DateTime.now();
      return null;
    }

    final firstIdx = _openIndexes.first;
    final first = cards[firstIdx];
    final reaction = DateTime.now().difference(_flipStartedAt!).inMilliseconds;
    _reactionSamples.add(reaction);
    _openIndexes.clear();
    _flipStartedAt = null;

    if (first.face.pairId == card.face.pairId) {
      first.matched = true;
      card.matched = true;
      correctCount++;
      return MemoryMatchResult(
        matched: true,
        reactionMs: reaction,
        boardComplete: cards.every((c) => c.matched),
      );
    }

    wrongCount++;
    inputLocked = true;
    return MemoryMatchResult(
      matched: false,
      reactionMs: reaction,
      boardComplete: false,
    );
  }

  /// Eşleşmeyen iki kartı kapat (UI kısa gecikme sonrası çağırır).
  void closeMismatched(int a, int b) {
    if (a >= 0 && a < cards.length) cards[a].faceUp = false;
    if (b >= 0 && b < cards.length) cards[b].faceUp = false;
    inputLocked = false;
  }

  /// Kısa süreli bellek: [count] yüz gösterir, sonra hedef sorulur.
  void startFlash({
    required List<MemoryCardFace> pool,
    int count = 3,
  }) {
    final shuffled = [...pool]..shuffle(_rng);
    _flashShown = shuffled.take(count.clamp(1, shuffled.length)).toList();
    _flashTarget = _flashShown[_rng.nextInt(_flashShown.length)];
    flashRevealing = true;
    _flashAskAt = null;
  }

  void endFlashReveal() {
    flashRevealing = false;
    _flashAskAt = DateTime.now();
  }

  List<MemoryCardFace> get flashShown => List.unmodifiable(_flashShown);

  MemoryCardFace? get flashTarget => _flashTarget;

  /// Seçenekler: hedef (gösterilenlerden) + yalnızca gösterilmeyen çeldiriciler.
  List<MemoryCardFace> flashChoices({int choiceCount = 4}) {
    final target = _flashTarget;
    if (target == null) return const [];
    final shownIds = _flashShown.map((f) => f.pairId).toSet();
    final distractors = _defaultPool()
        .where((f) => !shownIds.contains(f.pairId))
        .toList()
      ..shuffle(_rng);
    final list = <MemoryCardFace>[target, ...distractors.take(choiceCount - 1)];
    list.shuffle(_rng);
    return list;
  }

  MemoryFlashResult answerFlash(String pairId) {
    final askAt = _flashAskAt ?? DateTime.now();
    final reaction = DateTime.now().difference(askAt).inMilliseconds;
    _reactionSamples.add(reaction);
    // Doğru = gösterilen set ile aynı referans (target set üyesi).
    final ok = _flashShown.any((f) => f.pairId == pairId);
    if (ok) {
      correctCount++;
    } else {
      wrongCount++;
    }
    return MemoryFlashResult(correct: ok, reactionMs: reaction);
  }

  static List<MemoryCardFace> _defaultPool() => const [
        MemoryCardFace(pairId: 'apple', label: 'Elma', iconName: 'apple'),
        MemoryCardFace(pairId: 'ball', label: 'Top', iconName: 'sports_soccer'),
        MemoryCardFace(pairId: 'cat', label: 'Kedi', iconName: 'pets'),
        MemoryCardFace(pairId: 'sun', label: 'Güneş', iconName: 'wb_sunny'),
        MemoryCardFace(pairId: 'star', label: 'Yıldız', iconName: 'star'),
        MemoryCardFace(pairId: 'book', label: 'Kitap', iconName: 'menu_book'),
        MemoryCardFace(pairId: 'car', label: 'Araba', iconName: 'directions_car'),
        MemoryCardFace(pairId: 'fish', label: 'Balık', iconName: 'water'),
      ];

  static List<MemoryCardFace> defaultPool() => _defaultPool();
}
