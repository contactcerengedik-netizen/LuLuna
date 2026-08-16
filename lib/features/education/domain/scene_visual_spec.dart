/// Soru başına eğitici sahne — AI/mock görsel üretim sözleşmesi.
class SceneVisualSpec {
  const SceneVisualSpec({
    required this.template,
    this.character,
    this.objects = const [],
    this.counts = const {},
    this.setting,
    this.action,
    this.caption,
  });

  /// fridge_eggs | park_ball | kitchen_apples | shelf_books | plate_food |
  /// beach | classroom | market | garden | bedtime | abstract_dots | fraction_bars
  final String template;
  final String? character;
  final List<String> objects;
  final Map<String, int> counts;
  final String? setting;
  final String? action;
  final String? caption;

  Map<String, dynamic> toMap() => {
        'template': template,
        if (character != null) 'character': character,
        'objects': objects,
        'counts': counts,
        if (setting != null) 'setting': setting,
        if (action != null) 'action': action,
        if (caption != null) 'caption': caption,
      };

  factory SceneVisualSpec.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return const SceneVisualSpec(template: 'abstract_dots');
    }
    final countsRaw = map['counts'];
    final counts = <String, int>{};
    if (countsRaw is Map) {
      for (final e in countsRaw.entries) {
        counts['${e.key}'] = (e.value as num?)?.toInt() ?? 0;
      }
    }
    return SceneVisualSpec(
      template: map['template'] as String? ?? 'abstract_dots',
      character: map['character'] as String?,
      objects: [
        for (final o in (map['objects'] as List? ?? const [])) '$o',
      ],
      counts: counts,
      setting: map['setting'] as String?,
      action: map['action'] as String?,
      caption: map['caption'] as String?,
    );
  }

  /// Matematik hikâye şablonları (index ile çeşitlenir).
  static ({SceneVisualSpec spec, String text, String explanation}) mathAddStory({
    required int index,
    required int a,
    required int b,
  }) {
    final sum = a + b;
    final stories = <({SceneVisualSpec spec, String text})>[
      (
        spec: SceneVisualSpec(
          template: 'fridge_eggs',
          character: 'Ayşe',
          objects: const ['yumurta', 'buzdolabı'],
          counts: {'fridge': a, 'hand': b},
          setting: 'mutfak',
          action: 'koyuyor',
          caption: 'Buzdolabı, yumurtalar ve Ayşe',
        ),
        text:
            'Buzdolabında $a yumurta var.\nAyşe’nin elinde $b yumurta var.\nAyşe yumurtaları buzdolabına koyuyor.\nKaç yumurta olur?',
      ),
      (
        spec: SceneVisualSpec(
          template: 'park_ball',
          character: 'Ali',
          objects: const ['top'],
          counts: {'ground': a, 'bag': b},
          setting: 'park',
          caption: 'Parkta toplar',
        ),
        text:
            'Parkta yerde $a top var.\nAli çantadan $b top daha çıkarıyor.\nToplam kaç top olur?',
      ),
      (
        spec: SceneVisualSpec(
          template: 'kitchen_apples',
          character: 'Zeynep',
          objects: const ['elma'],
          counts: {'basket': a, 'table': b},
          caption: 'Sepet ve masadaki elmalar',
        ),
        text:
            'Sepette $a elma var.\nMasada $b elma daha var.\nHepsi birlikte kaç elma?',
      ),
      (
        spec: SceneVisualSpec(
          template: 'shelf_books',
          character: 'Mehmet',
          objects: const ['kitap'],
          counts: {'shelf': a, 'hand': b},
          caption: 'Raftaki kitaplar',
        ),
        text:
            'Rafta $a kitap var.\nMehmet $b kitap daha koyuyor.\nRafta kaç kitap olur?',
      ),
      (
        spec: SceneVisualSpec(
          template: 'plate_food',
          character: 'Elif',
          objects: const ['kurabiye'],
          counts: {'plate': a, 'box': b},
          caption: 'Tabaktaki kurabiyeler',
        ),
        text:
            'Tabakta $a kurabiye var.\nKutudan $b kurabiye daha koyuyor.\nTabakta kaç kurabiye olur?',
      ),
      (
        spec: SceneVisualSpec(
          template: 'beach',
          character: 'Can',
          objects: const ['deniz yıldızı'],
          counts: {'sand': a, 'bucket': b},
          caption: 'Sahilde deniz yıldızları',
        ),
        text:
            'Kumda $a deniz yıldızı var.\nKovada $b deniz yıldızı var.\nToplam kaç tane?',
      ),
      (
        spec: SceneVisualSpec(
          template: 'classroom',
          character: 'Merve',
          objects: const ['kalem'],
          counts: {'box': a, 'desk': b},
          caption: 'Sınıfta kalemler',
        ),
        text:
            'Kutuda $a kalem var.\nMasada $b kalem var.\nToplam kaç kalem?',
      ),
      (
        spec: SceneVisualSpec(
          template: 'market',
          character: 'Deniz',
          objects: const ['meyve'],
          counts: {'bag': a, 'cart': b},
          caption: 'Markette meyveler',
        ),
        text:
            'Poşette $a meyve var.\nArabada $b meyve daha var.\nToplam kaç meyve?',
      ),
      (
        spec: SceneVisualSpec(
          template: 'garden',
          character: 'Ece',
          objects: const ['çiçek'],
          counts: {'pot': a, 'ground': b},
          caption: 'Bahçede çiçekler',
        ),
        text:
            'Saksılarda $a çiçek var.\nToprakta $b çiçek daha var.\nToplam kaç çiçek?',
      ),
      (
        spec: SceneVisualSpec(
          template: 'bedtime',
          character: 'Berk',
          objects: const ['oyuncak'],
          counts: {'box': a, 'floor': b},
          caption: 'Odada oyuncaklar',
        ),
        text:
            'Kutuda $a oyuncak var.\nYerde $b oyuncak var.\nToplam kaç oyuncak?',
      ),
    ];
    final s = stories[index % stories.length];
    return (
      spec: s.spec,
      text: s.text,
      explanation: '$a + $b = $sum',
    );
  }

  /// Çıkarma hikâyeleri — her şablon farklı sahne.
  static ({SceneVisualSpec spec, String text, String explanation}) mathSubStory({
    required int index,
    required int start,
    required int take,
  }) {
    final diff = start - take;
    final stories = <({SceneVisualSpec spec, String text})>[
      (
        spec: SceneVisualSpec(
          template: 'kitchen_apples',
          character: 'Ayşe',
          objects: const ['elma'],
          counts: {'basket': start, 'table': take},
          caption: 'Sepetten elma yiyor',
          action: 'yiyor',
        ),
        text:
            'Sepette $start elma var.\nAyşe $take elma yiyor.\nSepette kaç elma kalır?',
      ),
      (
        spec: SceneVisualSpec(
          template: 'park_ball',
          character: 'Ali',
          objects: const ['top'],
          counts: {'ground': start, 'bag': take},
          caption: 'Parkta top kayboluyor',
        ),
        text:
            'Parkta $start top var.\nAli $take topu çantaya koyuyor.\nYerde kaç top kalır?',
      ),
      (
        spec: SceneVisualSpec(
          template: 'shelf_books',
          character: 'Zeynep',
          objects: const ['kitap'],
          counts: {'shelf': start, 'hand': take},
          caption: 'Raftan kitap alınıyor',
        ),
        text:
            'Rafta $start kitap var.\nZeynep $take kitap alıyor.\nRafta kaç kitap kalır?',
      ),
      (
        spec: SceneVisualSpec(
          template: 'plate_food',
          character: 'Elif',
          objects: const ['kurabiye'],
          counts: {'plate': start, 'box': take},
          caption: 'Tabaktan kurabiye',
        ),
        text:
            'Tabakta $start kurabiye var.\nElif $take kurabiye yiyor.\nKaç kurabiye kalır?',
      ),
      (
        spec: SceneVisualSpec(
          template: 'classroom',
          character: 'Mehmet',
          objects: const ['kalem'],
          counts: {'box': start, 'desk': take},
          caption: 'Kutudan kalem',
        ),
        text:
            'Kutuda $start kalem var.\nMehmet $take kalem alıyor.\nKutuda kaç kalem kalır?',
      ),
      (
        spec: SceneVisualSpec(
          template: 'beach',
          character: 'Can',
          objects: const ['deniz yıldızı'],
          counts: {'sand': start, 'bucket': take},
          caption: 'Kumdan yıldız',
        ),
        text:
            'Kumda $start deniz yıldızı var.\nCan $take tanesini kovaya koyuyor.\nKumda kaç tane kalır?',
      ),
      (
        spec: SceneVisualSpec(
          template: 'market',
          character: 'Deniz',
          objects: const ['meyve'],
          counts: {'bag': start, 'cart': take},
          caption: 'Poşetten meyve',
        ),
        text:
            'Poşette $start meyve var.\nDeniz $take meyve yiyor.\nPoşette kaç meyve kalır?',
      ),
      (
        spec: SceneVisualSpec(
          template: 'garden',
          character: 'Ece',
          objects: const ['çiçek'],
          counts: {'pot': start, 'ground': take},
          caption: 'Saksıdan çiçek',
        ),
        text:
            'Saksılarda $start çiçek var.\nEce $take çiçeği başka yere taşıyor.\nKaç çiçek kalır?',
      ),
      (
        spec: SceneVisualSpec(
          template: 'bedtime',
          character: 'Berk',
          objects: const ['oyuncak'],
          counts: {'box': start, 'floor': take},
          caption: 'Kutudan oyuncak',
        ),
        text:
            'Kutuda $start oyuncak var.\nBerk $take oyuncak çıkarıyor.\nKutuda kaç oyuncak kalır?',
      ),
      (
        spec: SceneVisualSpec(
          template: 'fridge_eggs',
          character: 'Merve',
          objects: const ['yumurta', 'buzdolabı'],
          counts: {'fridge': start, 'hand': take},
          setting: 'mutfak',
          action: 'alıyor',
          caption: 'Buzdolabından yumurta alınıyor',
        ),
        text:
            'Buzdolabında $start yumurta var.\nMerve $take yumurta alıyor.\nBuzdolabında kaç yumurta kalır?',
      ),
    ];
    final s = stories[index % stories.length];
    return (
      spec: s.spec,
      text: s.text,
      explanation: '$start - $take = $diff',
    );
  }
}
