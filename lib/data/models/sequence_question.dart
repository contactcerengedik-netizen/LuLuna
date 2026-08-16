import 'dart:math';

/// Ortak sıralama sorusu (Türkçe alfabetik/kelime + ileride örüntü/olay).
/// [items]: ekranda gösterilen (karışık) parçalar.
/// [correctOrder]: her pozisyon için [items] içindeki doğru indeks.
class SequenceQuestion {
  const SequenceQuestion({
    required this.items,
    required this.correctOrder,
  }) : assert(items.length == correctOrder.length);

  final List<String> items;
  final List<int> correctOrder;

  List<String> get correctItems => [
        for (final i in correctOrder) items[i],
      ];

  bool isCorrectSequence(List<String> given) {
    if (given.length != correctOrder.length) return false;
    for (var i = 0; i < correctOrder.length; i++) {
      if (given[i] != items[correctOrder[i]]) return false;
    }
    return true;
  }

  static String encode(List<String> ordered) => ordered.join(',');

  static List<String> decode(String answer) =>
      answer.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Map<String, dynamic> toMap() => {
        'type': 'sequence',
        'items': items,
        'correctOrder': correctOrder,
      };

  factory SequenceQuestion.fromMap(Map<String, dynamic> map) {
    return SequenceQuestion(
      items: [for (final e in (map['items'] as List? ?? const [])) '$e'],
      correctOrder: [
        for (final e in (map['correctOrder'] as List? ?? const []))
          e is int ? e : int.tryParse('$e') ?? 0,
      ],
    );
  }

  factory SequenceQuestion.shuffled(
    List<String> canonical, {
    Random? random,
  }) {
    final rng = random ?? Random();
    final n = canonical.length;
    final perm = List<int>.generate(n, (i) => i)..shuffle(rng);
    final items = [for (final i in perm) canonical[i]];
    final correctOrder = [
      for (var p = 0; p < n; p++) perm.indexOf(p),
    ];
    return SequenceQuestion(items: items, correctOrder: correctOrder);
  }
}
