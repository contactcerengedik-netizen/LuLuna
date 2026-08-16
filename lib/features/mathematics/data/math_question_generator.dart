import 'dart:math';

import '../../../data/models/education_question.dart';
import '../../../data/models/skill_level.dart';
import '../../education/domain/activity_engine.dart';

/// Matematik soru üretici — seviye ve kategoriye göre üretir.
class MathQuestionGenerator implements QuestionGenerator {
  MathQuestionGenerator({Random? random}) : _rng = random ?? Random(42);

  final Random _rng;

  @override
  SkillArea get skill => SkillArea.mathematics;

  @override
  List<EducationQuestion> generate({
    required String category,
    required SkillTier difficulty,
    int count = 5,
  }) {
    return List.generate(
      count,
      (i) => _one(category: category, difficulty: difficulty, index: i),
    );
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
    return switch (d) {
      SkillTier.easy => () {
          final a = _rng.nextInt(5) + 1;
          final b = _rng.nextInt(5) + 1;
          final sum = a + b;
          return EducationQuestion(
            id: 'math-add-e-$index-$a-$b',
            category: 'addition',
            skill: SkillArea.mathematics,
            difficulty: d,
            instruction: 'Toplamı bul.',
            questionText: '${'●' * a} + ${'●' * b} = ?',
            choices: _choicesAround(sum),
            correctAnswer: '$sum',
            explanation: '$a + $b = $sum',
            metadata: {
              'type': 'multipleChoice',
              'a': a,
              'b': b,
              'visualDots': true,
            },
          );
        }(),
      SkillTier.medium => () {
          final fridge = _rng.nextInt(4) + 3;
          final hand = _rng.nextInt(3) + 1;
          final sum = fridge + hand;
          return EducationQuestion(
            id: 'math-add-m-$index-$fridge-$hand',
            category: 'addition',
            skill: SkillArea.mathematics,
            difficulty: d,
            instruction: 'Problemi oku ve çöz.',
            questionText:
                'Buzdolabında $fridge yumurta var.\n'
                'Ayşe’nin elinde $hand yumurta var.\n'
                'Ayşe yumurtaları buzdolabına koyuyor.\n'
                'Kaç yumurta olur?',
            choices: _choicesAround(sum),
            correctAnswer: '$sum',
            explanation: '$fridge + $hand = $sum',
            metadata: {
              'type': 'multipleChoice',
              'a': fridge,
              'b': hand,
              'scene': ['Ayşe', 'yumurta', 'buzdolabı'],
            },
          );
        }(),
      SkillTier.hard => () {
          final age = _rng.nextInt(5) + 8;
          final years = _rng.nextInt(3) + 2;
          final books = _rng.nextInt(4) + 3;
          final more = _rng.nextInt(3) + 1;
          final sum = books + more;
          return EducationQuestion(
            id: 'math-add-h-$index-$books-$more',
            category: 'addition',
            skill: SkillArea.mathematics,
            difficulty: d,
            instruction: 'Gerekli bilgiyi bul ve çöz.',
            questionText:
                'Mehmet $age yaşında. $years yıl sonra okula başlayacak.\n'
                'Bugün rafta $books kitap var. Mehmet $more kitap daha koyuyor.\n'
                'Rafta kaç kitap olur?',
            choices: _choicesAround(sum),
            correctAnswer: '$sum',
            explanation: 'Yaş bilgisi gerekmez. $books + $more = $sum',
            metadata: {
              'type': 'multipleChoice',
              'a': books,
              'b': more,
              'twoStep': true,
            },
          );
        }(),
    };
  }

  EducationQuestion _subtraction(SkillTier d, int index) {
    return switch (d) {
      SkillTier.easy => () {
          final a = _rng.nextInt(8) + 3;
          final b = _rng.nextInt(a - 1) + 1;
          final diff = a - b;
          return EducationQuestion(
            id: 'math-sub-e-$index-$a-$b',
            category: 'subtraction',
            skill: SkillArea.mathematics,
            difficulty: d,
            instruction: 'Farkı bul.',
            questionText: '${'●' * a} − ${'●' * b} = ?',
            choices: _choicesAround(diff),
            correctAnswer: '$diff',
            explanation: '$a - $b = $diff',
            metadata: {
              'type': 'multipleChoice',
              'a': a,
              'b': b,
              'visualDots': true,
            },
          );
        }(),
      SkillTier.medium => () {
          final start = _rng.nextInt(6) + 6;
          final take = _rng.nextInt(4) + 1;
          final diff = start - take;
          return EducationQuestion(
            id: 'math-sub-m-$index-$start-$take',
            category: 'subtraction',
            skill: SkillArea.mathematics,
            difficulty: d,
            instruction: 'Problemi oku ve çöz.',
            questionText:
                'Sepette $start elma var.\n'
                'Ayşe $take elma yiyor.\n'
                'Sepette kaç elma kalır?',
            choices: _choicesAround(diff),
            correctAnswer: '$diff',
            explanation: '$start - $take = $diff',
            metadata: {'type': 'multipleChoice', 'a': start, 'b': take},
          );
        }(),
      SkillTier.hard => () {
          final age = _rng.nextInt(4) + 9;
          final start = _rng.nextInt(8) + 8;
          final give = _rng.nextInt(4) + 2;
          final diff = start - give;
          return EducationQuestion(
            id: 'math-sub-h-$index-$start-$give',
            category: 'subtraction',
            skill: SkillArea.mathematics,
            difficulty: d,
            instruction: 'Gerekli bilgiyi bul ve çöz.',
            questionText:
                'Zeynep $age yaşında ve mavi bir çanta taşıyor.\n'
                'Rafta $start kalem vardı. Zeynep $give kalem aldı.\n'
                'Rafta kaç kalem kaldı?',
            choices: _choicesAround(diff),
            correctAnswer: '$diff',
            explanation: 'Yaş/çanta gerekmez. $start - $give = $diff',
            metadata: {
              'type': 'multipleChoice',
              'a': start,
              'b': give,
              'twoStep': true,
            },
          );
        }(),
    };
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
          // Görsel: 4 dilimden 2'si boyalı → 1/2
          final whole = [2, 4][index % 2];
          final shaded = whole ~/ 2;
          final parts = List.generate(
            whole,
            (i) => i < shaded ? '■' : '□',
          ).join(' ');
          return EducationQuestion(
            id: 'math-frac-e-$index-$whole',
            category: 'fractions',
            skill: SkillArea.mathematics,
            difficulty: d,
            instruction: 'Boyalı kısmı bul.',
            questionText: '$parts\n\nBoyalı kısım hangi kesir?',
            choices: const ['1/2', '1/4', '1/3', '2/2'],
            correctAnswer: '1/2',
            explanation: '$shaded / $whole = 1/2',
            metadata: {
              'type': 'multipleChoice',
              'operationType': 'fraction_basic',
              'numerator': 1,
              'denominator': 2,
              'whole': whole,
              'shaded': shaded,
            },
          );
        }(),
      SkillTier.medium => () {
          final total = [4, 6, 8, 10][_rng.nextInt(4)];
          final half = total ~/ 2;
          return EducationQuestion(
            id: 'math-frac-m-$index-$total',
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
          // Çeyrek veya 1/4 of set
          final total = [4, 8, 12][_rng.nextInt(3)];
          final quarter = total ~/ 4;
          final age = _rng.nextInt(3) + 7;
          return EducationQuestion(
            id: 'math-frac-h-$index-$total',
            category: 'fractions',
            skill: SkillArea.mathematics,
            difficulty: d,
            instruction: 'Gerekli bilgiyi bul ve çöz.',
            questionText:
                'Ayşe $age yaşında.\n'
                'Sepette $total çilek var. Ayşe çeyreğini yiyor.\n'
                'Ayşe kaç çilek yedi?',
            choices: _choicesAround(quarter),
            correctAnswer: '$quarter',
            explanation: 'Yaş gerekmez. $total × 1/4 = $quarter',
            metadata: {
              'type': 'multipleChoice',
              'operationType': 'fraction_basic',
              'numerator': 1,
              'denominator': 4,
              'whole': total,
              'twoStep': true,
            },
          );
        }(),
    };
  }

  EducationQuestion _wordProblem(SkillTier d, int index) {
    return switch (d) {
      SkillTier.easy => () {
          final a = _rng.nextInt(5) + 2;
          final b = _rng.nextInt(4) + 1;
          return EducationQuestion(
            id: 'math-wp-e-$index',
            category: 'word_problems',
            skill: SkillArea.mathematics,
            difficulty: d,
            instruction: 'Problemi çöz.',
            questionText: 'Sepette $a elma var. $b elma daha konuyor. '
                'Kaç elma olur?',
            choices: _choicesAround(a + b),
            correctAnswer: '${a + b}',
            explanation: '$a + $b = ${a + b}',
            metadata: const {'type': 'multipleChoice'},
          );
        }(),
      SkillTier.medium => () {
          const fridge = 5;
          const hand = 3;
          return EducationQuestion(
            id: 'math-wp-m-$index',
            category: 'word_problems',
            skill: SkillArea.mathematics,
            difficulty: d,
            instruction: 'Problemi oku ve çöz.',
            questionText:
                'Buzdolabında $fridge yumurta var.\n'
                'Ayşe’nin elinde $hand yumurta var.\n'
                'Ayşe yumurtaları buzdolabına koyuyor.\n'
                'Kaç yumurta olur?',
            choices: _choicesAround(fridge + hand),
            correctAnswer: '${fridge + hand}',
            explanation: '$fridge + $hand = ${fridge + hand}',
            metadata: {
              'type': 'multipleChoice',
              'scene': ['Ayşe', 'yumurta', 'buzdolabı'],
            },
          );
        }(),
      SkillTier.hard => () {
          final age = _rng.nextInt(5) + 8;
          final years = _rng.nextInt(3) + 2;
          final books = _rng.nextInt(4) + 3;
          final more = _rng.nextInt(3) + 1;
          return EducationQuestion(
            id: 'math-wp-h-$index',
            category: 'word_problems',
            skill: SkillArea.mathematics,
            difficulty: d,
            instruction: 'Gerekli bilgiyi bul ve çöz.',
            questionText:
                'Mehmet $age yaşında. $years yıl sonra okula başlayacak.\n'
                'Bugün rafta $books kitap var. Mehmet $more kitap daha koyuyor.\n'
                'Rafta kaç kitap olur?',
            choices: _choicesAround(books + more),
            correctAnswer: '${books + more}',
            explanation:
                'Yaş bilgisi gerekmez. $books + $more = ${books + more}',
            metadata: const {'type': 'multipleChoice', 'twoStep': true},
          );
        }(),
    };
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
