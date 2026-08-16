import 'dart:math';

import '../../../data/models/education_question.dart';
import '../../../data/models/sequence_question.dart';
import '../../../data/models/skill_level.dart';
import '../../education/domain/activity_engine.dart';
import '../../education/domain/question_selection.dart';
import '../../education/domain/scene_visual_spec.dart';

class LanguageQuestionGenerator implements QuestionGenerator {
  LanguageQuestionGenerator({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  @override
  SkillArea get skill => SkillArea.language;

  @override
  List<EducationQuestion> generate({
    required String category,
    required SkillTier difficulty,
    int count = 10,
    List<String> excludeIds = const [],
  }) {
    final pool = _pool(category: category, difficulty: difficulty);
    return QuestionSelection.pickWithoutRecent(
      pool: pool,
      recentIds: excludeIds,
      count: count,
      random: _rng,
    );
  }

  List<EducationQuestion> _pool({
    required String category,
    required SkillTier difficulty,
  }) {
    return switch (category) {
      'alphabetical' => _alphabeticalPool(difficulty),
      'five_w1h' => _fiveW1hPool(difficulty),
      'antonyms' => _antonymsPool(difficulty),
      'synonyms' => _synonymsPool(difficulty),
      'homophones' => _homophonesPool(difficulty),
      'concepts' => _conceptsPool(difficulty),
      'event_ordering' => _eventOrderingPool(difficulty),
      'word_ordering' => _wordOrderingPool(difficulty),
      _ => _antonymsPool(difficulty),
    };
  }

  EducationQuestion _mc({
    required String id,
    required String category,
    required SkillTier d,
    required String instruction,
    required String questionText,
    required List<String> choices,
    required String correctAnswer,
    required String explanation,
    Map<String, dynamic> metadata = const {'type': 'multipleChoice'},
  }) {
    final scene = SceneVisualSpec(
      template: 'scene_5n1k',
      caption: questionText,
      objects: [correctAnswer],
      setting: switch (category) {
        'concepts' => 'park',
        'antonyms' || 'synonyms' => 'okul',
        'homophones' => 'ev',
        _ => 'okul',
      },
    );
    return EducationQuestion(
      id: id,
      category: category,
      skill: SkillArea.language,
      difficulty: d,
      instruction: instruction,
      questionText: questionText,
      imageUrl: 'mock://lang/$category/${id.hashCode.abs()}',
      solutionImageUrl: 'mock://lang/$category/solution',
      choices: choices,
      correctAnswer: correctAnswer,
      explanation: explanation,
      metadata: {
        ...metadata,
        if (!metadata.containsKey('sceneVisual'))
          'sceneVisual': scene.toMap(),
      },
    );
  }

  List<EducationQuestion> _conceptsPool(SkillTier d) {
    final bank = switch (d) {
      SkillTier.easy => const [
          ('Hangisi BÜYÜK?', 'Büyük top', ['Büyük top', 'Küçük top', 'Orta kutu'], 'büyük-küçük'),
          ('Hangisi UZUN?', 'Uzun ip', ['Uzun ip', 'Kısa ip', 'Top'], 'uzun-kısa'),
          ('Hangisi KÜÇÜK?', 'Küçük fare', ['Küçük fare', 'Büyük fil', 'Uzun yol'], 'büyük-küçük'),
          ('Hangisi KISA?', 'Kısa kalem', ['Kısa kalem', 'Uzun cetvel', 'Geniş kapı'], 'uzun-kısa'),
          ('Hangisi YÜKSEK?', 'Yüksek dağ', ['Yüksek dağ', 'Alçak tepe', 'Küçük taş'], 'yüksek-alçak'),
          ('Hangisi ALÇAK?', 'Alçak masa', ['Alçak masa', 'Yüksek bina', 'Uzun ağaç'], 'yüksek-alçak'),
          ('Hangisi GENİŞ?', 'Geniş yol', ['Geniş yol', 'Dar sokak', 'İnce ip'], 'geniş-dar'),
          ('Hangisi DAR?', 'Dar kapı', ['Dar kapı', 'Geniş salon', 'Büyük oda'], 'geniş-dar'),
          ('Hangisi HIZLI?', 'Hızlı araba', ['Hızlı araba', 'Yavaş kaplumbağa', 'Küçük taş'], 'hızlı-yavaş'),
          ('Hangisi YAVAŞ?', 'Yavaş salyangoz', ['Yavaş salyangoz', 'Hızlı tren', 'Uzun yol'], 'hızlı-yavaş'),
        ],
      SkillTier.medium => const [
          ('Hangisi AĞIR?', 'Ağır çanta', ['Ağır çanta', 'Hafif tüy', 'Boş kutu', 'İnce kalem'], 'ağır-hafif'),
          ('Hangisi DOLU?', 'Dolu bardak', ['Dolu bardak', 'Boş bardak', 'Kırık tabak'], 'dolu-boş'),
          ('Hangisi HAFİF?', 'Hafif balon', ['Hafif balon', 'Ağır taş', 'Dolu kova'], 'ağır-hafif'),
          ('Hangisi BOŞ?', 'Boş kutu', ['Boş kutu', 'Dolu kutu', 'Ağır çanta'], 'dolu-boş'),
          ('Hangisi SICAK?', 'Sıcak çorba', ['Sıcak çorba', 'Soğuk dondurma', 'Ilık su'], 'sıcak-soğuk'),
          ('Hangisi SOĞUK?', 'Soğuk buz', ['Soğuk buz', 'Sıcak çay', 'Ilık ekmek'], 'sıcak-soğuk'),
          ('Hangisi YAŞ?', 'Yaş havlu', ['Yaş havlu', 'Kuru havlu', 'Temiz bardak'], 'yaş-kuru'),
          ('Hangisi KURU?', 'Kuru yaprak', ['Kuru yaprak', 'Yaş mendil', 'Dolu bardak'], 'yaş-kuru'),
          ('Hangisi TEMİZ?', 'Temiz tabak', ['Temiz tabak', 'Kirli ayakkabı', 'Boş kova'], 'temiz-kirli'),
          ('Hangisi KİRLİ?', 'Kirli elbise', ['Kirli elbise', 'Temiz gömlek', 'Yeni kalem'], 'temiz-kirli'),
        ],
      SkillTier.hard => const [
          ('Cümlede “küçük”ün zıt kavramı hangisi?', 'Büyük', ['Büyük', 'Minik', 'İnce', 'Yavaş'], 'cümle'),
          ('“Kısa yol”daki kavramın zıttı?', 'Uzun', ['Uzun', 'Dar', 'Yavaş', 'Boş'], 'cümle'),
          ('“Ağır paket”teki kavramın zıttı?', 'Hafif', ['Hafif', 'Büyük', 'Dolu', 'Yavaş'], 'cümle'),
          ('“Dolu kutu”nun zıttı?', 'Boş', ['Boş', 'Ağır', 'Geniş', 'Sıcak'], 'cümle'),
          ('“Yüksek bina”nın zıttı?', 'Alçak', ['Alçak', 'Uzun', 'Dar', 'Ağır'], 'cümle'),
          ('“Hızlı koşu”nun zıttı?', 'Yavaş', ['Yavaş', 'Uzun', 'Büyük', 'Boş'], 'cümle'),
          ('“Geniş sokak”ın zıttı?', 'Dar', ['Dar', 'Kısa', 'Hafif', 'Kuru'], 'cümle'),
          ('“Sıcak çay”ın zıttı?', 'Soğuk', ['Soğuk', 'Dolu', 'Temiz', 'Uzun'], 'cümle'),
          ('“Yaş havlu”nun zıttı?', 'Kuru', ['Kuru', 'Boş', 'Hafif', 'Dar'], 'cümle'),
          ('“Temiz oda”nın zıttı?', 'Kirli', ['Kirli', 'Boş', 'Dar', 'Soğuk'], 'cümle'),
        ],
    };
    return [
      for (var i = 0; i < bank.length; i++)
        _mc(
          id: 'lang-concept-${d.name}-$i-${bank[i].$4}',
          category: 'concepts',
          d: d,
          instruction: d == SkillTier.easy
              ? 'Görsel + kelime: doğru kavramı seç.'
              : 'Doğru kavramı seç.',
          questionText: bank[i].$1,
          choices: bank[i].$3,
          correctAnswer: bank[i].$2,
          explanation: 'Kavram: ${bank[i].$4} → ${bank[i].$2}',
          metadata: {
            'type': 'multipleChoice',
            'conceptPair': bank[i].$4,
            if (d == SkillTier.easy) 'withVisualHint': true,
          },
        ),
    ];
  }

  List<EducationQuestion> _homophonesPool(SkillTier d) {
    final bank = switch (d) {
      SkillTier.easy => const [
          ('“Kar” ile aynı seslenen ama yazımı farklı olan?', 'Kâr', ['Kâr', 'Karlı', 'Kara', 'Kart']),
          ('“Göl” ile eş sesli hangisi?', 'Göl (su)', ['Göl (su)', 'Gül', 'Yol', 'Kol']),
          ('“Çay” (içecek) ile aynı seslenen?', 'Çay (akarsu)', ['Çay (akarsu)', 'Çayır', 'Çağ', 'Çaydanlık']),
          ('“Yüz” (sayı) ile eş sesli eylem kökü?', 'Yüzmek', ['Yüzmek', 'Yüzük', 'Yaz', 'Yün']),
          ('“At” (hayvan) ile eş sesli eylem?', 'Atmak', ['Atmak', 'Atlı', 'Ay', 'Ot']),
          ('“Dal” (ağaç) ile eş sesli eylem?', 'Dalmak', ['Dalmak', 'Dalga', 'Kal', 'Bal']),
          ('“Yaz” (mevsim) ile eş sesli eylem?', 'Yazmak', ['Yazmak', 'Yazlık', 'Yüz', 'Yas']),
          ('“Ek” ile eş sesli sayı?', 'İki (ses benzeri dikkat)', ['İki (ses benzeri dikkat)', 'Üç', 'Beş', 'On']),
          ('“Gül” (çiçek) ile eş sesli eylem?', 'Gülmek', ['Gülmek', 'Göl', 'Kul', 'Yol']),
          ('“Bal” ile eş sesli eylem benzeri?', 'Balık (yakın ses)', ['Balık (yakın ses)', 'Bol', 'Bel', 'Bul']),
        ],
      SkillTier.medium => const [
          ('“Çay” (içecek) ile eş sesli yer adı anlamı için doğru yazım?', 'Çay (akarsu)', ['Çay (akarsu)', 'Çayır', 'Çağ', 'Çaydanlık']),
          ('“Yüz” (sayı) ile eş sesli eylem?', 'Yüzmek', ['Yüzmek', 'Yüzük', 'Yaz', 'Yün']),
          ('“Kar” / “kâr” ayrımı: kazanç anlamı?', 'Kâr', ['Kâr', 'Kar', 'Kara', 'Kart']),
          ('“Göz” ile ilgili eş sesli dikkat: “göz / köz” — köz nedir?', 'Köz (ateş)', ['Köz (ateş)', 'Göz', 'Koz', 'Kös']),
          ('“Saat” (zaman) ile eş yazımlı cihaz?', 'Saat (alet)', ['Saat (alet)', 'Sahat', 'Sat', 'Set']),
          ('“Yol” ile eş sesli yakın kelime?', 'Yulaf değil — Yol', ['Yol', 'Yul', 'Yıl', 'Yel']),
          ('“Bin” (sayı) ile eş sesli eylem?', 'Binmek', ['Binmek', 'Bina', 'Ben', 'Ban']),
          ('“Çek” (fiil) ile eş sesli banka anlamı?', 'Çek (belge)', ['Çek (belge)', 'Çekirge', 'Çök', 'Çok']),
          ('“Al” (fiil) ile eş sesli renk?', 'Al (kırmızı)', ['Al (kırmızı)', 'El', 'Öl', 'Ol']),
          ('“Dil” (organ) ile eş sesli dil (lisan)?', 'Dil (lisan)', ['Dil (lisan)', 'Dal', 'Del', 'Dol']),
        ],
      SkillTier.hard => const [
          ('Cümle: “Bahçede ___ açtı.” (çiçek) — doğru kelime?', 'gül', ['gül', 'göl', 'kül', 'yol']),
          ('Cümle: “Süt ___ geldi.” (renk) — doğru kelime?', 'beyaz', ['beyaz', 'beyazı', 'bayaz', 'boyaz']),
          ('Cümle: “Kışın ___ yağdı.” — doğru kelime?', 'kar', ['kar', 'kâr', 'kara', 'kart']),
          ('Cümle: “Gölde ___ yüzdü.” — doğru kelime?', 'balık', ['balık', 'bal', 'bol', 'bel']),
          ('Cümle: “Çaydan ___ içtim.” — doğru kelime?', 'çay', ['çay', 'çayır', 'çağ', 'çaycı']),
          ('Cümle: “Yüz ___ saydım.” — doğru kelime?', 'yüz', ['yüz', 'yüzük', 'yaz', 'yün']),
          ('Cümle: “At ___ koştu.” — doğru kelime?', 'hızlı', ['hızlı', 'atlı', 'ötü', 'ütü']),
          ('Cümle: “Kâr ___ hesapladı.” — doğru kelime?', 'ettik', ['ettik', 'ettikçe', 'kar', 'kart']),
          ('Cümle: “Saat ___ çaldı.” — doğru kelime?', 'dokuz', ['dokuz', 'doğu', 'dok', 'doktor']),
          ('Cümle: “Dil ___ konuştuk.” — doğru kelime?', 'Türkçe', ['Türkçe', 'türkü', 'türk', 'tül']),
        ],
    };
    return [
      for (var i = 0; i < bank.length; i++)
        _mc(
          id: 'lang-homo-${d.name}-$i',
          category: 'homophones',
          d: d,
          instruction: 'Eş sesli / doğru yazımı seç.',
          questionText: bank[i].$1,
          choices: bank[i].$3,
          correctAnswer: bank[i].$2,
          explanation: 'Doğru: ${bank[i].$2}',
        ),
    ];
  }

  List<EducationQuestion> _alphabeticalPool(SkillTier d) {
    final bank = switch (d) {
      SkillTier.easy => const [
          ['Ayna', 'Bıçak', 'Cetvel', 'Dolap'],
          ['Elma', 'Armut', 'Üzüm', 'Kiraz'],
          ['Kalem', 'Defter', 'Silgi', 'Çanta'],
          ['Masa', 'Sandalye', 'Kapı', 'Pencere'],
          ['Araba', 'Bisiklet', 'Tren', 'Uçak'],
          ['Kedi', 'Köpek', 'Kuş', 'Balık'],
          ['Güneş', 'Ay', 'Yıldız', 'Bulut'],
          ['Ekmek', 'Peynir', 'Zeytin', 'Bal'],
          ['Top', 'İp', 'Blok', 'Puzzle'],
          ['Okul', 'Sınıf', 'Tahta', 'Sıra'],
        ],
      SkillTier.medium => const [
          ['Masa', 'Merdiven', 'Merdane', 'Mum'],
          ['Kalem', 'Kapı', 'Kedi', 'Kitap'],
          ['Sandalye', 'Sandal', 'Sandık', 'Sarımsak'],
          ['Pencere', 'Pençe', 'Pembe', 'Perde'],
          ['Bahçe', 'Balık', 'Bardak', 'Bez'],
          ['Çanta', 'Çatal', 'Çiçek', 'Çorap'],
          ['Defter', 'Deniz', 'Dere', 'Dudak'],
          ['Fener', 'Fil', 'Fırça', 'Fincan'],
          ['Gemi', 'Göz', 'Gömlek', 'Gül'],
          ['Halı', 'Havuç', 'Hexagon değil — Halat', 'Horoz'],
        ],
      SkillTier.hard => const [
          ['Sandalye', 'Sandal', 'Sandık', 'Sarımsak'],
          ['Pencere', 'Pençe', 'Pembe', 'Perde'],
          ['Traktör', 'Tren', 'Trompet', 'Turşu'],
          ['Zeytin', 'Zil', 'Zımba', 'Zürafa'],
          ['Lamba', 'Limon', 'Lale', 'Lokum'],
          ['Makas', 'Mandalina', 'Mantar', 'Mürekkep'],
          ['Nar', 'Nane', 'Nehir', 'Nota'],
          ['Otobüs', 'Orman', 'Ot', 'Oyuncak'],
          ['Radyo', 'Raf', 'Renk', 'Rüzgar'],
          ['Şapka', 'Şeker', 'Şemsiye', 'Şişe'],
        ],
    };
    // Fix the weird medium entry
    final fixedBank = [
      for (final row in bank)
        [
          for (final w in row)
            w.contains('Hexagon') ? 'Halat' : w,
        ],
    ];
    final out = <EducationQuestion>[];
    for (var i = 0; i < fixedBank.length; i++) {
      final words = [...fixedBank[i]];
      final sorted = [...words]
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      if (d == SkillTier.easy) {
        out.add(
          _mc(
            id: 'lang-alpha-first-${d.name}-$i',
            category: 'alphabetical',
            d: d,
            instruction: 'Alfabetik sırada ilk kelime hangisi?',
            questionText: words.join('\n'),
            choices: words,
            correctAnswer: sorted.first,
            explanation: 'İlk kelime: ${sorted.first}',
          ),
        );
      } else {
        final seq = SequenceQuestion.shuffled(sorted, random: Random(i + 17));
        out.add(
          EducationQuestion(
            id: 'lang-alpha-order-${d.name}-$i',
            category: 'alphabetical',
            skill: SkillArea.language,
            difficulty: d,
            instruction: 'Kelimeleri alfabetik sıraya koy.',
            questionText: d == SkillTier.hard ? 'Yalnızca kelime' : 'Sırala',
            imageUrl: 'mock://lang/alphabetical',
            solutionImageUrl: 'mock://lang/alphabetical/solution',
            choices: seq.items,
            correctAnswer: SequenceQuestion.encode(seq.correctItems),
            explanation: 'Sıra: ${seq.correctItems.join(', ')}',
            metadata: seq.toMap(),
          ),
        );
      }
    }
    return out;
  }

  List<EducationQuestion> _fiveW1hPool(SkillTier d) {
    // Görselli kart taşıma: Kim → Ne → Nerede (+ orta/zor: Ne zaman / Neden).
    final scenes = <({
      String sentence,
      String setting,
      String character,
      List<String> objects,
      List<(String label, String icon)> base,
      (String label, String icon) whenCard,
      (String label, String icon) whyCard,
    })>[
      (
        sentence: 'Ayşe denizde top oynuyor.',
        setting: 'deniz',
        character: 'Ayşe',
        objects: const ['top'],
        base: const [
          ('Ayşe', 'person'),
          ('Top oynuyor', 'sports_soccer'),
          ('Denizde', 'beach_access'),
        ],
        whenCard: ('Öğleden sonra', 'wb_sunny'),
        whyCard: ('Eğlenmek için', 'mood'),
      ),
      (
        sentence: 'Ali parkta bisiklet sürüyor.',
        setting: 'park',
        character: 'Ali',
        objects: const ['bisiklet'],
        base: const [
          ('Ali', 'person'),
          ('Bisiklet sürüyor', 'directions_bike'),
          ('Parkta', 'park'),
        ],
        whenCard: ('Sabah', 'wb_sunny'),
        whyCard: ('Spor yapmak için', 'favorite'),
      ),
      (
        sentence: 'Zeynep evde kitap okuyor.',
        setting: 'ev',
        character: 'Zeynep',
        objects: const ['kitap'],
        base: const [
          ('Zeynep', 'person'),
          ('Kitap okuyor', 'menu_book'),
          ('Evde', 'home'),
        ],
        whenCard: ('Akşam', 'bedtime'),
        whyCard: ('Ödev için', 'school'),
      ),
      (
        sentence: 'Mehmet okulda yazı yazıyor.',
        setting: 'okul',
        character: 'Mehmet',
        objects: const ['kalem'],
        base: const [
          ('Mehmet', 'person'),
          ('Yazı yazıyor', 'edit'),
          ('Okulda', 'school'),
        ],
        whenCard: ('Ders saatinde', 'school'),
        whyCard: ('Öğrenmek için', 'menu_book'),
      ),
      (
        sentence: 'Elif bahçede çiçek suluyor.',
        setting: 'bahçe',
        character: 'Elif',
        objects: const ['çiçek'],
        base: const [
          ('Elif', 'person'),
          ('Çiçek suluyor', 'local_florist'),
          ('Bahçede', 'yard'),
        ],
        whenCard: ('Sabah erken', 'wb_sunny'),
        whyCard: ('Bitkiler büyüsün diye', 'local_florist'),
      ),
      (
        sentence: 'Can markette ekmek alıyor.',
        setting: 'market',
        character: 'Can',
        objects: const ['ekmek'],
        base: const [
          ('Can', 'person'),
          ('Ekmek alıyor', 'bakery_dining'),
          ('Markette', 'storefront'),
        ],
        whenCard: ('Öğleden önce', 'wb_sunny'),
        whyCard: ('Kahvaltı için', 'restaurant'),
      ),
      (
        sentence: 'Ece mutfakta yemek pişiriyor.',
        setting: 'ev',
        character: 'Ece',
        objects: const ['yemek'],
        base: const [
          ('Ece', 'person'),
          ('Yemek pişiriyor', 'soup_kitchen'),
          ('Mutfakta', 'kitchen'),
        ],
        whenCard: ('Akşamüstü', 'restaurant'),
        whyCard: ('Ailesi için', 'favorite'),
      ),
      (
        sentence: 'Berk parkta köpekle oynuyor.',
        setting: 'park',
        character: 'Berk',
        objects: const ['köpek'],
        base: const [
          ('Berk', 'person'),
          ('Köpekle oynuyor', 'pets'),
          ('Parkta', 'park'),
        ],
        whenCard: ('Öğleden sonra', 'wb_sunny'),
        whyCard: ('Sevdiği için', 'pets'),
      ),
      (
        sentence: 'Merve kütüphanede ders çalışıyor.',
        setting: 'okul',
        character: 'Merve',
        objects: const ['kitap'],
        base: const [
          ('Merve', 'person'),
          ('Ders çalışıyor', 'menu_book'),
          ('Kütüphanede', 'local_library'),
        ],
        whenCard: ('Öğleden sonra', 'school'),
        whyCard: ('Sınav için', 'edit'),
      ),
      (
        sentence: 'Deniz sahilde kumdan kale yapıyor.',
        setting: 'deniz',
        character: 'Deniz',
        objects: const ['kum'],
        base: const [
          ('Deniz', 'person'),
          ('Kale yapıyor', 'castle'),
          ('Sahilde', 'beach_access'),
        ],
        whenCard: ('Yaz tatilinde', 'beach_access'),
        whyCard: ('Oynamak için', 'mood'),
      ),
    ];

    return [
      for (var i = 0; i < scenes.length; i++)
        () {
          final s = scenes[i];
          final cards = <(String, String)>[
            ...s.base,
            if (d == SkillTier.medium || d == SkillTier.hard) s.whenCard,
            if (d == SkillTier.hard) s.whyCard,
          ];
          final labels = [for (final c in cards) c.$1];
          final icons = {for (final c in cards) c.$1: c.$2};
          final seq = SequenceQuestion.shuffled(labels, random: Random(i + 11));
          final steps = switch (d) {
            SkillTier.easy => 'Kim → Ne → Nerede',
            SkillTier.medium => 'Kim → Ne → Nerede → Ne zaman',
            SkillTier.hard => 'Kim → Ne → Nerede → Ne zaman → Neden',
          };
          return EducationQuestion(
            id: 'lang-5n1k-${d.name}-$i',
            category: 'five_w1h',
            skill: SkillArea.language,
            difficulty: d,
            instruction: 'Görselli kartları sürükle: $steps',
            questionText: s.sentence,
            imageUrl: 'mock://lang/5n1k/${s.setting}',
            solutionImageUrl: 'mock://lang/5n1k/${s.setting}/solution',
            choices: seq.items,
            correctAnswer: SequenceQuestion.encode(seq.correctItems),
            explanation: seq.correctItems.join(' → '),
            metadata: {
              ...seq.toMap(),
              'cardIcons': icons,
              'visualCards': true,
              'sceneVisual': SceneVisualSpec(
                template: 'scene_5n1k',
                character: s.character,
                objects: s.objects,
                setting: s.setting,
                caption: s.sentence,
              ).toMap(),
            },
          );
        }(),
    ];
  }

  List<EducationQuestion> _antonymsPool(SkillTier d) {
    final pairs = switch (d) {
      SkillTier.easy => const [
          ('GECE', 'Gündüz', ['Gündüz', 'Karanlık', 'Akşam']),
          ('SICAK', 'Soğuk', ['Soğuk', 'Ilık', 'Yaz']),
          ('BÜYÜK', 'Küçük', ['Küçük', 'Uzun', 'Geniş']),
          ('UZUN', 'Kısa', ['Kısa', 'İnce', 'Yavaş']),
          ('HIZLI', 'Yavaş', ['Yavaş', 'Çabuk', 'Koşu']),
          ('AÇIK', 'Kapalı', ['Kapalı', 'Geniş', 'Parlak']),
          ('DOLU', 'Boş', ['Boş', 'Ağır', 'Kalabalık']),
          ('YUKARI', 'Aşağı', ['Aşağı', 'İçeri', 'Dışarı']),
          ('İÇERİ', 'Dışarı', ['Dışarı', 'Yukarı', 'Aşağı']),
          ('TEMİZ', 'Kirli', ['Kirli', 'Yaş', 'Kuru']),
        ],
      SkillTier.medium => const [
          ('AÇIK', 'Kapalı', ['Kapalı', 'Geniş', 'Parlak']),
          ('HIZLI', 'Yavaş', ['Yavaş', 'Çabuk', 'Koşu']),
          ('DOLU', 'Boş', ['Boş', 'Ağır', 'Kalabalık']),
          ('AĞIR', 'Hafif', ['Hafif', 'Büyük', 'Dolu']),
          ('GENİŞ', 'Dar', ['Dar', 'Kısa', 'İnce']),
          ('YÜKSEK', 'Alçak', ['Alçak', 'Uzun', 'Derin']),
          ('YAŞ', 'Kuru', ['Kuru', 'Soğuk', 'Sıcak']),
          ('ESKİ', 'Yeni', ['Yeni', 'Büyük', 'Küçük']),
          ('SERT', 'Yumuşak', ['Yumuşak', 'Ağır', 'Keskin']),
          ('PARLAK', 'Mat', ['Mat', 'Açık', 'Kapalı']),
        ],
      SkillTier.hard => const [
          ('Ahmet gece dışarı çıktı.', 'Gündüz', ['Gündüz', 'Karanlık', 'Akşam', 'Gece']),
          ('Su çok sıcaktı.', 'Soğuk', ['Soğuk', 'Ilık', 'Kaynar', 'Yaz']),
          ('Kapı açıktı.', 'Kapalı', ['Kapalı', 'Geniş', 'Parlak', 'Açık']),
          ('Çanta çok ağırdı.', 'Hafif', ['Hafif', 'Büyük', 'Dolu', 'Ağır']),
          ('Yol çok dardı.', 'Geniş', ['Geniş', 'Uzun', 'Kısa', 'Dar']),
          ('Bina yüksekti.', 'Alçak', ['Alçak', 'Uzun', 'Derin', 'Yüksek']),
          ('Havlu yaştı.', 'Kuru', ['Kuru', 'Kirli', 'Temiz', 'Yaş']),
          ('Ayakkabı eskiydi.', 'Yeni', ['Yeni', 'Büyük', 'Küçük', 'Eski']),
          ('Yastık sertti.', 'Yumuşak', ['Yumuşak', 'Ağır', 'Keskin', 'Sert']),
          ('Oda karanlıktı.', 'Aydınlık', ['Aydınlık', 'Kapalı', 'Boş', 'Karanlık']),
        ],
    };
    return [
      for (var i = 0; i < pairs.length; i++)
        _mc(
          id: 'lang-ant-${d.name}-$i',
          category: 'antonyms',
          d: d,
          instruction: 'Zıt kavramı seç.',
          questionText: pairs[i].$1,
          choices: pairs[i].$3,
          correctAnswer: pairs[i].$2,
          explanation: 'Zıt: ${pairs[i].$2}',
        ),
    ];
  }

  List<EducationQuestion> _synonymsPool(SkillTier d) {
    final pairs = const [
      ('Cevap', 'Yanıt', ['Yanıt', 'Soru', 'Ses']),
      ('Misafir', 'Konuk', ['Konuk', 'Ev', 'Kapı']),
      ('Kalp', 'Yürek', ['Yürek', 'El', 'Göz']),
      ('Güzel', 'Hoş', ['Hoş', 'Kötü', 'Büyük']),
      ('Akıllı', 'Zeki', ['Zeki', 'Yavaş', 'Küçük']),
      ('Hızlı', 'Çabuk', ['Çabuk', 'Yavaş', 'Ağır']),
      ('Ev', 'Yuva', ['Yuva', 'Okul', 'Yol']),
      ('Çocuk', 'Yavru', ['Yavru', 'Yetişkin', 'Kapı']),
      ('Sevinç', 'Mutluluk', ['Mutluluk', 'Üzüntü', 'Korku']),
      ('Yemek', 'Yiyecek', ['Yiyecek', 'İçecek', 'Oyun']),
      ('Öğretmen', 'Muallim', ['Muallim', 'Öğrenci', 'Müdür']),
      ('Kitap', 'Eser', ['Eser', 'Kalem', 'Defter']),
    ];
    return [
      for (var i = 0; i < pairs.length; i++)
        _mc(
          id: 'lang-syn-${d.name}-$i',
          category: 'synonyms',
          d: d,
          instruction: 'Eş anlamlıyı seç.',
          questionText: pairs[i].$1,
          choices: switch (d) {
            SkillTier.easy => pairs[i].$3,
            SkillTier.medium => [...pairs[i].$3, 'Benzer'],
            SkillTier.hard => [...pairs[i].$3, 'Anlam', 'Kelime'],
          },
          correctAnswer: pairs[i].$2,
          explanation: '${pairs[i].$1} ↔ ${pairs[i].$2}',
        ),
    ];
  }

  List<EducationQuestion> _eventOrderingPool(SkillTier d) {
    final sequences = switch (d) {
      SkillTier.easy => const [
          ['Uyandı', 'Kahvaltı yaptı', 'Okula gitti'],
          ['Ellerini yıkadı', 'Yemek yedi', 'Dişlerini fırçaladı'],
          ['Kapıyı açtı', 'İçeri girdi', 'Oturdu'],
          ['Çantasını aldı', 'Ayakkabı giydi', 'Evden çıktı'],
          ['Sabunladı', 'Yıkadı', 'Kuruladı'],
          ['Kitabı açtı', 'Okudu', 'Kapattı'],
          ['Topu aldı', 'Attı', 'Tuttu'],
          ['Suyu koydu', 'İçti', 'Bardağı bıraktı'],
          ['Işığı açtı', 'Odayı gördü', 'Işığı kapattı'],
          ['Selam verdi', 'Sordu', 'Cevap aldı'],
        ],
      SkillTier.medium => const [
          ['Alarm çaldı', 'Uyandı', 'Kahvaltı yaptı', 'Çantasını aldı', 'Okula gitti'],
          ['Ellerini yıkadı', 'Masaya oturdu', 'Yemek yedi', 'Teşekkür etti', 'Kalktı'],
          ['Kapıyı çaldı', 'Bekledi', 'İçeri alındı', 'Oturdu', 'Konuştu'],
          ['Diş macunu sürdü', 'Fırçaladı', 'Çalkaladı', 'Sildi', 'Bıraktı'],
          ['Oyuncağı aldı', 'Kutuyu açtı', 'Oynadı', 'Topladı', 'Yerleştirdi'],
          ['Kitabı seçti', 'Okudu', 'Not aldı', 'Kapattı', 'Rafa koydu'],
          ['Markete girdi', 'Listeyi okudu', 'Ürün aldı', 'Ödedi', 'Çıktı'],
          ['Parka gitti', 'Arkadaş buldu', 'Oynadı', 'Dinlendi', 'Eve döndü'],
          ['Ödevi açtı', 'Sordu', 'Çözdü', 'Kontrol etti', 'Teslim etti'],
          ['Banyoya girdi', 'Duş aldı', 'Kurulandı', 'Giydi', 'Çıktı'],
        ],
      SkillTier.hard => const [
          ['Markete gitti', 'Listeyi okudu', 'Ürünleri aldı', 'Ödeme yaptı', 'Eve döndü', 'Poşetleri yerleştirdi'],
          ['Çalar saat çaldı', 'Uyandı', 'Yüzünü yıkadı', 'Kahvaltı yaptı', 'Çantasını hazırladı', 'Okula gitti'],
          ['Kapıyı açtı', 'Misafiri karşıladı', 'İçeri aldı', 'İkram etti', 'Sohbet etti', 'Uğurladı'],
          ['Ödevi okudu', 'Araştırdı', 'Yazdı', 'Çizdi', 'Kontrol etti', 'Teslim etti'],
          ['Parka gitti', 'Bisiklet aldı', 'Kask taktı', 'Sürdü', 'Dinlendi', 'Eve döndü'],
          ['Ellerini yıkadı', 'Masayı kurdu', 'Yemeği koydu', 'Yedi', 'Bulaşıkları aldı', 'Yıkadı'],
          ['Kitap seçti', 'Kütüphaneye gitti', 'Ödünç aldı', 'Okudu', 'Not tuttu', 'İade etti'],
          ['Çantayı açtı', 'Kalemi buldu', 'Defteri çıkardı', 'Yazdı', 'Kapattı', 'Çantaya koydu'],
          ['Sınıfa girdi', 'Sırasına oturdu', 'Dinledi', 'Soru sordu', 'Cevapladı', 'Dersten çıktı'],
          ['Ayakkabı bağladı', 'Mont giydi', 'Kapıyı kilitledi', 'Asansöre bindi', 'Dışarı çıktı', 'Yürüdü'],
        ],
    };
    return [
      for (var i = 0; i < sequences.length; i++)
        () {
          final order = [...sequences[i]];
          final seq = SequenceQuestion.shuffled(order, random: Random(i + 31));
          return EducationQuestion(
            id: 'lang-event-${d.name}-$i',
            category: 'event_ordering',
            skill: SkillArea.language,
            difficulty: d,
            instruction: 'Görselli kartları sürükle — olayları sırala.',
            questionText: 'Baştan sona sırala',
            imageUrl: 'mock://lang/event/$i',
            solutionImageUrl: 'mock://lang/event/$i/solution',
            choices: seq.items,
            correctAnswer: SequenceQuestion.encode(seq.correctItems),
            explanation: seq.correctItems.join(' → '),
            metadata: {
              ...seq.toMap(),
              'visualCards': true,
              'cardIcons': {
                for (final label in order) label: _eventIcon(label),
              },
              'sceneVisual': SceneVisualSpec(
                template: 'scene_5n1k',
                setting: 'ev',
                caption: 'Günlük olay sırası',
                objects: order,
              ).toMap(),
            },
          );
        }(),
    ];
  }

  List<EducationQuestion> _wordOrderingPool(SkillTier d) {
    final sentences = switch (d) {
      SkillTier.easy => const [
          ['Ben', 'elma', 'yerim'],
          ['Kedi', 'süt', 'içer'],
          ['Ali', 'top', 'atar'],
          ['Kuş', 'uçup', 'gider'],
          ['Anne', 'yemek', 'yapar'],
          ['Çocuk', 'oyun', 'oynar'],
          ['Köpek', 'hav', 'eder'],
          ['Ben', 'su', 'içerim'],
          ['O', 'kitap', 'okur'],
          ['Biz', 'parkta', 'koşarız'],
        ],
      SkillTier.medium => const [
          ['Ayşe', 'parkta', 'top', 'oynuyor'],
          ['Bugün', 'hava', 'çok', 'güzel'],
          ['Ali', 'okula', 'erken', 'gitti'],
          ['Kedi', 'sofada', 'uyuyor', 'şimdi'],
          ['Biz', 'bahçede', 'çiçek', 'dikiyoruz'],
          ['Öğretmen', 'tahtaya', 'yazı', 'yazdı'],
          ['Çocuklar', 'sınıfta', 'şarkı', 'söylüyor'],
          ['Annem', 'mutfakta', 'çorba', 'pişiriyor'],
          ['Babam', 'arabayı', 'yavaş', 'sürüyor'],
          ['Zeynep', 'kitabı', 'dikkatle', 'okuyor'],
        ],
      SkillTier.hard => const [
          ['Küçük', 'kız', 'mavi', 'balonu', 'sevdi'],
          ['Öğretmen', 'tahtaya', 'bir', 'soru', 'yazdı'],
          ['Bugün', 'okulda', 'çok', 'güzel', 'şarkı', 'söyledik'],
          ['Ali', 'arkadaşıyla', 'parkta', 'top', 'oynadı'],
          ['Annem', 'sabah', 'erken', 'kahvaltı', 'hazırladı'],
          ['Kedi', 'pencerenin', 'önünde', 'uzun', 'süre', 'uyudu'],
          ['Biz', 'dün', 'akşam', 'birlikte', 'film', 'izledik'],
          ['Çocuklar', 'bahçede', 'neşeyle', 'koşup', 'oynadı'],
          ['Babam', 'yeni', 'kitabı', 'masanın', 'üstüne', 'koydu'],
          ['Zeynep', 'ödevini', 'dikkatle', 've', 'hızlı', 'bitirdi'],
        ],
    };
    return [
      for (var i = 0; i < sentences.length; i++)
        () {
          final order = [...sentences[i]];
          final seq = SequenceQuestion.shuffled(order, random: Random(i + 41));
          return EducationQuestion(
            id: 'lang-words-${d.name}-$i',
            category: 'word_ordering',
            skill: SkillArea.language,
            difficulty: d,
            instruction: 'Görselli kelime kartlarını sürükle — cümleyi kur.',
            questionText: 'Cümleyi doğru sıraya koy',
            imageUrl: 'mock://lang/words/$i',
            solutionImageUrl: 'mock://lang/words/$i/solution',
            choices: seq.items,
            correctAnswer: SequenceQuestion.encode(seq.correctItems),
            explanation: seq.correctItems.join(' '),
            metadata: {
              ...seq.toMap(),
              'visualCards': true,
              'cardIcons': {
                for (final label in order) label: 'edit',
              },
              'sceneVisual': SceneVisualSpec(
                template: 'scene_5n1k',
                setting: 'okul',
                caption: seq.correctItems.join(' '),
                objects: order,
              ).toMap(),
            },
          );
        }(),
    ];
  }

  String _eventIcon(String label) {
    final t = label.toLowerCase();
    if (t.contains('uyandı') || t.contains('alarm')) return 'bedtime';
    if (t.contains('kahvaltı') || t.contains('yemek') || t.contains('yedi')) {
      return 'restaurant';
    }
    if (t.contains('okul') || t.contains('ders') || t.contains('ödev')) {
      return 'school';
    }
    if (t.contains('yıkadı') || t.contains('sabun') || t.contains('duş')) {
      return 'soap';
    }
    if (t.contains('diş')) return 'mood';
    if (t.contains('kitap') || t.contains('okudu') || t.contains('kütüphane')) {
      return 'menu_book';
    }
    if (t.contains('top') || t.contains('oyna') || t.contains('park')) {
      return 'sports_soccer';
    }
    if (t.contains('market') || t.contains('ödeme') || t.contains('ürün')) {
      return 'storefront';
    }
    if (t.contains('kapı') || t.contains('ev') || t.contains('içeri')) {
      return 'home';
    }
    if (t.contains('çanta') || t.contains('ayakkabı') || t.contains('mont')) {
      return 'checkroom';
    }
    if (t.contains('bisiklet') || t.contains('sür')) return 'directions_bike';
    if (t.contains('çiçek') || t.contains('bahçe')) return 'local_florist';
    if (t.contains('el') || t.contains('temiz')) return 'cleaning_services';
    return 'circle';
  }
}
