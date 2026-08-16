/// Örüntü tamamlama (v3 Faz 13).
/// [pattern] gösterilen dizi; [missingIndex] boşluk (?).
class PatternQuestion {
  const PatternQuestion({
    required this.id,
    required this.instruction,
    required this.pattern,
    required this.missingIndex,
    required this.choices,
    this.kind = PatternKind.complete,
  }) : assert(missingIndex >= 0);

  final String id;
  final String instruction;
  final List<String> pattern;
  final int missingIndex;
  final List<String> choices;
  final PatternKind kind;

  String get correctAnswer {
    if (kind == PatternKind.oddOneOut) {
      return pattern[missingIndex];
    }
    return pattern[missingIndex];
  }

  /// Ekranda gösterilen dizi (? ile).
  List<String> get displayPattern {
    if (kind == PatternKind.oddOneOut) {
      return List<String>.from(pattern);
    }
    return [
      for (var i = 0; i < pattern.length; i++)
        i == missingIndex ? '?' : pattern[i],
    ];
  }

  bool isCorrect(String answer) =>
      answer.trim().toLowerCase() == correctAnswer.trim().toLowerCase();

  Map<String, dynamic> toMap() => {
        'type': 'pattern',
        'id': id,
        'instruction': instruction,
        'pattern': pattern,
        'missingIndex': missingIndex,
        'choices': choices,
        'kind': kind.name,
      };

  factory PatternQuestion.fromMap(Map<String, dynamic> map) {
    final kindName = map['kind'] as String? ?? 'complete';
    return PatternQuestion(
      id: map['id'] as String? ?? '',
      instruction: map['instruction'] as String? ?? '',
      pattern: [for (final e in (map['pattern'] as List? ?? const [])) '$e'],
      missingIndex: map['missingIndex'] as int? ?? 0,
      choices: [for (final e in (map['choices'] as List? ?? const [])) '$e'],
      kind: PatternKind.values.asNameMap()[kindName] ?? PatternKind.complete,
    );
  }
}

enum PatternKind {
  /// Eksik parçayı tamamla.
  complete,

  /// Farklı olanı bul ([missingIndex] = farklı öğe).
  oddOneOut,
}
