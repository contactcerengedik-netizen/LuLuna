import 'package:flutter_test/flutter_test.dart';

import 'package:luluna/core/memory/memory_engine.dart';

void main() {
  group('MemoryEngine match', () {
    test('eşleşen çift matched + reaction', () {
      final faces = MemoryEngine.defaultPool().take(2).toList();
      final engine = MemoryEngine(
        faces: faces,
        pairCount: 2,
        random: null,
      );
      expect(engine.cards, hasLength(4));

      // Find two cards with same pairId
      final first = 0;
      final pairId = engine.cards[first].face.pairId;
      final second = engine.cards.indexWhere(
        (c) => c.face.pairId == pairId && c.id != engine.cards[first].id,
      );

      expect(engine.flip(first), isNull);
      final result = engine.flip(second);
      expect(result, isNotNull);
      expect(result!.matched, isTrue);
      expect(result.reactionMs, greaterThanOrEqualTo(0));
      expect(engine.correctCount, 1);
    });

    test('yanlış eşleşme kapanır', () {
      final engine = MemoryEngine(
        faces: MemoryEngine.defaultPool(),
        pairCount: 3,
        random: null,
      );
      // Find two different pairIds
      final a = 0;
      final b = engine.cards.indexWhere(
        (c) => c.face.pairId != engine.cards[a].face.pairId,
      );
      engine.flip(a);
      final result = engine.flip(b);
      expect(result!.matched, isFalse);
      expect(engine.wrongCount, 1);
      expect(engine.inputLocked, isTrue);
      engine.closeMismatched(a, b);
      expect(engine.cards[a].faceUp, isFalse);
      expect(engine.inputLocked, isFalse);
    });
  });

  group('MemoryEngine flash', () {
    test('göster → sor → doğru cevap', () {
      final engine = MemoryEngine(
        faces: MemoryEngine.defaultPool(),
        displayDurationMs: 1000,
        pairCount: 3,
        random: null,
      );
      engine.startFlash(pool: MemoryEngine.defaultPool(), count: 3);
      expect(engine.flashRevealing, isTrue);
      expect(engine.flashShown, hasLength(3));
      engine.endFlashReveal();
      expect(engine.flashRevealing, isFalse);
      final target = engine.flashTarget!;
      final result = engine.answerFlash(target.pairId);
      expect(result.correct, isTrue);
      expect(engine.averageReactionMs, isNotNull);
    });

    test('yanlış flash cevabı', () {
      final engine = MemoryEngine(
        faces: MemoryEngine.defaultPool(),
        pairCount: 3,
        random: null,
      );
      engine.startFlash(pool: MemoryEngine.defaultPool(), count: 2);
      engine.endFlashReveal();
      final shown = engine.flashShown.map((f) => f.pairId).toSet();
      final wrong = MemoryEngine.defaultPool()
          .firstWhere((f) => !shown.contains(f.pairId));
      final result = engine.answerFlash(wrong.pairId);
      expect(result.correct, isFalse);
      expect(engine.wrongCount, 1);
    });

    test('flash: doğru şık gösterilenlerle tutarlı; çeldirici gösterilmez', () {
      for (var i = 0; i < 10; i++) {
        final engine = MemoryEngine(
          faces: MemoryEngine.defaultPool(),
          pairCount: 3,
          random: null,
        );
        engine.startFlash(pool: MemoryEngine.defaultPool(), count: 3);
        engine.endFlashReveal();
        final shown = engine.flashShown.map((f) => f.pairId).toSet();
        expect(shown.contains(engine.flashTarget!.pairId), isTrue);
        final choices = engine.flashChoices();
        final choiceIds = choices.map((c) => c.pairId).toSet();
        // Çeldiriciler gösterilenlerle kesişmemeli (hedef hariç).
        for (final id in choiceIds) {
          if (id == engine.flashTarget!.pairId) continue;
          expect(shown.contains(id), isFalse);
        }
        expect(engine.answerFlash(engine.flashTarget!.pairId).correct, isTrue);
      }
    });
  });
}
