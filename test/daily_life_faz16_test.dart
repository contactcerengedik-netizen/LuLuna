import 'package:flutter_test/flutter_test.dart';

import 'package:luluna/core/communication/communication_board.dart';
import 'package:luluna/core/routine/routine_engine.dart';

void main() {
  group('RoutineEngine', () {
    test('firstThen ve completeCurrent', () {
      final engine = RoutineEngine(steps: RoutineEngine.morningSample());
      expect(engine.firstThen.first.label, 'Uyan');
      expect(engine.firstThen.then?.label, 'Diş fırçala');
      expect(engine.completeCurrent(), isTrue);
      expect(engine.isStepDone('wake'), isTrue);
      expect(engine.current.label, 'Diş fırçala');
      while (!engine.isComplete) {
        engine.completeCurrent();
      }
      expect(engine.isComplete, isTrue);
      expect(engine.progress, 1);
    });

    test('replaceSteps sıfırlar', () {
      final engine = RoutineEngine(steps: RoutineEngine.morningSample());
      engine.completeCurrent();
      engine.replaceSteps(const [
        RoutineStep(id: 'a', label: 'A', iconName: 'circle'),
        RoutineStep(id: 'b', label: 'B', iconName: 'circle'),
      ]);
      expect(engine.index, 0);
      expect(engine.total, 2);
      expect(engine.isStepDone('wake'), isFalse);
    });
  });

  group('CommunicationBoard', () {
    test('tap artırır ve sıralar', () {
      final board = CommunicationBoard(
        cards: CommunicationBoard.defaultCards(),
      );
      board.tap('hungry');
      board.tap('hungry');
      board.tap('water');
      final sorted = board.cardsSorted;
      expect(sorted.first.id, 'hungry');
      expect(sorted.first.usageCount, 2);
      expect(board.usageSnapshot()['water'], 1);
    });
  });
}
