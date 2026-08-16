import '../domain/scenario_models.dart';

/// JSON/map tabanlı senaryo kataloğu.
abstract final class ScenarioCatalog {
  static List<DailyLifeScenario> get all => [
        restaurant,
        market,
        grocery,
        bakery,
      ];

  static DailyLifeScenario? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Prompt §25 — Restoran (tam çalışan örnek).
  static final restaurant = DailyLifeScenario.fromMap(const {
    'scenario': 'restaurant',
    'title': 'Restoran',
    'description': 'Sipariş ver, doğru parayı öde, teşekkür et',
    'difficulty': 'easy',
    'npcRole': 'Garson',
    'steps': [
      {
        'id': 'greet',
        'type': 'npcSpeak',
        'speaker': 'Garson',
        'text': 'Merhaba, ne sipariş etmek istersiniz?',
      },
      {
        'id': 'order',
        'type': 'studentChoice',
        'speaker': 'Sen',
        'text': 'Ne istersin?',
        'hint': 'Pizza sipariş et.',
        'choices': [
          {'id': 'pizza', 'label': 'Pizza istiyorum.', 'correct': true},
          {'id': 'quiet', 'label': '...', 'correct': false},
          {'id': 'leave', 'label': 'Gidiyorum.', 'correct': false},
        ],
      },
      {
        'id': 'price',
        'type': 'npcSpeak',
        'speaker': 'Garson',
        'text': 'Pizzanız 50 TL.',
      },
      {
        'id': 'pay',
        'type': 'paymentChoice',
        'speaker': 'Sen',
        'text': 'Doğru parayı seç.',
        'hint': '50 TL olanı seç.',
        'choices': [
          {'id': '20', 'label': '20 TL', 'correct': false},
          {'id': '50', 'label': '50 TL', 'correct': true},
          {'id': '100', 'label': '100 TL', 'correct': false},
        ],
      },
      {
        'id': 'thanks_npc',
        'type': 'npcSpeak',
        'speaker': 'Garson',
        'text': 'Teşekkür ederim.',
      },
      {
        'id': 'thanks_student',
        'type': 'studentChoice',
        'speaker': 'Sen',
        'text': 'Ne dersin?',
        'hint': 'Teşekkür ederim de.',
        'choices': [
          {'id': 'thanks', 'label': 'Teşekkür ederim.', 'correct': true},
          {'id': 'bye_rude', 'label': 'Hadi bakayım.', 'correct': false},
          {'id': 'silent', 'label': '(Sessiz kal)', 'correct': false},
        ],
      },
      {
        'id': 'done',
        'type': 'complete',
        'speaker': 'Garson',
        'text': 'Afiyet olsun! Senaryo tamam.',
      },
    ],
  });

  static final market = DailyLifeScenario.fromMap(const {
    'scenario': 'market',
    'title': 'Market',
    'description': 'Kasiyerle selamlaş, ürün söyle, öde',
    'difficulty': 'easy',
    'npcRole': 'Kasiyer',
    'steps': [
      {
        'id': 'm1',
        'type': 'npcSpeak',
        'speaker': 'Kasiyer',
        'text': 'Merhaba! Bugün ne almak istersiniz?',
      },
      {
        'id': 'm2',
        'type': 'studentChoice',
        'text': 'Ne alıyorsun?',
        'hint': 'Süt iste.',
        'choices': [
          {'id': 'milk', 'label': 'Süt istiyorum.', 'correct': true},
          {'id': 'no', 'label': 'Bir şey istemiyorum.', 'correct': false},
        ],
      },
      {
        'id': 'm3',
        'type': 'npcSpeak',
        'speaker': 'Kasiyer',
        'text': 'Süt 30 TL.',
      },
      {
        'id': 'm4',
        'type': 'paymentChoice',
        'text': 'Parayı seç.',
        'choices': [
          {'id': '10', 'label': '10 TL', 'correct': false},
          {'id': '30', 'label': '30 TL', 'correct': true},
          {'id': '50', 'label': '50 TL', 'correct': false},
        ],
      },
      {
        'id': 'm5',
        'type': 'studentChoice',
        'text': 'Vedalaş.',
        'choices': [
          {'id': 't', 'label': 'Teşekkür ederim.', 'correct': true},
          {'id': 'x', 'label': 'Hadi.', 'correct': false},
        ],
      },
      {
        'id': 'm6',
        'type': 'complete',
        'speaker': 'Kasiyer',
        'text': 'İyi günler! Market senaryosu bitti.',
      },
    ],
  });

  static final grocery = DailyLifeScenario.fromMap(const {
    'scenario': 'grocery',
    'title': 'Bakkal',
    'description': 'Ekmek al ve teşekkür et',
    'difficulty': 'easy',
    'npcRole': 'Bakkal',
    'steps': [
      {
        'id': 'g1',
        'type': 'npcSpeak',
        'speaker': 'Bakkal',
        'text': 'Hoş geldin. Ne lazım?',
      },
      {
        'id': 'g2',
        'type': 'studentChoice',
        'text': 'Ne istersin?',
        'choices': [
          {'id': 'bread', 'label': 'Ekmek istiyorum.', 'correct': true},
          {'id': 'nothing', 'label': 'Bir şey yok.', 'correct': false},
        ],
      },
      {
        'id': 'g3',
        'type': 'npcSpeak',
        'speaker': 'Bakkal',
        'text': 'Buyur, ekmeğin 15 TL.',
      },
      {
        'id': 'g4',
        'type': 'paymentChoice',
        'text': 'Parayı seç.',
        'choices': [
          {'id': '5', 'label': '5 TL', 'correct': false},
          {'id': '15', 'label': '15 TL', 'correct': true},
          {'id': '20', 'label': '20 TL', 'correct': false},
        ],
      },
      {
        'id': 'g5',
        'type': 'complete',
        'speaker': 'Bakkal',
        'text': 'Güle güle kullan! Bakkal senaryosu bitti.',
      },
    ],
  });

  static final bakery = DailyLifeScenario.fromMap(const {
    'scenario': 'bakery',
    'title': 'Fırın',
    'description': 'Poğaça sipariş et',
    'difficulty': 'easy',
    'npcRole': 'Fırıncı',
    'steps': [
      {
        'id': 'b1',
        'type': 'npcSpeak',
        'speaker': 'Fırıncı',
        'text': 'Merhaba, ne arzu edersiniz?',
      },
      {
        'id': 'b2',
        'type': 'studentChoice',
        'text': 'Ne alıyorsun?',
        'choices': [
          {'id': 'pogaca', 'label': 'Poğaça istiyorum.', 'correct': true},
          {'id': 'water', 'label': 'Su istiyorum.', 'correct': false},
        ],
      },
      {
        'id': 'b3',
        'type': 'npcSpeak',
        'speaker': 'Fırıncı',
        'text': 'Poğaça 20 TL.',
      },
      {
        'id': 'b4',
        'type': 'paymentChoice',
        'text': 'Parayı seç.',
        'choices': [
          {'id': '10', 'label': '10 TL', 'correct': false},
          {'id': '20', 'label': '20 TL', 'correct': true},
          {'id': '50', 'label': '50 TL', 'correct': false},
        ],
      },
      {
        'id': 'b5',
        'type': 'studentChoice',
        'text': 'Ne dersin?',
        'choices': [
          {'id': 'thanks', 'label': 'Teşekkür ederim.', 'correct': true},
          {'id': 'no', 'label': 'Hayır.', 'correct': false},
        ],
      },
      {
        'id': 'b6',
        'type': 'complete',
        'speaker': 'Fırıncı',
        'text': 'Afiyet olsun! Fırın senaryosu bitti.',
      },
    ],
  });
}
