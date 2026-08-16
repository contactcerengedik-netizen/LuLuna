import 'skill_level.dart';

/// Beceri anahtarları — `student_skill_levels.skill_key` (prompt §6).
abstract final class SkillKeys {
  static const numberRecognition = 'sayi_tanima';
  static const addition = 'toplama';
  static const subtraction = 'cikarma';
  static const multiplication = 'carpma';
  static const division = 'bolme';
  static const fractions = 'kesir';
  static const tracing = 'cizgi';
  static const coloring = 'boyama';
  static const categorization = 'eslestirme';
  static const pattern = 'oruntu';
  static const dataReading = 'veri_okuma';
  static const memory = 'hafiza';
  static const speech = 'konusma';
  static const routine = 'rutin';
  static const aac = 'aac';
  static const fiveW1h = '5n1k';
  static const antonyms = 'zit_kavramlar';
  static const puzzle = 'puzzle';

  /// MVP’de seviye takip edilen beceriler.
  static const mvp = <String>[
    numberRecognition,
    addition,
    subtraction,
    multiplication,
    division,
    fractions,
    fiveW1h,
    antonyms,
    puzzle,
    tracing,
    coloring,
    categorization,
    pattern,
    dataReading,
    memory,
    speech,
    routine,
    aac,
  ];

  static String label(String key) => switch (key) {
        numberRecognition => 'Sayı tanıma',
        addition => 'Toplama',
        subtraction => 'Çıkarma',
        multiplication => 'Çarpma',
        division => 'Bölme',
        fractions => 'Kesirler',
        tracing => 'Çizgi / motor',
        coloring => 'Boyama',
        categorization => 'Eşleştirme',
        pattern => 'Örüntü / mantık',
        dataReading => 'Veri okuma',
        memory => 'Hafıza / dikkat',
        speech => 'Konuşma / sosyal',
        routine => 'Rutin',
        aac => 'AAC panosu',
        fiveW1h => '5N1K',
        antonyms => 'Zıt kavramlar',
        puzzle => 'Puzzle',
        _ => key,
      };

  /// Aktivite kategori id → skill_key.
  static String? fromCategory(String category) => switch (category) {
        'number_recognition' ||
        'learn_numbers' ||
        'learn_digits' =>
          numberRecognition,
        'addition' => addition,
        'subtraction' => subtraction,
        'multiplication' => multiplication,
        'division' => division,
        'fractions' => fractions,
        'five_w1h' => fiveW1h,
        'antonyms' => antonyms,
        'puzzle' => puzzle,
        'straightLine' ||
        'wavyLine' ||
        'shape' ||
        'digit' ||
        'uppercaseLetter' ||
        'lowercaseLetter' ||
        'word' ||
        'freeDraw' ||
        'connectDots' ||
        'lineFollow' ||
        'letter' ||
        'pattern' => // eski çizgi zig-zag route adı
          tracing,
        'coloring' => coloring,
        'categorization' => categorization,
        'patternComplete' || 'oddOne' || 'eventOrder' => pattern,
        'dataRead' ||
        'chart_reading' ||
        'table_reading' ||
        'tally' =>
          dataReading,
        'match' || 'flash' => memory,
        'pronunciation' || 'communication' || 'emotion' => speech,
        'routine' => routine,
        'aac' => aac,
        _ => null,
      };

  static SkillArea areaFor(String skillKey) => switch (skillKey) {
        numberRecognition ||
        addition ||
        subtraction ||
        multiplication ||
        division ||
        fractions =>
          SkillArea.mathematics,
        fiveW1h || antonyms => SkillArea.language,
        puzzle => SkillArea.puzzle,
        tracing => SkillArea.tracing,
        coloring => SkillArea.coloring,
        categorization || pattern || dataReading || memory =>
          SkillArea.visualPerception,
        speech || aac => SkillArea.communication,
        routine => SkillArea.dailyLife,
        _ => SkillArea.mathematics,
      };
}
