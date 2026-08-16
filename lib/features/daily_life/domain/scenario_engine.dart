import 'scenario_models.dart';

/// Adım adım senaryo yürütücü (Duolingo-benzeri, özel eğitim odaklı).
class ScenarioEngine {
  ScenarioEngine(this.scenario) {
    if (scenario.steps.isEmpty) {
      throw ArgumentError('Senaryo en az bir adım içermeli');
    }
  }

  final DailyLifeScenario scenario;
  var _index = 0;
  var _wrongTries = 0;
  var _correctChoices = 0;
  String? _lastFeedback;

  int get index => _index;
  int get total => scenario.steps.length;
  int get wrongTries => _wrongTries;
  int get correctChoices => _correctChoices;
  String? get lastFeedback => _lastFeedback;
  bool get isComplete =>
      _index >= scenario.steps.length ||
      current.type == ScenarioStepType.complete;

  ScenarioStep get current => scenario.steps[
      _index.clamp(0, scenario.steps.length - 1)];

  /// NPC konuşması / tamamlandı → sonraki adıma geç.
  void continueNarration() {
    _lastFeedback = null;
    if (isComplete) return;
    if (current.type == ScenarioStepType.npcSpeak ||
        current.type == ScenarioStepType.complete) {
      _advance();
    }
  }

  /// Öğrenci seçimi / ödeme.
  ScenarioChoiceResult submitChoice(String choiceId) {
    if (isComplete) {
      return const ScenarioChoiceResult(
        accepted: false,
        finished: true,
        message: 'Senaryo bitti',
      );
    }
    final step = current;
    if (step.type != ScenarioStepType.studentChoice &&
        step.type != ScenarioStepType.paymentChoice) {
      return const ScenarioChoiceResult(
        accepted: false,
        finished: false,
        message: 'Şu an seçim sırası değil',
      );
    }

    ScenarioChoice? picked;
    for (final c in step.choices) {
      if (c.id == choiceId || c.label == choiceId) {
        picked = c;
        break;
      }
    }
    if (picked == null) {
      return const ScenarioChoiceResult(
        accepted: false,
        finished: false,
        message: 'Geçersiz seçim',
      );
    }

    if (!picked.correct) {
      _wrongTries++;
      _lastFeedback = step.hint ?? 'Tekrar dene.';
      return ScenarioChoiceResult(
        accepted: false,
        finished: false,
        message: _lastFeedback!,
      );
    }

    _correctChoices++;
    _lastFeedback = 'Doğru!';
    _advance();
    return ScenarioChoiceResult(
      accepted: true,
      finished: isComplete,
      message: _lastFeedback!,
    );
  }

  void _advance() {
    if (_index < scenario.steps.length - 1) {
      _index++;
    } else {
      _index = scenario.steps.length;
    }
  }
}

class ScenarioChoiceResult {
  const ScenarioChoiceResult({
    required this.accepted,
    required this.finished,
    required this.message,
  });

  final bool accepted;
  final bool finished;
  final String message;
}
