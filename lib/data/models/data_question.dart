/// Grafik / çetele / tablo okuma sorusu (v3 Faz 13).
class DataQuestion {
  const DataQuestion({
    required this.id,
    required this.instruction,
    required this.dataset,
    required this.displayAs,
    required this.questionType,
    required this.questionText,
    required this.choices,
    required this.correctAnswer,
    this.fromAttempts = false,
  });

  final String id;
  final String instruction;
  final Map<String, int> dataset;
  final DataDisplayAs displayAs;
  final DataQuestionType questionType;
  final String questionText;
  final List<String> choices;
  final String correctAnswer;

  /// activity_attempts özetinden üretildiyse true.
  final bool fromAttempts;

  bool isCorrect(String answer) =>
      answer.trim().toLowerCase() == correctAnswer.trim().toLowerCase();

  Map<String, dynamic> toMap() => {
        'type': 'data',
        'id': id,
        'instruction': instruction,
        'dataset': dataset,
        'displayAs': displayAs.name,
        'questionType': questionType.name,
        'questionText': questionText,
        'choices': choices,
        'correctAnswer': correctAnswer,
        'fromAttempts': fromAttempts,
      };

  factory DataQuestion.fromMap(Map<String, dynamic> map) {
    final raw = Map<String, dynamic>.from(map['dataset'] as Map? ?? const {});
    return DataQuestion(
      id: map['id'] as String? ?? '',
      instruction: map['instruction'] as String? ?? '',
      dataset: {
        for (final e in raw.entries)
          e.key: e.value is int ? e.value as int : int.tryParse('${e.value}') ?? 0,
      },
      displayAs: DataDisplayAs.values.asNameMap()[map['displayAs'] as String?] ??
          DataDisplayAs.table,
      questionType:
          DataQuestionType.values.asNameMap()[map['questionType'] as String?] ??
              DataQuestionType.max,
      questionText: map['questionText'] as String? ?? '',
      choices: [for (final e in (map['choices'] as List? ?? const [])) '$e'],
      correctAnswer: map['correctAnswer'] as String? ?? '',
      fromAttempts: map['fromAttempts'] as bool? ?? false,
    );
  }
}

enum DataDisplayAs {
  tally,
  table,
  barChart,
}

enum DataQuestionType {
  max,
  min,
  difference,
  count,
}
