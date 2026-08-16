import 'dart:math';

import '../../../data/models/education_question.dart';
import '../../../data/models/skill_level.dart';
import '../../education/domain/activity_engine.dart';
import '../../education/domain/question_selection.dart';
import '../../education/domain/scene_visual_spec.dart';

/// Matematik soru üretici — seviye ve kategoriye göre üretir.
class MathQuestionGenerator implements QuestionGenerator {
  MathQuestionGenerator({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  @override
  SkillArea get skill => SkillArea.mathematics;

  @override
  List<EducationQuestion> generate({
    required String category,
    required SkillTier difficulty,
    int count = 10,
    List<String> excludeIds = const [],
  }) {
    final pool = <String, EducationQuestion>{};
    final target = max(QuestionSelection.minPoolSize, count * 3);
    for (var i = 0; i < 120 && pool.length < target; i++) {
      final q = _one(category: category, difficulty: difficulty, index: i);
      final stableId = _stableId(q);
      pool.putIfAbsent(
        stableId,
        () => EducationQuestion(
          id: stableId,
          category: q.category,
          skill: q.skill,
          difficulty: q.difficulty,
          instruction: q.instruction,
          questionText: q.questionText,
          imageUrl: q.imageUrl ?? 'mock://math/${q.category}',
          solutionImageUrl:
              q.solutionImageUrl ?? 'mock://math/${q.category}/solution',
          audioUrl: q.audioUrl,
          choices: q.choices,
          correctAnswer: q.correctAnswer,
          explanation: q.explanation,
          metadata: q.metadata,
        ),
      );
    }
    return QuestionSelection.pickWithoutRecent(
      pool: pool.values.toList(),
      recentIds: excludeIds,
      count: count,
      random: _rng,
    );
  }

  String _stableId(EducationQuestion q) {
    final key =
        '${q.category}|${q.difficulty.name}|${q.questionText}|${q.correctAnswer}';
    return 'math-${q.category}-${q.difficulty.name}-${key.hashCode.abs()}';
  }

  EducationQuestion _one({
    required String category,
    required SkillTier difficulty,
    required int index,
  }) {
    return switch (category) {
      'learn_numbers' || 'learn_digits' || 'number_recognition' =>
        _numberRecognition(difficulty, index, category),
      'number_ordering' => _numberOrdering(difficulty, index),
      'rhythmic_counting' => _rhythmic(difficulty, index),
      'fill_blank' => _fillBlank(difficulty, index),
      'addition' => _addition(difficulty, index),
      'subtraction' => _subtraction(difficulty, index),
      'multiplication' => _multiplication(difficulty, index),
      'division' => _division(difficulty, index),
      'fractions' => _fractions(difficulty, index),
      'word_problems' => _wordProblem(difficulty, index),
      'chart_reading' || 'table_reading' => _table(difficulty, index, category),
      'tally' => _tally(difficulty, index),
      _ => _addition(difficulty, index),
    };
  }

  int _maxFor(SkillTier d) => switch (d) {
        SkillTier.easy => 10,
        SkillTier.medium => 20,
        SkillTier.hard => 50,
      };

  List<String> _choicesAround(int correct, {int count = 4}) {
    final set = <int>{correct};
    while (set.length < count) {
      final delta = _rng.nextInt(5) + 1;
      set.add(_rng.nextBool() ? correct + delta : (correct - delta).clamp(0, 999));
    }
    final list = set.map((e) => '$e').toList()..shuffle(_rng);
    return list;
  }

  EducationQuestion _numberRecognition(
    SkillTier d,
    int index,
    String category,
  ) {
    final n = _rng.nextInt(_maxFor(d)) + 1;
    return EducationQuestion(
      id: 'math-$category-$index-$n',
      category: category,
      skill: SkillArea.mathematics,
      difficulty: d,
      instruction: 'Doğru sayıyı seç.',
      questionText: 'Hangisi $n?',
      choices: _choicesAround(n),
      correctAnswer: '$n',
      explanation: 'Doğru sayı $n.',
      metadata: const {'type': 'multipleChoice'},
    );
  }

  EducationQuestion _numberOrdering(SkillTier d, int index) {
    final start = _rng.nextInt(_maxFor(d) - 3) + 1;
    final nums = [start, start + 1, start + 2];
    if (d != SkillTier.easy) nums.add(start + 3);
    if (d == SkillTier.hard) nums.add(start + 4);
    final shuffled = [...nums]..shuffle(_rng);
    return EducationQuestion(
      id: 'math-order-$index-$start',
      category: 'number_ordering',
      skill: SkillArea.mathematics,
      difficulty: d,
      instruction: 'Küçükten büyüğe sırala.',
      questionText: shuffled.join(' · '),
      choices: shuffled.map((e) => '$e').toList(),
      correctAnswer: nums.join(','),
      explanation: 'Doğru sıra: ${nums.join(', ')}',
      metadata: {
        'type': 'order',
        'items': shuffled.map((e) => '$e').toList(),
        'correctOrder': nums.map((e) => '$e').toList(),
      },
    );
  }

  EducationQuestion _rhythmic(SkillTier d, int index) {
    final step = switch (d) {
      SkillTier.easy => 2,
      SkillTier.medium => _rng.nextBool() ? 2 : 5,
      SkillTier.hard => [2, 5, 10][_rng.nextInt(3)],
    };
    final start = step;
    final seq = [start, start + step, start + 2 * step, start + 3 * step];
    final missing = start + 2 * step;
    final shown = seq.map((e) => e == missing ? '?' : '$e').join(' - ');
    return EducationQuestion(
      id: 'math-rhythm-$index-$step',
      category: 'rhythmic_counting',
      skill: SkillArea.mathematics,
      difficulty: d,
      instruction: '$step’şer ritmik say.',
      questionText: shown,
      choices: _choicesAround(missing),
      correctAnswer: '$missing',
      explanation: '$step’şer sayınca eksik sayı $missing olur.',
      metadata: const {'type': 'multipleChoice'},
    );
  }

  EducationQuestion _fillBlank(SkillTier d, int index) {
    final start = _rng.nextInt(15) + 1;
    final holes = switch (d) {
      SkillTier.easy => 1,
      SkillTier.medium => 2,
      SkillTier.hard => 3,
    };
    final values = List.generate(5, (i) => start + i);
    final holeIndexes = <int>{};
    while (holeIndexes.length < holes) {
      holeIndexes.add(_rng.nextInt(values.length));
    }
    final firstHole = holeIndexes.reduce((a, b) => a < b ? a : b);
    final text = [
      for (var i = 0; i < values.length; i++)
        holeIndexes.contains(i) ? '?' : '${values[i]}',
    ].join(' - ');
    final ans = values[firstHole];
    return EducationQuestion(
      id: 'math-fill-$index-$start',
      category: 'fill_blank',
      skill: SkillArea.mathematics,
      difficulty: d,
      instruction: 'İlk boşluğa gelecek sayıyı seç.',
      questionText: text,
      choices: _choicesAround(ans),
      correctAnswer: '$ans',
      explanation: 'Dizi: ${values.join(', ')}',
      metadata: {
        'type': 'multipleChoice',
        'sequence': values,
        'holes': holeIndexes.toList(),
      },
    );
  }

  EducationQuestion _addition(SkillTier d, int index) {
    final a = switch (d) {
      SkillTier.easy => 1 + (index % 5),
      SkillTier.medium => 2 + (index % 5),
      SkillTier.hard => 3 + (index % 6),
    };
    final b = switch (d) {
      SkillTier.easy => 1 + ((index * 3) % 5),
      SkillTier.medium => 1 + ((index * 2) % 4),
      SkillTier.hard => 2 + ((index * 3) % 5),
    };
    final story = SceneVisualSpec.mathAddStory(index: index, a: a, b: b);
    final sum = a + b;
    final distractorNote = d == SkillTier.hard
        ? '\n(${story.spec.character} ${8 + index % 5} yaşında — bu bilgi gerekmez.)'
        : '';
    return EducationQuestion(
      id: 'math-add-${d.name}-$index-$a-$b',
      category: 'addition',
      skill: SkillArea.mathematics,
      difficulty: d,
      instruction: d == SkillTier.hard
          ? 'Gerekli bilgiyi bul ve çöz.'
          : d == SkillTier.easy
              ? 'Görsele bak, toplamı bul.'
              : 'Problemi oku ve görsele bak.',
      questionText: '${story.text}$distractorNote',
      imageUrl: 'mock://math/addition/${story.spec.template}',
      solutionImageUrl:
          'mock://math/addition/${story.spec.template}/solution',
      choices: _choicesAround(sum),
      correctAnswer: '$sum',
      explanation: story.explanation,
      metadata: {
        'type': 'multipleChoice',
        'a': a,
        'b': b,
        'sceneVisual': story.spec.toMap(),
        if (d == SkillTier.hard) 'twoStep': true,
      },
    );
  }

  EducationQuestion _subtraction(SkillTier d, int index) {
    final start = switch (d) {
      SkillTier.easy => 3 + (index % 6),
      SkillTier.medium => 6 + (index % 6),
      SkillTier.hard => 8 + (index % 8),
    };
    final take = switch (d) {
      SkillTier.easy => 1 + (index % (start - 1).clamp(1, 3)),
      SkillTier.medium => 1 + ((index * 2) % 4),
      SkillTier.hard => 2 + ((index * 3) % 4),
    }.clamp(1, start - 1);
    final story =
        SceneVisualSpec.mathSubStory(index: index, start: start, take: take);
    final diff = start - take;
    final distractor = d == SkillTier.hard
        ? '\n(${story.spec.character} ${9 + index % 4} yaşında — gerekmez.)'
        : '';
    return EducationQuestion(
      id: 'math-sub-${d.name}-$index-$start-$take',
      category: 'subtraction',
      skill: SkillArea.mathematics,
      difficulty: d,
      instruction: d == SkillTier.hard
          ? 'Gerekli bilgiyi bul ve çöz.'
          : 'Problemi oku ve görsele bak.',
      questionText: '${story.text}$distractor',
      imageUrl: 'mock://math/subtraction/${story.spec.template}',
      solutionImageUrl:
          'mock://math/subtraction/${story.spec.template}/solution',
      choices: _choicesAround(diff),
      correctAnswer: '$diff',
      explanation: story.explanation,
      metadata: {
        'type': 'multipleChoice',
        'a': start,
        'b': take,
        'sceneVisual': story.spec.toMap(),
        if (d == SkillTier.hard) 'twoStep': true,
      },
    );
  }

  EducationQuestion _multiplication(SkillTier d, int index) {
    return switch (d) {
      SkillTier.easy => () {
          final groups = _rng.nextInt(3) + 2; // 2–4
          final each = _rng.nextInt(3) + 2; // 2–4
          final p = groups * each;
          final visual = List.generate(groups, (_) => '●' * each).join('  ');
          return EducationQuestion(
            id: 'math-mul-e-$index-$groups-$each',
            category: 'multiplication',
            skill: SkillArea.mathematics,
            difficulty: d,
            instruction: 'Grupları say, toplamı bul.',
            questionText: '$visual\n\n$groups grup × $each = ?',
            choices: _choicesAround(p),
            correctAnswer: '$p',
            explanation: '$groups × $each = $p',
            metadata: {
              'type': 'multipleChoice',
              'operationType': 'multiply',
              'a': groups,
              'b': each,
              'visualDots': true,
            },
          );
        }(),
      SkillTier.medium => () {
          final plates = _rng.nextInt(3) + 2;
          final each = _rng.nextInt(4) + 2;
          final p = plates * each;
          return EducationQuestion(
            id: 'math-mul-m-$index-$plates-$each',
            category: 'multiplication',
            skill: SkillArea.mathematics,
            difficulty: d,
            instruction: 'Problemi oku ve çöz.',
            questionText:
                '$plates tabakta, her tabakta $each elma var.\n'
                'Toplam kaç elma var?',
            choices: _choicesAround(p),
            correctAnswer: '$p',
            explanation: '$plates × $each = $p',
            metadata: {
              'type': 'multipleChoice',
              'operationType': 'multiply',
              'a': plates,
              'b': each,
              'scene': ['tabak', 'elma'],
            },
          );
        }(),
      SkillTier.hard => () {
          final a = _rng.nextInt(8) + 3;
          final b = _rng.nextInt(8) + 3;
          final p = a * b;
          final age = _rng.nextInt(4) + 8;
          return EducationQuestion(
            id: 'math-mul-h-$index-$a-$b',
            category: 'multiplication',
            skill: SkillArea.mathematics,
            difficulty: d,
            instruction: 'Gerekli bilgiyi bul ve çöz.',
            questionText:
                'Deniz $age yaşında.\n'
                'Sınıfta $a sıra var. Her sırada $b öğrenci oturuyor.\n'
                'Sınıfta kaç öğrenci var?',
            choices: _choicesAround(p),
            correctAnswer: '$p',
            explanation: 'Yaş gerekmez. $a × $b = $p',
            metadata: {
              'type': 'multipleChoice',
              'operationType': 'multiply',
              'a': a,
              'b': b,
              'twoStep': true,
            },
          );
        }(),
    };
  }

  EducationQuestion _division(SkillTier d, int index) {
    return switch (d) {
      SkillTier.easy => () {
          final groups = _rng.nextInt(3) + 2;
          final each = _rng.nextInt(3) + 2;
          final total = groups * each;
          final visual = '●' * total;
          return EducationQuestion(
            id: 'math-div-e-$index-$total-$groups',
            category: 'division',
            skill: SkillArea.mathematics,
            difficulty: d,
            instruction: 'Eşit gruplara böl.',
            questionText:
                '$visual\n\n'
                '$total nesneyi $groups eşit gruba böl.\n'
                'Her grupta kaç tane olur?',
            choices: _choicesAround(each),
            correctAnswer: '$each',
            explanation: '$total ÷ $groups = $each',
            metadata: {
              'type': 'multipleChoice',
              'operationType': 'divide',
              'a': total,
              'b': groups,
              'visualDots': true,
            },
          );
        }(),
      SkillTier.medium => () {
          final friends = _rng.nextInt(3) + 2;
          final each = _rng.nextInt(4) + 2;
          final total = friends * each;
          return EducationQuestion(
            id: 'math-div-m-$index-$total-$friends',
            category: 'division',
            skill: SkillArea.mathematics,
            difficulty: d,
            instruction: 'Problemi oku ve çöz.',
            questionText:
                '$total şeker, $friends arkadaşa eşit paylaşılacak.\n'
                'Her arkadaşa kaç şeker düşer?',
            choices: _choicesAround(each),
            correctAnswer: '$each',
            explanation: '$total ÷ $friends = $each',
            metadata: {
              'type': 'multipleChoice',
              'operationType': 'divide',
              'a': total,
              'b': friends,
              'scene': ['şeker', 'arkadaş'],
            },
          );
        }(),
      SkillTier.hard => () {
          final b = _rng.nextInt(8) + 2;
          final q = _rng.nextInt(8) + 2;
          final a = b * q;
          final color = _rng.nextBool() ? 'mavi' : 'kırmızı';
          return EducationQuestion(
            id: 'math-div-h-$index-$a-$b',
            category: 'division',
            skill: SkillArea.mathematics,
            difficulty: d,
            instruction: 'Gerekli bilgiyi bul ve çöz.',
            questionText:
                'Kutuda $a kalem var. Kutunun rengi $color.\n'
                'Kalemler $b kişilik gruplara ayrılacak.\n'
                'Kaç grup olur?',
            choices: _choicesAround(q),
            correctAnswer: '$q',
            explanation: 'Renk gerekmez. $a ÷ $b = $q',
            metadata: {
              'type': 'multipleChoice',
              'operationType': 'divide',
              'a': a,
              'b': b,
              'twoStep': true,
            },
          );
        }(),
    };
  }

  /// Temel kesir: yarım / çeyrek / bir bütünün parçası.
  EducationQuestion _fractions(SkillTier d, int index) {
    return switch (d) {
      SkillTier.easy => () {
          const configs = <(int whole, int shaded, String answer, List<String> choices)>[
            (2, 1, '1/2', ['1/2', '1/4', '1/3', '2/2']),
            (4, 1, '1/4', ['1/4', '1/2', '1/3', '2/4']),
            (4, 2, '1/2', ['1/2', '1/4', '3/4', '2/2']),
            (4, 3, '3/4', ['3/4', '1/4', '1/2', '2/4']),
            (3, 1, '1/3', ['1/3', '1/2', '2/3', '1/4']),
            (3, 2, '2/3', ['2/3', '1/3', '1/2', '3/3']),
            (6, 1, '1/6', ['1/6', '1/2', '1/3', '2/6']),
            (6, 3, '1/2', ['1/2', '1/3', '1/6', '3/6']),
            (8, 2, '1/4', ['1/4', '1/2', '1/8', '2/8']),
            (8, 4, '1/2', ['1/2', '1/4', '1/8', '4/8']),
          ];
          final c = configs[index % configs.length];
          final parts = List.generate(
            c.$1,
            (i) => i < c.$2 ? '■' : '□',
          ).join(' ');
          return EducationQuestion(
            id: 'math-frac-e-${c.$1}-${c.$2}-${c.$3}',
            category: 'fractions',
            skill: SkillArea.mathematics,
            difficulty: d,
            instruction: 'Boyalı kısmı bul.',
            questionText: '$parts\n\nBoyalı kısım hangi kesir?',
            choices: c.$4,
            correctAnswer: c.$3,
            explanation: '${c.$2} / ${c.$1} = ${c.$3}',
            metadata: {
              'type': 'multipleChoice',
              'operationType': 'fraction_basic',
              'numerator': c.$2,
              'denominator': c.$1,
              'whole': c.$1,
              'shaded': c.$2,
            },
          );
        }(),
      SkillTier.medium => () {
          const totals = [4, 6, 8, 10, 12, 14, 16, 18, 20, 24];
          final total = totals[index % totals.length];
          final half = total ~/ 2;
          return EducationQuestion(
            id: 'math-frac-m-$total',
            category: 'fractions',
            skill: SkillArea.mathematics,
            difficulty: d,
            instruction: 'Yarısını bul.',
            questionText: '$total elmanın yarısı kaçtır?',
            choices: _choicesAround(half),
            correctAnswer: '$half',
            explanation: '$total ÷ 2 = $half (1/2)',
            metadata: {
              'type': 'multipleChoice',
              'operationType': 'fraction_basic',
              'numerator': 1,
              'denominator': 2,
              'whole': total,
              'a': total,
              'b': 2,
            },
          );
        }(),
      SkillTier.hard => () {
          const configs = <(int total, int parts, String label)>[
            (4, 4, 'çeyrek'),
            (8, 4, 'çeyrek'),
            (12, 4, 'çeyrek'),
            (16, 4, 'çeyrek'),
            (6, 3, 'üçte bir'),
            (9, 3, 'üçte bir'),
            (12, 3, 'üçte bir'),
            (15, 3, 'üçte bir'),
            (10, 5, 'beşte bir'),
            (20, 5, 'beşte bir'),
          ];
          final c = configs[index % configs.length];
          final piece = c.$1 ~/ c.$2;
          final age = 7 + (index % 4);
          return EducationQuestion(
            id: 'math-frac-h-${c.$1}-${c.$2}',
            category: 'fractions',
            skill: SkillArea.mathematics,
            difficulty: d,
            instruction: 'Gerekli bilgiyi bul ve çöz.',
            questionText:
                'Ayşe $age yaşında.\n'
                'Sepette ${c.$1} çilek var. Ayşe ${c.$3}ini yiyor.\n'
                'Ayşe kaç çilek yedi?',
            choices: _choicesAround(piece),
            correctAnswer: '$piece',
            explanation: 'Yaş gerekmez. ${c.$1} ÷ ${c.$2} = $piece',
            metadata: {
              'type': 'multipleChoice',
              'operationType': 'fraction_basic',
              'numerator': 1,
              'denominator': c.$2,
              'whole': c.$1,
              'twoStep': true,
            },
          );
        }(),
    };
  }

  EducationQuestion _wordProblem(SkillTier d, int index) {
    final a = 2 + (index % 5);
    final b = 1 + ((index * 2) % 4);
    final story = SceneVisualSpec.mathAddStory(index: index, a: a, b: b);
    final sum = a + b;
    final distractor = d == SkillTier.hard
        ? '\n(${story.spec.character} ${7 + index % 6} yaşında — gerekmez.)'
        : '';
    return EducationQuestion(
      id: 'math-wp-${d.name}-$index-$a-$b',
      category: 'word_problems',
      skill: SkillArea.mathematics,
      difficulty: d,
      instruction: d == SkillTier.hard
          ? 'Gerekli bilgiyi bul ve çöz.'
          : 'Problemi oku ve görsele bak.',
      questionText: '${story.text}$distractor',
      imageUrl: 'mock://math/wp/${story.spec.template}',
      solutionImageUrl: 'mock://math/wp/${story.spec.template}/solution',
      choices: _choicesAround(sum),
      correctAnswer: '$sum',
      explanation: story.explanation,
      metadata: {
        'type': 'multipleChoice',
        'a': a,
        'b': b,
        'sceneVisual': story.spec.toMap(),
        if (d == SkillTier.hard) 'twoStep': true,
      },
    );
  }

  EducationQuestion _table(SkillTier d, int index, String category) {
    const names = ['Ayşe', 'Mehmet', 'Merve', 'Aslı'];
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum'];
    final matrix = <List<bool>>[
      [true, false, false, false, false],
      [true, true, true, true, true],
      [false, true, false, true, false],
      [true, false, true, false, true],
    ];
    final counts = matrix.map((r) => r.where((e) => e).length).toList();
    final maxIdx = counts.indexOf(counts.reduce((a, b) => a > b ? a : b));
    final minIdx = counts.indexOf(counts.reduce((a, b) => a < b ? a : b));

    if (d == SkillTier.easy || index % 3 == 0) {
      return EducationQuestion(
        id: 'math-table-max-$index',
        category: category,
        skill: SkillArea.mathematics,
        difficulty: d,
        instruction: 'Tabloya bak.',
        questionText: 'En fazla işaretlenen kim?',
        choices: names,
        correctAnswer: names[maxIdx],
        explanation: '${names[maxIdx]} en fazla işarete sahip.',
        metadata: {
          'type': 'table',
          'headers': days,
          'rows': [
            for (var i = 0; i < names.length; i++)
              {'label': names[i], 'cells': matrix[i]},
          ],
        },
      );
    }
    if (d == SkillTier.hard && index % 3 == 1) {
      return EducationQuestion(
        id: 'math-table-daily-$index',
        category: category,
        skill: SkillArea.mathematics,
        difficulty: d,
        instruction: 'Tabloya bak.',
        questionText: 'Her gün okuyan kim?',
        choices: names,
        correctAnswer: 'Mehmet',
        explanation: 'Mehmet her gün işaretlenmiş.',
        metadata: {
          'type': 'table',
          'headers': days,
          'rows': [
            for (var i = 0; i < names.length; i++)
              {'label': names[i], 'cells': matrix[i]},
          ],
        },
      );
    }
    return EducationQuestion(
      id: 'math-table-min-$index',
      category: category,
      skill: SkillArea.mathematics,
      difficulty: d,
      instruction: 'Tabloya bak.',
      questionText: 'En az işaretlenen kim?',
      choices: names,
      correctAnswer: names[minIdx],
      explanation: '${names[minIdx]} en az işarete sahip.',
      metadata: {
        'type': 'table',
        'headers': days,
        'rows': [
          for (var i = 0; i < names.length; i++)
            {'label': names[i], 'cells': matrix[i]},
        ],
      },
    );
  }

  EducationQuestion _tally(SkillTier d, int index) {
    final n = switch (d) {
      SkillTier.easy => _rng.nextInt(5) + 1,
      SkillTier.medium => _rng.nextInt(8) + 3,
      SkillTier.hard => _rng.nextInt(12) + 5,
    };
    final groups = n ~/ 5;
    final rem = n % 5;
    final tally = '${'卌 ' * groups}${'|' * rem}'.trim();
    return EducationQuestion(
      id: 'math-tally-$index-$n',
      category: 'tally',
      skill: SkillArea.mathematics,
      difficulty: d,
      instruction: 'Çeteleyi say.',
      questionText: tally.isEmpty ? '|' : tally,
      choices: _choicesAround(n),
      correctAnswer: '$n',
      explanation: 'Toplam $n.',
      metadata: {'type': 'multipleChoice', 'tallyCount': n},
    );
  }
}
