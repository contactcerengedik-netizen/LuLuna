import '../../dialogue/domain/dialogue_models.dart';

/// Konuşma / iletişim / duygu diyalog setleri (Faz 15).
/// Üçü de aynı [DialogueRunnerEngine] ile çalışır.
abstract final class SocialDialogueCatalog {
  static Dialogue pronunciation({String word = 'elma'}) {
    final w = word.trim().isEmpty ? 'elma' : word.trim().toLowerCase();
    return Dialogue(
      id: 'speech-pronounce-$w',
      topic: 'Telaffuz: $w',
      level: 'easy',
      turns: [
        DialogueTurn(
          id: 'p1',
          speaker: DialogueSpeaker.aiCharacter,
          text: 'Benimle tekrar et: “$w”.',
          responseType: DialogueResponseType.freeSpeech,
          expectedKeywords: [w],
          imageUrl: 'mock://speech/pronounce/$w',
          onCorrectFeedback: 'Harika söyledin!',
          onIncorrectFeedback: 'Bir daha “$w” demeyi dene.',
        ),
        DialogueTurn(
          id: 'p2',
          speaker: DialogueSpeaker.aiCharacter,
          text: 'Hangisi “$w”?',
          responseType: DialogueResponseType.choice,
          choices: [w, 'masa', 'araba'],
        ),
        DialogueTurn(
          id: 'p3',
          speaker: DialogueSpeaker.aiCharacter,
          text: 'Aferin! Telaffuz bitti.',
          responseType: DialogueResponseType.none,
        ),
      ],
    );
  }

  static Dialogue communication() {
    return const Dialogue(
      id: 'speech-comm-1',
      topic: 'İletişim',
      level: 'easy',
      turns: [
        DialogueTurn(
          id: 'c1',
          speaker: DialogueSpeaker.aiCharacter,
          text: 'Susadın. Ne istersin?',
          responseType: DialogueResponseType.choice,
          choices: ['Su istiyorum', 'Top istiyorum', 'Uyumak istiyorum'],
          onCorrectFeedback: 'Evet, su isteyebilirsin.',
          imageUrl: 'mock://speech/comm/thirst',
        ),
        DialogueTurn(
          id: 'c2',
          speaker: DialogueSpeaker.aiCharacter,
          text: 'Şimdi söyle: “Su lütfen”.',
          responseType: DialogueResponseType.freeSpeech,
          expectedKeywords: ['su'],
          onCorrectFeedback: 'Çok nazik oldun!',
          onIncorrectFeedback: '“Su” kelimesini duymak istiyorum.',
        ),
        DialogueTurn(
          id: 'c3',
          speaker: DialogueSpeaker.aiCharacter,
          text: 'Teşekkürler. İletişim turu bitti.',
          responseType: DialogueResponseType.none,
        ),
      ],
    );
  }

  static Dialogue emotionSocial() {
    return const Dialogue(
      id: 'speech-emotion-1',
      topic: 'Duygu / Sosyal',
      level: 'medium',
      turns: [
        DialogueTurn(
          id: 'e1',
          speaker: DialogueSpeaker.aiCharacter,
          text: 'Bu çocuk üzgün görünüyor. Neden üzgün olabilir?',
          responseType: DialogueResponseType.choice,
          choices: [
            'Oyuncağı kırıldı',
            'Güneş parlıyor',
            'Top oynuyor',
          ],
          imageUrl: 'mock://speech/emotion/sad',
          onCorrectFeedback: 'Evet, oyuncağı kırılınca üzülebilir.',
          onIncorrectFeedback: 'Üzgün yüzüne tekrar bak.',
        ),
        DialogueTurn(
          id: 'e2',
          speaker: DialogueSpeaker.aiCharacter,
          text: 'Ona ne diyebiliriz?',
          responseType: DialogueResponseType.choice,
          choices: [
            'Yanındayım, yardım edebilirim',
            'Git buradan',
            'Gülmek zorundasın',
          ],
          onCorrectFeedback: 'Güzel bir destek cümlesi!',
        ),
        DialogueTurn(
          id: 'e3',
          speaker: DialogueSpeaker.aiCharacter,
          text: 'Şimdi “üzgün” de.',
          responseType: DialogueResponseType.freeSpeech,
          expectedKeywords: ['üzgün', 'uzgun'],
          onCorrectFeedback: 'Duyguyu adlandırdın.',
          onIncorrectFeedback: '“Üzgün” demeyi dene.',
        ),
        DialogueTurn(
          id: 'e4',
          speaker: DialogueSpeaker.aiCharacter,
          text: 'Aferin! Duygu konuşması bitti.',
          responseType: DialogueResponseType.none,
        ),
      ],
    );
  }
}

enum SocialSpeechModule {
  pronunciation('Telaffuz', 'Kelimeyi söyle, dinle'),
  communication('İletişim', 'İstek ve nazik konuşma'),
  emotion('Duygu / Sosyal', 'Yüz ifadesi ve destek');

  const SocialSpeechModule(this.label, this.subtitle);
  final String label;
  final String subtitle;

  Dialogue dialogue() => switch (this) {
        SocialSpeechModule.pronunciation =>
          SocialDialogueCatalog.pronunciation(),
        SocialSpeechModule.communication =>
          SocialDialogueCatalog.communication(),
        SocialSpeechModule.emotion => SocialDialogueCatalog.emotionSocial(),
      };
}
