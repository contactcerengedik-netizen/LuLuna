enum Difficulty {
  beginner,
  easy,
  medium,
  advanced;

  String get label => switch (this) {
    Difficulty.beginner => 'Başlangıç',
    Difficulty.easy => 'Kolay',
    Difficulty.medium => 'Orta',
    Difficulty.advanced => 'İleri',
  };
}
