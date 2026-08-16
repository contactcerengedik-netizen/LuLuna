import '../../education/domain/activity_models.dart';

/// Matematik alt kategorileri (v3 Faz 10: dört işlem + kesir).
abstract final class MathCategories {
  /// Hub: sayı tanıma, toplama, çıkarma, çarpma, bölme, kesir.
  static const mvp = <ActivityCategoryDef>[
    ActivityCategoryDef(
      id: 'number_recognition',
      title: 'Sayı Tanıma',
      description: 'Hangisi doğru sayı?',
      iconName: 'search',
    ),
    ActivityCategoryDef(
      id: 'addition',
      title: 'Toplama',
      description: 'Toplamı bul',
      iconName: 'add',
    ),
    ActivityCategoryDef(
      id: 'subtraction',
      title: 'Çıkarma',
      description: 'Farkı bul',
      iconName: 'remove',
    ),
    ActivityCategoryDef(
      id: 'multiplication',
      title: 'Çarpma',
      description: 'Çarpımı bul',
      iconName: 'close',
    ),
    ActivityCategoryDef(
      id: 'division',
      title: 'Bölme',
      description: 'Bölümü bul',
      iconName: 'percent',
    ),
    ActivityCategoryDef(
      id: 'fractions',
      title: 'Kesirler',
      description: 'Basit kesirleri tanı',
      iconName: 'pie_chart',
    ),
  ];

  /// Üretici kapsamı / backlog (hub’da gösterilmez).
  static const backlog = <ActivityCategoryDef>[
    ActivityCategoryDef(
      id: 'learn_numbers',
      title: 'Sayıları Öğreniyorum',
      description: 'Sayıları tanı ve söyle',
      iconName: 'looks_one',
    ),
    ActivityCategoryDef(
      id: 'learn_digits',
      title: 'Rakamları Öğreniyorum',
      description: 'Rakam şekillerini tanı',
      iconName: 'pin',
    ),
    ActivityCategoryDef(
      id: 'number_ordering',
      title: 'Sayı Sıralama',
      description: 'Küçükten büyüğe sırala',
      iconName: 'swap_vert',
    ),
    ActivityCategoryDef(
      id: 'rhythmic_counting',
      title: 'Ritmik Sayma',
      description: '2’şer, 5’er, 10’ar',
      iconName: 'repeat',
    ),
    ActivityCategoryDef(
      id: 'fill_blank',
      title: 'Boşluk Doldurma',
      description: 'Eksik sayıyı bul',
      iconName: 'more_horiz',
    ),
    ActivityCategoryDef(
      id: 'word_problems',
      title: 'Problem Çözme',
      description: 'Günlük yaşam problemleri',
      iconName: 'menu_book',
    ),
    ActivityCategoryDef(
      id: 'chart_reading',
      title: 'Grafik Okuma',
      description: 'Basit grafik soruları',
      iconName: 'bar_chart',
    ),
    ActivityCategoryDef(
      id: 'table_reading',
      title: 'Tablo Okuma',
      description: 'Tabloyu oku ve cevapla',
      iconName: 'table_chart',
    ),
    ActivityCategoryDef(
      id: 'tally',
      title: 'Çetele Tablosu',
      description: 'Çetele işaretlerini say',
      iconName: 'checklist',
    ),
  ];

  static const all = [...mvp, ...backlog];

  static ActivityCategoryDef? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}
