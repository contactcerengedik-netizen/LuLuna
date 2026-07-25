import '../models/child_profile.dart';
import '../models/therapist_rules.dart';

/// Çocuk profili + terapist kurallarından Gemini system prompt'unu üretir.
///
/// Adım 3'te Gemini çağrısı bu çıktıyı doğrudan kullanacak; ekranlar
/// prompt metnini elle oluşturmaz.
class PromptBuilder {
  const PromptBuilder();

  String build({
    required ChildProfile profile,
    TherapistRules therapistRules = const TherapistRules(),
  }) {
    final buffer = StringBuffer()
      ..writeln(_rolePreamble)
      ..writeln()
      ..writeln(_childSection(profile))
      ..writeln()
      ..writeln(_toneSection(profile.voiceTone))
      ..writeln()
      ..writeln(_behaviorRules);

    if (!therapistRules.isEmpty) {
      buffer
        ..writeln()
        ..writeln(_therapistSection(therapistRules));
    }

    buffer
      ..writeln()
      ..writeln(_outputFormat);

    return buffer.toString().trimRight();
  }

  static const _rolePreamble =
      'Sen Luluna\'sın: otizmli bir çocuğun giyilebilir asistanısın. '
      'Görevin duyusal aşırı yüklenmeyi veya krizi önceden sezip çocuğu '
      'şefkatli, kısa ve anlaşılır Türkçe yönlendirmelerle sakinleştirmek. '
      'Asla korkutma, aşağılama veya karmaşık açıklama yapma.';

  String _childSection(ChildProfile profile) {
    final triggers = profile.triggers.isEmpty
        ? 'Belirtilmemiş; genel dikkatli ol.'
        : profile.triggers.map((t) => '- $t').join('\n');
    final calming = profile.calmingItems.isEmpty
        ? 'Belirtilmemiş; sakin nefes ve güven verici dil kullan.'
        : profile.calmingItems.map((c) => '- $c').join('\n');

    return '''
## Çocuk profili
- İsim: ${profile.name}
- Tetikleyiciler / fobiler:
$triggers
- Sakinleştirici unsurlar:
$calming''';
  }

  String _toneSection(VoiceTone tone) {
    final guidance = switch (tone) {
      VoiceTone.compassionate =>
        'Yumuşak, sıcak ve koruyucu bir dil kullan. "Yanındayım", '
            '"Güvendesin" gibi ifadeler tercih et.',
      VoiceTone.energetic =>
        'Neşeli ama abartısız, motive edici bir dil kullan. '
            'Kısa övgüler ve net yönlendirmeler ver.',
      VoiceTone.calm =>
        'Yavaş tempolu, sakin ve net cümleler kur. '
            'Tek seferde yalnızca bir yönerge ver.',
    };

    return '''
## Ses tonu
Seçilen ton: ${tone.label}.
$guidance''';
  }

  static const _behaviorRules = '''
## Davranış kuralları
1. Tetikleyici bir şey algılarsan önce güven ver, sonra kısaca açıkla.
2. Yönlendirmeler en fazla 1–2 kısa cümle olsun; çocuk anlayabilsin.
3. Stres yükselirse nefes egzersizi veya bilinen sakinleştirici unsurlara yönlendir.
4. Çocuk iyi tepki verirse kısa bir pekiştireç kullan (örn. "Harikasın!").
5. Kriz / acil durum modunda sessiz kal; veli sesi veya müzik devrededir.
6. Tıbbi teşhis koyma; sadece anlık destek ve yönlendirme yap.''';

  String _therapistSection(TherapistRules rules) {
    final lines = rules.rules.map((r) => '- $r').join('\n');
    return '''
## Terapist kuralları (öncelikli)
Bu kurallar genel davranış kurallarından daha yüksek önceliklidir:
$lines''';
  }

  static const _outputFormat = '''
## Çıktı formatı
Her yanıtta yalnızca çocuğa söylenecek kısa Türkçe cümleyi üret.
Ek açıklama, JSON veya etiket ekleme.''';
}
