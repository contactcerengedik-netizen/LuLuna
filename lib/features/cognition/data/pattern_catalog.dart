import 'dart:math';

import '../../../data/models/pattern_question.dart';
import '../../../data/models/sequence_question.dart';
import '../../../data/models/skill_level.dart';

/// Örüntü / mantık / olay sıralama örnekleri.
abstract final class PatternCatalog {
  static PatternQuestion patternFor(SkillTier tier, {int index = 0}) {
    final pool = switch (tier) {
      SkillTier.easy => _easyComplete,
      SkillTier.medium => _mediumComplete,
      SkillTier.hard => _hardComplete,
    };
    return pool[index % pool.length];
  }

  static PatternQuestion oddOneOut({int index = 0}) =>
      _oddOnes[index % _oddOnes.length];

  static SequenceQuestion eventOrder({Random? random, int index = 0}) {
    final events = _events[index % _events.length];
    return SequenceQuestion.shuffled(events, random: random ?? Random(42));
  }

  static const _easyComplete = <PatternQuestion>[
    PatternQuestion(
      id: 'pat-ab-1',
      instruction: 'Sıradaki nedir?',
      pattern: ['Kırmızı', 'Mavi', 'Kırmızı', 'Mavi', 'Kırmızı', 'Mavi'],
      missingIndex: 5,
      choices: ['Kırmızı', 'Mavi', 'Yeşil', 'Sarı'],
    ),
    PatternQuestion(
      id: 'pat-shape-1',
      instruction: 'Sıradaki şekil?',
      pattern: ['●', '■', '●', '■', '●', '■'],
      missingIndex: 5,
      choices: ['●', '■', '▲', '◆'],
    ),
  ];

  static const _mediumComplete = <PatternQuestion>[
    PatternQuestion(
      id: 'pat-abc-1',
      instruction: 'Eksik olanı bul.',
      pattern: ['A', 'B', 'C', 'A', 'B', 'C'],
      missingIndex: 4,
      choices: ['A', 'B', 'C', 'D'],
    ),
    PatternQuestion(
      id: 'pat-num-1',
      instruction: 'Eksik sayı?',
      pattern: ['2', '4', '6', '8', '10', '12'],
      missingIndex: 3,
      choices: ['7', '8', '9', '10'],
    ),
  ];

  static const _hardComplete = <PatternQuestion>[
    PatternQuestion(
      id: 'pat-grow-1',
      instruction: 'Örüntüyü tamamla.',
      pattern: ['1', '2', '4', '8', '16', '32'],
      missingIndex: 4,
      choices: ['12', '14', '16', '18'],
    ),
    PatternQuestion(
      id: 'pat-mix-1',
      instruction: 'Eksik parça?',
      pattern: ['●', '●', '■', '●', '●', '■'],
      missingIndex: 5,
      choices: ['●', '■', '▲', '◆'],
    ),
  ];

  static const _oddOnes = <PatternQuestion>[
    PatternQuestion(
      id: 'odd-1',
      instruction: 'Farklı olanı seç.',
      kind: PatternKind.oddOneOut,
      pattern: ['Elma', 'Armut', 'Muz', 'Araba'],
      missingIndex: 3,
      choices: ['Elma', 'Armut', 'Muz', 'Araba'],
    ),
    PatternQuestion(
      id: 'odd-2',
      instruction: 'Farklı olanı seç.',
      kind: PatternKind.oddOneOut,
      pattern: ['Kedi', 'Köpek', 'Kuş', 'Masa'],
      missingIndex: 3,
      choices: ['Kedi', 'Köpek', 'Kuş', 'Masa'],
    ),
  ];

  static const _events = <List<String>>[
    ['Tohum', 'Filiz', 'Ağaç'],
    ['Yumurta', 'Civciv', 'Tavuk'],
    ['Sabah', 'Öğle', 'Akşam'],
  ];
}
