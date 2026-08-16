import 'dart:math';

import '../../../data/models/education_question.dart';
import '../../../data/models/sequence_question.dart';
import '../../../data/models/skill_level.dart';
import '../../education/domain/activity_engine.dart';

class LanguageQuestionGenerator implements QuestionGenerator {
  LanguageQuestionGenerator({Random? random}) : _rng = random ?? Random(7);

  final Random _rng;

  @override
  SkillArea get skill => SkillArea.language;

  @override
  List<EducationQuestion> generate({
    required String category,
    required SkillTier difficulty,
    int count = 5,
  }) {
    return List.generate(
      count,
      (i) => _one(category: category, difficulty: difficulty, index: i),
    );
  }

  EducationQuestion _one({
    required String category,
    required SkillTier difficulty,
    required int index,
  }) {
    return switch (category) {
      'alphabetical' => _alphabetical(difficulty, index),
      'five_w1h' => _fiveW1h(difficulty, index),
      'antonyms' => _antonyms(difficulty, index),
      'synonyms' => _synonyms(difficulty, index),
      'homophones' => _homophones(difficulty, index),
      'concepts' => _concepts(difficulty, index),
      'event_ordering' => _eventOrdering(difficulty, index),
      'word_ordering' => _wordOrdering(difficulty, index),
      _ => _antonyms(difficulty, index),
    };
  }

  EducationQuestion _concepts(SkillTier d, int index) {
    final bank = switch (d) {
      SkillTier.easy => const [
          (
            'Hangisi BÜYÜK?',
            'Büyük top',
            ['Büyük top', 'Küçük top', 'Orta kutu'],
            'büyük-küçük',
          ),
          (
            'Hangisi UZUN?',
            'Uzun ip',
            ['Uzun ip', 'Kısa ip', 'Top'],
            'uzun-kısa',
          ),
        ],
      SkillTier.medium => const [
          (
            'Hangisi AĞIR?',
            'Ağır çanta',
            ['Ağır çanta', 'Hafif tüy', 'Boş kutu', 'İnce kalem'],
            'ağır-hafif',
          ),
          (
            'Hangisi DOLU?',
            'Dolu bardak',
            ['Dolu bardak', 'Boş bardak', 'Kırık tabak'],
            'dolu-boş',
          ),
        ],
      SkillTier.hard => const [
          (
            'Cümlede “küçük”ün zıt kavramı hangisi?',
            'Büyük',
            ['Büyük', 'Minik', 'İnce', 'Yavaş'],
            'cümle-kavram',
          ),
          (
            '“Kısa yol”daki kavramın zıttı?',
            'Uzun',
            ['Uzun', 'Dar', 'Yavaş', 'Boş'],
            'cümle-kavram',
          ),
        ],
    };
    final p = bank[index % bank.length];
    return EducationQuestion(
      id: 'lang-concept-$index-${d.name}',
      category: 'concepts',
      skill: SkillArea.language,
      difficulty: d,
      instruction: d == SkillTier.easy
          ? 'Görsel + kelime: doğru kavramı seç.'
          : 'Doğru kavramı seç.',
      questionText: p.$1,
      choices: p.$3,
      correctAnswer: p.$2,
      explanation: 'Kavram: ${p.$4} → ${p.$2}',
      metadata: {
        'type': 'multipleChoice',
        'conceptPair': p.$4,
        if (d == SkillTier.easy) 'withVisualHint': true,
      },
    );
  }

  EducationQuestion _homophones(SkillTier d, int index) {
    final bank = switch (d) {
      SkillTier.easy => const [
          (
            '“Kar” ile aynı seslenen ama yazımı farklı olan?',
            'Kâr',
            ['Kâr', 'Karlı', 'Kara', 'Kart'],
          ),
          (
            '“Göl” ile eş sesli hangisi?',
            'Göl (su)',
            ['Göl (su)', 'Gül', 'Yol', 'Kol'],
          ),
        ],
      SkillTier.medium => const [
          (
            '“Çay” (içecek) ile eş sesli yer adı anlamı için doğru yazım?',
            'Çay (akarsu)',
            ['Çay (akarsu)', 'Çayır', 'Çağ', 'Çaydanlık'],
          ),
          (
            '“Yüz” (sayı) ile eş sesli eylem?',
            'Yüzmek',
            ['Yüzmek', 'Yüzük', 'Yaz', 'Yün'],
          ),
        ],
      SkillTier.hard => const [
          (
            'Cümle: “Bahçede ___ açtı.” (çiçek) — doğru kelime?',
            'gül',
            ['gül', 'göl', 'kül', 'yol'],
          ),
          (
            'Cümle: “Süt ___ geldi.” (renk) — doğru kelime?',
            'beyaz',
            ['beyaz', 'beyazı', 'bayaz', 'boyaz'],
          ),
        ],
    };
    final p = bank[index % bank.length];
    return EducationQuestion(
      id: 'lang-homo-$index',
      category: 'homophones',
      skill: SkillArea.language,
      difficulty: d,
      instruction: 'Eş sesli / doğru yazımı seç.',
      questionText: p.$1,
      choices: p.$3,
      correctAnswer: p.$2,
      explanation: 'Doğru: ${p.$2}',
      metadata: const {'type': 'multipleChoice'},
    );
  }

  EducationQuestion _alphabetical(SkillTier d, int index) {
    final bank = switch (d) {
      SkillTier.easy => const [
          ['Ayna', 'Bıçak', 'Cetvel', 'Dolap'],
          ['Elma', 'Armut', 'Üzüm', 'Kiraz'],
        ],
      SkillTier.medium => const [
          ['Masa', 'Merdiven', 'Merdane', 'Mum'],
          ['Kalem', 'Kapı', 'Kedi', 'Kitap'],
        ],
      SkillTier.hard => const [
          ['Sandalye', 'Sandal', 'Sandık', 'Sarımsak'],
          ['Pencere', 'Pençe', 'Pembe', 'Perde'],
        ],
    };
    final words = [...bank[index % bank.length]];
    final sorted = [...words]..sort(
        (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
      );
    if (d == SkillTier.easy) {
      return EducationQuestion(
        id: 'lang-alpha-first-$index',
        category: 'alphabetical',
        skill: SkillArea.language,
        difficulty: d,
        instruction: 'Alfabetik sırada ilk kelime hangisi?',
        questionText: words.join('\n'),
        choices: words,
        correctAnswer: sorted.first,
        explanation: 'İlk kelime: ${sorted.first}',
        metadata: const {'type': 'multipleChoice'},
      );
    }
    final seq = SequenceQuestion.shuffled(sorted, random: _rng);
    return EducationQuestion(
      id: 'lang-alpha-order-$index',
      category: 'alphabetical',
      skill: SkillArea.language,
      difficulty: d,
      instruction: 'Kelimeleri alfabetik sıraya koy (sürükle veya seç).',
      questionText: d == SkillTier.hard ? 'Yalnızca kelime' : 'Sırala',
      choices: seq.items,
      correctAnswer: SequenceQuestion.encode(seq.correctItems),
      explanation: 'Sıra: ${seq.correctItems.join(', ')}',
      metadata: seq.toMap(),
    );
  }

  EducationQuestion _fiveW1h(SkillTier d, int index) {
    const sentence = 'Ayşe denizde top oynuyor.';
    final prompts = switch (d) {
      SkillTier.easy => [
          ('Kim?', 'Ayşe', ['Ayşe', 'Deniz', 'Top', 'Okul']),
          (
            'Ne yapıyor?',
            'Top oynuyor',
            ['Top oynuyor', 'Uyuyor', 'Yemek yiyor', 'Okuyor'],
          ),
          (
            'Nerede?',
            'Denizde',
            ['Denizde', 'Evde', 'Okulda', 'Parkta'],
          ),
        ],
      SkillTier.medium => [
          ('Kim?', 'Ayşe', ['Ayşe', 'Ahmet', 'Top', 'Deniz']),
          ('Ne?', 'Top', ['Top', 'Ayşe', 'Deniz', 'Kum']),
          (
            'Nerede?',
            'Denizde',
            ['Denizde', 'Havuzda', 'Gölde', 'Evde'],
          ),
        ],
      SkillTier.hard => [
          (
            'Nasıl bir yerde oynuyor?',
            'Denizde',
            ['Denizde', 'Evde', 'Sınıfta', 'Otobüste'],
          ),
          (
            'Ne ile oynuyor?',
            'Top',
            ['Top', 'Kitap', 'Kalem', 'Tabak'],
          ),
          (
            'Kim oynuyor?',
            'Ayşe',
            ['Ayşe', 'Top', 'Deniz', 'Güneş'],
          ),
        ],
    };
    final p = prompts[index % prompts.length];
    return EducationQuestion(
      id: 'lang-5n1k-$index-${d.name}',
      category: 'five_w1h',
      skill: SkillArea.language,
      difficulty: d,
      instruction: p.$1,
      questionText: sentence,
      choices: p.$3,
      correctAnswer: p.$2,
      explanation: '${p.$1} → ${p.$2}',
      metadata: {
        'type': 'multipleChoice',
        'scene': ['Ayşe', 'deniz', 'top'],
      },
    );
  }

  EducationQuestion _antonyms(SkillTier d, int index) {
    final pairs = switch (d) {
      SkillTier.easy => const [
          ('GECE', 'Gündüz', ['Gündüz', 'Karanlık', 'Akşam']),
          ('SICAK', 'Soğuk', ['Soğuk', 'Ilık', 'Yaz']),
          ('BÜYÜK', 'Küçük', ['Küçük', 'Uzun', 'Geniş']),
        ],
      SkillTier.medium => const [
          ('AÇIK', 'Kapalı', ['Kapalı', 'Geniş', 'Parlak']),
          ('HIZLI', 'Yavaş', ['Yavaş', 'Çabuk', 'Koşu']),
          ('DOLU', 'Boş', ['Boş', 'Ağır', 'Kalabalık']),
        ],
      SkillTier.hard => const [
          (
            'Ahmet gece dışarı çıktı.',
            'Gündüz',
            ['Gündüz', 'Karanlık', 'Akşam', 'Gece'],
          ),
          (
            'Su çok sıcaktı.',
            'Soğuk',
            ['Soğuk', 'Ilık', 'Kaynar', 'Yaz'],
          ),
        ],
    };
    final p = pairs[index % pairs.length];
    return EducationQuestion(
      id: 'lang-ant-$index',
      category: 'antonyms',
      skill: SkillArea.language,
      difficulty: d,
      instruction: 'Zıt kavramı seç.',
      questionText: p.$1,
      choices: p.$3,
      correctAnswer: p.$2,
      explanation: 'Zıt: ${p.$2}',
      metadata: const {'type': 'multipleChoice'},
    );
  }

  EducationQuestion _synonyms(SkillTier d, int index) {
    final pairs = const [
      ('Cevap', 'Yanıt', ['Yanıt', 'Soru', 'Ses']),
      ('Misafir', 'Konuk', ['Konuk', 'Ev', 'Kapı']),
      ('Kalp', 'Yürek', ['Yürek', 'El', 'Göz']),
      ('Güzel', 'Hoş', ['Hoş', 'Kötü', 'Büyük']),
    ];
    final p = pairs[index % pairs.length];
    final distractors = switch (d) {
      SkillTier.easy => p.$3,
      SkillTier.medium => [...p.$3, 'Benzer'],
      SkillTier.hard => [...p.$3, 'Anlam', 'Kelime'],
    };
    return EducationQuestion(
      id: 'lang-syn-$index',
      category: 'synonyms',
      skill: SkillArea.language,
      difficulty: d,
      instruction: 'Eş anlamlıyı seç.',
      questionText: p.$1,
      choices: distractors,
      correctAnswer: p.$2,
      explanation: '${p.$1} ↔ ${p.$2}',
      metadata: const {'type': 'multipleChoice'},
    );
  }

  EducationQuestion _eventOrdering(SkillTier d, int index) {
    final sequences = switch (d) {
      SkillTier.easy => const [
          ['Uyandı', 'Kahvaltı yaptı', 'Okula gitti'],
          ['Ellerini yıkadı', 'Yemek yedi', 'Dişlerini fırçaladı'],
        ],
      SkillTier.medium => const [
          [
            'Alarm çaldı',
            'Uyandı',
            'Kahvaltı yaptı',
            'Çantasını aldı',
            'Okula gitti',
          ],
        ],
      SkillTier.hard => const [
          [
            'Markete gitti',
            'Listeyi okudu',
            'Ürünleri aldı',
            'Ödeme yaptı',
            'Eve döndü',
            'Poşetleri yerleştirdi',
          ],
        ],
    };
    final order = [...sequences[index % sequences.length]];
    final seq = SequenceQuestion.shuffled(order, random: _rng);
    return EducationQuestion(
      id: 'lang-event-$index',
      category: 'event_ordering',
      skill: SkillArea.language,
      difficulty: d,
      instruction: 'Olayları doğru sıraya koy.',
      questionText: 'Baştan sona sırala',
      choices: seq.items,
      correctAnswer: SequenceQuestion.encode(seq.correctItems),
      explanation: seq.correctItems.join(' → '),
      metadata: seq.toMap(),
    );
  }

  EducationQuestion _wordOrdering(SkillTier d, int index) {
    final sentences = switch (d) {
      SkillTier.easy => const [
          ['Ben', 'elma', 'yerim'],
          ['Kedi', 'süt', 'içer'],
        ],
      SkillTier.medium => const [
          ['Ayşe', 'parkta', 'top', 'oynuyor'],
          ['Bugün', 'hava', 'çok', 'güzel'],
        ],
      SkillTier.hard => const [
          ['Küçük', 'kız', 'mavi', 'balonu', 'sevdi'],
          ['Öğretmen', 'tahtaya', 'bir', 'soru', 'yazdı'],
        ],
    };
    final order = [...sentences[index % sentences.length]];
    final seq = SequenceQuestion.shuffled(order, random: _rng);
    return EducationQuestion(
      id: 'lang-words-$index',
      category: 'word_ordering',
      skill: SkillArea.language,
      difficulty: d,
      instruction: 'Kelimeleri doğru sıraya koy.',
      questionText: d == SkillTier.easy
          ? 'Cümleyi kur (görsel+kelime)'
          : 'Cümleyi kur',
      choices: seq.items,
      correctAnswer: SequenceQuestion.encode(seq.correctItems),
      explanation: seq.correctItems.join(' '),
      metadata: seq.toMap(),
    );
  }
}
