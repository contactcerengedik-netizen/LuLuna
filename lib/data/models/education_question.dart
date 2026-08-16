import 'sequence_question.dart';
import 'skill_level.dart';

/// Ortak aktivite / soru modeli (Matematik, Türkçe, AI).
class EducationQuestion {
  const EducationQuestion({
    required this.id,
    required this.category,
    required this.skill,
    required this.difficulty,
    required this.instruction,
    required this.questionText,
    this.imageUrl,
    this.audioUrl,
    this.choices = const [],
    required this.correctAnswer,
    this.explanation,
    this.metadata = const {},
  });

  final String id;
  final String category;
  final SkillArea skill;
  final SkillTier difficulty;
  final String instruction;
  final String questionText;
  final String? imageUrl;
  final String? audioUrl;
  final List<String> choices;
  final String correctAnswer;
  final String? explanation;
  final Map<String, dynamic> metadata;

  bool isCorrect(String answer) {
    final type = metadata['type'] as String? ?? 'multipleChoice';
    if (type == 'sequence' || type == 'order') {
      final seq = type == 'sequence'
          ? SequenceQuestion.fromMap(metadata)
          : null;
      if (seq != null && seq.items.isNotEmpty) {
        return seq.isCorrectSequence(SequenceQuestion.decode(answer));
      }
      final a = answer.trim().toLowerCase();
      final c = correctAnswer.trim().toLowerCase();
      return a == c;
    }
    final a = answer.trim().toLowerCase();
    final c = correctAnswer.trim().toLowerCase();
    return a == c;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'category': category,
    'skill': skill.name,
    'difficulty': difficulty.name,
    'instruction': instruction,
    'questionText': questionText,
    'imageUrl': imageUrl,
    'audioUrl': audioUrl,
    'choices': choices,
    'correctAnswer': correctAnswer,
    'explanation': explanation,
    'metadata': metadata,
  };

  factory EducationQuestion.fromMap(Map<String, dynamic> map) {
    return EducationQuestion(
      id: map['id'] as String? ?? '',
      category: map['category'] as String? ?? '',
      skill: SkillArea.values.asNameMap()[map['skill']] ?? SkillArea.mathematics,
      difficulty:
          SkillTier.values.asNameMap()[map['difficulty']] ?? SkillTier.easy,
      instruction: map['instruction'] as String? ?? '',
      questionText: map['questionText'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      audioUrl: map['audioUrl'] as String?,
      choices: List<String>.from(map['choices'] as List? ?? const []),
      correctAnswer: map['correctAnswer'] as String? ?? '',
      explanation: map['explanation'] as String?,
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? const {}),
    );
  }
}
