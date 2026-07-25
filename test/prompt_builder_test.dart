import 'package:flutter_test/flutter_test.dart';
import 'package:luluna/data/ai/prompt_builder.dart';
import 'package:luluna/data/models/child_profile.dart';
import 'package:luluna/data/models/therapist_rules.dart';

void main() {
  const builder = PromptBuilder();

  final profile = ChildProfile(
    name: 'Ela',
    triggers: const ['Yüksek ses', 'Köpek'],
    calmingItems: const ['Annesinin sesi'],
    voiceTone: VoiceTone.calm,
  );

  test('profil alanlarını system prompt içine enjekte eder', () {
    final prompt = builder.build(profile: profile);

    expect(prompt, contains('Ela'));
    expect(prompt, contains('Yüksek ses'));
    expect(prompt, contains('Köpek'));
    expect(prompt, contains('Annesinin sesi'));
    expect(prompt, contains('Sakin'));
    expect(prompt, contains('Tek seferde yalnızca bir yönerge'));
    expect(prompt, isNot(contains('Terapist kuralları')));
  });

  test('terapist kurallarını öncelikli bölüm olarak ekler', () {
    final prompt = builder.build(
      profile: profile,
      therapistRules: const TherapistRules(
        rules: [
          'Kalabalık ortamlarda komut verme, sadece nefes egzersizi yaptır.',
        ],
      ),
    );

    expect(prompt, contains('Terapist kuralları (öncelikli)'));
    expect(
      prompt,
      contains(
        'Kalabalık ortamlarda komut verme, sadece nefes egzersizi yaptır.',
      ),
    );
  });

  test('ses tonuna göre farklı rehberlik üretir', () {
    final energetic = builder.build(
      profile: profile.copyWith(voiceTone: VoiceTone.energetic),
    );
    final compassionate = builder.build(
      profile: profile.copyWith(voiceTone: VoiceTone.compassionate),
    );

    expect(energetic, contains('Neşeli ama abartısız'));
    expect(compassionate, contains('Yumuşak, sıcak ve koruyucu'));
  });
}
