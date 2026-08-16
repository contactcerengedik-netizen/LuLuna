import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:luluna/data/models/education_question.dart';
import 'package:luluna/data/models/skill_level.dart';
import 'package:luluna/features/education/presentation/widgets/education_question_visual.dart';
import 'package:luluna/features/education/presentation/widgets/question_player.dart';
import 'package:luluna/features/language/data/language_question_generator.dart';
import 'package:luluna/features/mathematics/data/math_question_generator.dart';

void main() {
  test('math/lang sorularında imageUrl + solutionImageUrl dolu', () {
    final math = MathQuestionGenerator().generate(
      category: 'addition',
      difficulty: SkillTier.easy,
      count: 3,
    );
    final lang = LanguageQuestionGenerator().generate(
      category: 'antonyms',
      difficulty: SkillTier.easy,
      count: 3,
    );
    for (final q in [...math, ...lang]) {
      expect(q.imageUrl, isNotNull);
      expect(q.solutionImageUrl, isNotNull);
      expect(q.imageUrl, isNotEmpty);
    }
  });

  testWidgets('ChoiceQuestionView görsel + çözüm painter render eder',
      (tester) async {
    const q = EducationQuestion(
      id: 't1',
      category: 'addition',
      skill: SkillArea.mathematics,
      difficulty: SkillTier.easy,
      instruction: 'Topla',
      questionText: '2+3',
      imageUrl: 'mock://math/addition',
      solutionImageUrl: 'mock://math/addition/solution',
      choices: ['4', '5', '6'],
      correctAnswer: '5',
      metadata: {'type': 'multipleChoice', 'a': 2, 'b': 3},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChoiceQuestionView(
              question: q,
              onAnswer: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(find.byType(EducationQuestionVisual), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EducationQuestionVisual(
            question: q,
            mode: EducationVisualMode.solution,
          ),
        ),
      ),
    );
    expect(find.byType(EducationQuestionVisual), findsOneWidget);
  });
}
