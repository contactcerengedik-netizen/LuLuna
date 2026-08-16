/// Günlük yaşam senaryo modelleri — JSON ile serileştirilebilir.
enum ScenarioStepType {
  npcSpeak,
  studentChoice,
  paymentChoice,
  complete,
}

class ScenarioChoice {
  const ScenarioChoice({
    required this.id,
    required this.label,
    this.correct = false,
  });

  final String id;
  final String label;
  final bool correct;

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'correct': correct,
      };

  factory ScenarioChoice.fromMap(Map<String, dynamic> map) {
    return ScenarioChoice(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
      correct: map['correct'] as bool? ?? false,
    );
  }
}

class ScenarioStep {
  const ScenarioStep({
    required this.id,
    required this.type,
    this.speaker,
    this.text = '',
    this.choices = const [],
    this.hint,
    this.metadata = const {},
  });

  final String id;
  final ScenarioStepType type;
  final String? speaker;
  final String text;
  final List<ScenarioChoice> choices;
  final String? hint;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'speaker': speaker,
        'text': text,
        'choices': choices.map((e) => e.toMap()).toList(),
        'hint': hint,
        'metadata': metadata,
      };

  factory ScenarioStep.fromMap(Map<String, dynamic> map) {
    final typeName = map['type'] as String? ?? 'npcSpeak';
    return ScenarioStep(
      id: map['id'] as String? ?? '',
      type: ScenarioStepType.values.asNameMap()[typeName] ??
          ScenarioStepType.npcSpeak,
      speaker: map['speaker'] as String?,
      text: map['text'] as String? ?? '',
      choices: [
        for (final e in (map['choices'] as List? ?? const []))
          ScenarioChoice.fromMap(Map<String, dynamic>.from(e as Map)),
      ],
      hint: map['hint'] as String?,
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? const {}),
    );
  }
}

class DailyLifeScenario {
  const DailyLifeScenario({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
    this.difficulty = 'easy',
    this.npcRole = 'Görevli',
  });

  final String id;
  final String title;
  final String description;
  final String difficulty;
  final String npcRole;
  final List<ScenarioStep> steps;

  Map<String, dynamic> toMap() => {
        'scenario': id,
        'title': title,
        'description': description,
        'difficulty': difficulty,
        'npcRole': npcRole,
        'steps': steps.map((e) => e.toMap()).toList(),
      };

  factory DailyLifeScenario.fromMap(Map<String, dynamic> map) {
    return DailyLifeScenario(
      id: map['scenario'] as String? ?? map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      difficulty: map['difficulty'] as String? ?? 'easy',
      npcRole: map['npcRole'] as String? ?? 'Görevli',
      steps: [
        for (final e in (map['steps'] as List? ?? const []))
          ScenarioStep.fromMap(Map<String, dynamic>.from(e as Map)),
      ],
    );
  }
}
