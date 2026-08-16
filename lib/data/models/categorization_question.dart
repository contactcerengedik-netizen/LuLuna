/// Eşleştirme / sınıflandırma sorusu (v3 Faz 12).
class CategorizationItem {
  const CategorizationItem({
    required this.id,
    required this.label,
    this.iconName = 'circle',
    this.tintArgb,
  });

  final String id;
  final String label;

  /// Material ikon anahtarı (UI map eder).
  final String iconName;

  /// Görsel benzerlik seviyesi için renk ipucu.
  final int? tintArgb;

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'iconName': iconName,
        'tintArgb': tintArgb,
      };

  factory CategorizationItem.fromMap(Map<String, dynamic> map) {
    return CategorizationItem(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
      iconName: map['iconName'] as String? ?? 'circle',
      tintArgb: map['tintArgb'] as int?,
    );
  }
}

class CategorizationQuestion {
  const CategorizationQuestion({
    required this.id,
    required this.instruction,
    required this.items,
    required this.categories,
    required this.correctMapping,
    this.level = 'easy',
  });

  final String id;
  final String instruction;
  final List<CategorizationItem> items;
  final List<String> categories;

  /// itemId → category
  final Map<String, String> correctMapping;

  /// easy = görsel benzerlik; hard = kavramsal.
  final String level;

  bool isCorrect(Map<String, String> given) {
    if (given.length != correctMapping.length) return false;
    for (final e in correctMapping.entries) {
      if (given[e.key] != e.value) return false;
    }
    return true;
  }

  int score(Map<String, String> given) {
    var ok = 0;
    for (final e in correctMapping.entries) {
      if (given[e.key] == e.value) ok++;
    }
    return ok;
  }

  Map<String, dynamic> toMap() => {
        'type': 'categorization',
        'id': id,
        'instruction': instruction,
        'items': [for (final i in items) i.toMap()],
        'categories': categories,
        'correctMapping': correctMapping,
        'level': level,
      };

  factory CategorizationQuestion.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List? ?? const [];
    final rawMap = Map<String, dynamic>.from(
      map['correctMapping'] as Map? ?? const {},
    );
    return CategorizationQuestion(
      id: map['id'] as String? ?? '',
      instruction: map['instruction'] as String? ?? '',
      items: [
        for (final e in rawItems)
          CategorizationItem.fromMap(Map<String, dynamic>.from(e as Map)),
      ],
      categories: [
        for (final c in (map['categories'] as List? ?? const [])) '$c',
      ],
      correctMapping: {
        for (final e in rawMap.entries) e.key: '${e.value}',
      },
      level: map['level'] as String? ?? 'easy',
    );
  }
}
