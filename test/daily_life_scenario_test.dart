import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:luluna/features/daily_life/data/scenario_catalog.dart';
import 'package:luluna/features/daily_life/domain/scenario_engine.dart';
import 'package:luluna/features/daily_life/domain/scenario_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyLifeScenario JSON', () {
    test('fromMap roundtrip restoran', () {
      final s = ScenarioCatalog.restaurant;
      final again = DailyLifeScenario.fromMap(s.toMap());
      expect(again.id, 'restaurant');
      expect(again.steps.length, s.steps.length);
      expect(again.steps.first.type, ScenarioStepType.npcSpeak);
    });

    test('assets/scenarios/restaurant.json yüklenir', () async {
      final raw =
          await rootBundle.loadString('assets/scenarios/restaurant.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final s = DailyLifeScenario.fromMap(map);
      expect(s.id, 'restaurant');
      expect(s.steps.any((e) => e.type == ScenarioStepType.paymentChoice), isTrue);
    });
  });

  group('ScenarioEngine restoran akışı', () {
    test('yanlış ödemede kalır, doğroda ilerler', () {
      final engine = ScenarioEngine(ScenarioCatalog.restaurant);
      expect(engine.current.type, ScenarioStepType.npcSpeak);
      engine.continueNarration();
      expect(engine.current.id, 'order');
      expect(engine.submitChoice('quiet').accepted, isFalse);
      expect(engine.current.id, 'order');
      expect(engine.submitChoice('pizza').accepted, isTrue);
      engine.continueNarration(); // price
      expect(engine.current.id, 'pay');
      expect(engine.submitChoice('20').accepted, isFalse);
      expect(engine.submitChoice('50').accepted, isTrue);
      expect(engine.current.id, 'thanks_npc');
      engine.continueNarration();
      expect(engine.current.id, 'thanks_student');
      expect(engine.submitChoice('thanks').accepted, isTrue);
      expect(engine.current.type, ScenarioStepType.complete);
    });
  });

  group('ScenarioCatalog', () {
    test('4 senaryo tanımlı', () {
      expect(ScenarioCatalog.all.map((e) => e.id), [
        'restaurant',
        'market',
        'grocery',
        'bakery',
      ]);
    });
  });
}
