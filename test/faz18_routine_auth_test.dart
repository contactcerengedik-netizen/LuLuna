import 'package:flutter_test/flutter_test.dart';

import 'package:luluna/core/routine/routine_engine.dart';
import 'package:luluna/data/models/user_role.dart';
import 'package:luluna/data/providers.dart';
import 'package:luluna/features/daily_life/data/routine_sequence_catalog.dart';

void main() {
  group('RoutineSequenceCatalog (Faz 18.6)', () {
    test('en az 3 rutin ve sürükle-bırak için karışık sıra', () {
      expect(RoutineSequenceCatalog.builtins.length, greaterThanOrEqualTo(3));
      final morning = RoutineSequenceCatalog.byId('morning');
      expect(morning, isNotNull);
      expect(morning!.title, 'Sabah Rutini');
      final seq = morning.shuffledSequence(random: null);
      expect(seq.items, hasLength(morning.steps.length));
      expect(seq.isCorrectSequence(morning.labelsInOrder), isTrue);
    });

    test('öğretmen custom rutin ekler', () {
      RoutineSequenceCatalog.addCustom(
        const RoutineSequenceActivity(
          id: 'test_custom',
          title: 'Test Rutin',
          steps: [
            RoutineStep(id: 'a', label: 'A', iconName: 'circle'),
            RoutineStep(id: 'b', label: 'B', iconName: 'circle'),
            RoutineStep(id: 'c', label: 'C', iconName: 'circle'),
          ],
        ),
      );
      expect(RoutineSequenceCatalog.byId('test_custom')?.title, 'Test Rutin');
    });
  });

  group('Login path role gate (Faz 18.7)', () {
    test('veli/öğretmen yolları karışmaz', () {
      expect(
        resolveRoleForLogin(email: 'veli@demo.com', path: LoginPath.family),
        UserRole.parent,
      );
      expect(
        resolveRoleForLogin(email: 'teacher@demo.com', path: LoginPath.teacher),
        UserRole.teacher,
      );
      expect(
        resolveRoleForLogin(email: 'teacher@demo.com', path: LoginPath.family),
        isNull,
      );
      expect(
        resolveRoleForLogin(email: 'veli@demo.com', path: LoginPath.teacher),
        isNull,
      );
      expect(
        resolveRoleForLogin(email: 'student@demo.com', path: LoginPath.family),
        UserRole.student,
      );
    });
  });
}
