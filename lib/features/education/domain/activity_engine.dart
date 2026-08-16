import '../../../data/models/education_question.dart';
import '../../../data/models/skill_level.dart';
import 'activity_models.dart';

/// Yeniden kullanılabilir soru / aktivite oturumu.
class ActivityEngine {
  ActivityEngine({
    required this.studentId,
    required List<EducationQuestion> questions,
  }) : _questions = List.unmodifiable(questions) {
    if (_questions.isEmpty) {
      throw ArgumentError('ActivityEngine en az bir soru ister');
    }
  }

  final String studentId;
  final List<EducationQuestion> _questions;
  final List<ActivityAttempt> _attempts = [];

  var _index = 0;
  var _correct = 0;
  var _wrong = 0;
  DateTime? _questionStartedAt;

  List<EducationQuestion> get questions => _questions;
  int get index => _index;
  int get total => _questions.length;
  int get correctCount => _correct;
  int get wrongCount => _wrong;
  bool get isComplete => _index >= _questions.length;
  EducationQuestion get current => _questions[_index];
  List<ActivityAttempt> get attempts => List.unmodifiable(_attempts);

  void markQuestionStarted([DateTime? at]) {
    _questionStartedAt = at ?? DateTime.now();
  }

  /// Cevabı değerlendirir; doğruysa sonraki soruya geçer.
  /// Yanlışta aynı soruda kalır (özel eğitim: tekrar şansı).
  /// [advanceOnWrong] true ise yanlışta da ilerler.
  AnswerEvaluation submit(
    String answer, {
    bool advanceOnWrong = false,
  }) {
    if (isComplete) {
      throw StateError('Oturum tamamlandı');
    }
    final q = current;
    final ok = q.isCorrect(answer);
    final now = DateTime.now();
    final started = _questionStartedAt ?? now;
    final attempt = ActivityAttempt(
      id: '${q.id}_${now.millisecondsSinceEpoch}',
      studentId: studentId,
      skill: q.skill.name,
      category: q.category,
      difficulty: q.difficulty.name,
      questionId: q.id,
      givenAnswer: answer,
      correct: ok,
      attemptedAt: now,
      durationMs: now.difference(started).inMilliseconds,
    );
    _attempts.add(attempt);
    if (ok) {
      _correct++;
      _index++;
      _questionStartedAt = null;
    } else {
      _wrong++;
      if (advanceOnWrong) {
        _index++;
        _questionStartedAt = null;
      } else {
        _questionStartedAt = DateTime.now();
      }
    }
    return AnswerEvaluation(
      correct: ok,
      explanation: q.explanation,
      attempt: attempt,
      finished: isComplete,
    );
  }

  ActivitySessionResult result() {
    final sample = _questions.first;
    return ActivitySessionResult(
      skill: sample.skill.name,
      category: sample.category,
      difficulty: sample.difficulty.name,
      total: _questions.length,
      correctCount: _correct,
      wrongCount: _wrong,
      attempts: List.unmodifiable(_attempts),
      finishedAt: DateTime.now(),
    );
  }
}

class AnswerEvaluation {
  const AnswerEvaluation({
    required this.correct,
    required this.attempt,
    required this.finished,
    this.explanation,
  });

  final bool correct;
  final String? explanation;
  final ActivityAttempt attempt;
  final bool finished;
}

abstract class QuestionGenerator {
  SkillArea get skill;
  List<EducationQuestion> generate({
    required String category,
    required SkillTier difficulty,
    int count = 10,
    List<String> excludeIds = const [],
  });
}
