import '../../education/domain/activity_models.dart';

/// Türkçe / dil alt kategorileri (v3 Faz 9).
abstract final class LanguageCategories {
  /// Faz 9 hub: 5N1K + kavram + eş/zıt/eşses + sıralamalar.
  static const mvp = <ActivityCategoryDef>[
    ActivityCategoryDef(
      id: 'five_w1h',
      title: '5N1K',
      description: 'Kim, ne, nerede, ne zaman, nasıl, neden',
      iconName: 'quiz',
    ),
    ActivityCategoryDef(
      id: 'concepts',
      title: 'Kavramlar',
      description: 'Büyük–küçük, uzun–kısa…',
      iconName: 'category',
    ),
    ActivityCategoryDef(
      id: 'antonyms',
      title: 'Zıt Kavramlar',
      description: 'Zıt anlamlıyı bul',
      iconName: 'compare_arrows',
    ),
    ActivityCategoryDef(
      id: 'synonyms',
      title: 'Eş Anlamlılar',
      description: 'Aynı anlamda olanı bul',
      iconName: 'sync_alt',
    ),
    ActivityCategoryDef(
      id: 'homophones',
      title: 'Eş Sesliler',
      description: 'Aynı ses, farklı anlam',
      iconName: 'record_voice_over',
    ),
    ActivityCategoryDef(
      id: 'alphabetical',
      title: 'Alfabetik Sıralama',
      description: 'Kelimeleri alfabetik sıraya koy',
      iconName: 'sort_by_alpha',
    ),
    ActivityCategoryDef(
      id: 'word_ordering',
      title: 'Kelime / Cümle Sıralama',
      description: 'Cümleyi doğru kur',
      iconName: 'reorder',
    ),
  ];

  /// Üretici kapsamı / sonraki fazlar.
  static const backlog = <ActivityCategoryDef>[
    ActivityCategoryDef(
      id: 'event_ordering',
      title: 'Olay Sıralama',
      description: 'Olayları doğru sıraya koy',
      iconName: 'view_timeline',
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
