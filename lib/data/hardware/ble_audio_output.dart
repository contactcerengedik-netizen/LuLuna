import '../services/speech_service.dart';

/// Kemik iletimli kulaklık / yaka hoparlörüne ses yönlendirme arayüzü.
///
/// Gerçek GATT yazımı sonraki donanım iterasyonunda `flutter_blue_plus`
/// ile bağlanacak; şimdilik yerel TTS'e düşen implementasyon jüri
/// demosu ve birim testleri için yeterli.
abstract class BleAudioOutput {
  bool get isConnected;

  Future<void> connect({String deviceName = 'Luluna-Bone'});

  Future<void> disconnect();

  /// Metni cihaza iletir (BLE audio veya yerel hoparlör fallback).
  Future<void> playText(String text);
}

/// Telefon hoparlörüne düşen geçici çıkış — BLE bağlanana kadar.
class LocalBleAudioOutput implements BleAudioOutput {
  LocalBleAudioOutput(this._speech);

  final SpeechService _speech;
  var _connected = false;
  String? connectedName;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect({String deviceName = 'Luluna-Bone'}) async {
    connectedName = deviceName;
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    connectedName = null;
    await _speech.stop();
  }

  @override
  Future<void> playText(String text) async {
    if (!_connected) return;
    // BLE audio pipeline hazır olana kadar TTS yerel hoparlörden çıkar;
    // çağrı noktası aynı kalır, sadece alt katman değişir.
    await _speech.speak(text);
  }
}

class NoopBleAudioOutput implements BleAudioOutput {
  var _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect({String deviceName = 'Luluna-Bone'}) async {
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }

  @override
  Future<void> playText(String text) async {}
}
