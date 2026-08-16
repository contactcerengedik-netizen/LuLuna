import '../../../data/models/categorization_question.dart';
import '../../../data/models/skill_level.dart';

/// Örnek sınıflandırma setleri — easy görsel, hard kavramsal.
abstract final class CategorizationCatalog {
  static CategorizationQuestion forTier(SkillTier tier, {int index = 0}) {
    return switch (tier) {
      SkillTier.easy => _visual[index % _visual.length],
      SkillTier.medium => _mixed[index % _mixed.length],
      SkillTier.hard => _conceptual[index % _conceptual.length],
    };
  }

  static const _visual = <CategorizationQuestion>[
    CategorizationQuestion(
      id: 'cat-color-1',
      instruction: 'Aynı renkte olanları grupla.',
      level: 'easy',
      categories: ['Kırmızı', 'Mavi'],
      items: [
        CategorizationItem(
          id: 'r1',
          label: 'Elma',
          iconName: 'apple',
          tintArgb: 0xFFE53935,
        ),
        CategorizationItem(
          id: 'r2',
          label: 'Kalp',
          iconName: 'favorite',
          tintArgb: 0xFFE53935,
        ),
        CategorizationItem(
          id: 'b1',
          label: 'Gökyüzü',
          iconName: 'cloud',
          tintArgb: 0xFF1E88E5,
        ),
        CategorizationItem(
          id: 'b2',
          label: 'Balık',
          iconName: 'water',
          tintArgb: 0xFF1E88E5,
        ),
      ],
      correctMapping: {
        'r1': 'Kırmızı',
        'r2': 'Kırmızı',
        'b1': 'Mavi',
        'b2': 'Mavi',
      },
    ),
    CategorizationQuestion(
      id: 'cat-shape-1',
      instruction: 'Şekline göre grupla.',
      level: 'easy',
      categories: ['Yuvarlak', 'Köşeli'],
      items: [
        CategorizationItem(id: 'c1', label: 'Top', iconName: 'circle'),
        CategorizationItem(id: 'c2', label: 'Güneş', iconName: 'wb_sunny'),
        CategorizationItem(id: 's1', label: 'Kutu', iconName: 'crop_square'),
        CategorizationItem(id: 's2', label: 'Kitap', iconName: 'menu_book'),
      ],
      correctMapping: {
        'c1': 'Yuvarlak',
        'c2': 'Yuvarlak',
        's1': 'Köşeli',
        's2': 'Köşeli',
      },
    ),
  ];

  static const _mixed = <CategorizationQuestion>[
    CategorizationQuestion(
      id: 'cat-size-1',
      instruction: 'Büyüklüğüne göre ayır.',
      level: 'medium',
      categories: ['Büyük', 'Küçük'],
      items: [
        CategorizationItem(id: 'big1', label: 'Fil', iconName: 'pets'),
        CategorizationItem(id: 'big2', label: 'Otobüs', iconName: 'directions_bus'),
        CategorizationItem(id: 'sm1', label: 'Karınca', iconName: 'bug_report'),
        CategorizationItem(id: 'sm2', label: 'Düğme', iconName: 'radio_button_checked'),
      ],
      correctMapping: {
        'big1': 'Büyük',
        'big2': 'Büyük',
        'sm1': 'Küçük',
        'sm2': 'Küçük',
      },
    ),
  ];

  static const _conceptual = <CategorizationQuestion>[
    CategorizationQuestion(
      id: 'cat-edible-1',
      instruction: 'Yenebilenleri ayır.',
      level: 'hard',
      categories: ['Yenebilir', 'Yenmez'],
      items: [
        CategorizationItem(id: 'e1', label: 'Elma', iconName: 'apple'),
        CategorizationItem(id: 'e2', label: 'Ekmek', iconName: 'bakery_dining'),
        CategorizationItem(id: 'n1', label: 'Taş', iconName: 'landscape'),
        CategorizationItem(id: 'n2', label: 'Kalem', iconName: 'edit'),
      ],
      correctMapping: {
        'e1': 'Yenebilir',
        'e2': 'Yenebilir',
        'n1': 'Yenmez',
        'n2': 'Yenmez',
      },
    ),
    CategorizationQuestion(
      id: 'cat-use-1',
      instruction: 'Nerede kullanılır?',
      level: 'hard',
      categories: ['Okul', 'Mutfak'],
      items: [
        CategorizationItem(id: 'o1', label: 'Defter', iconName: 'menu_book'),
        CategorizationItem(id: 'o2', label: 'Silgi', iconName: 'auto_fix_high'),
        CategorizationItem(id: 'k1', label: 'Tencere', iconName: 'soup_kitchen'),
        CategorizationItem(id: 'k2', label: 'Tabak', iconName: 'dinner_dining'),
      ],
      correctMapping: {
        'o1': 'Okul',
        'o2': 'Okul',
        'k1': 'Mutfak',
        'k2': 'Mutfak',
      },
    ),
  ];
}
