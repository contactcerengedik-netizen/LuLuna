import 'package:flutter/services.dart';

/// Android ön plan servisini MethodChannel ile yönetir.
/// Uygulama arka plandayken "Luluna izliyor" bildirimi tutar.
class BackgroundMonitorService {
  BackgroundMonitorService({
    MethodChannel? channel,
  }) : _channel = channel ??
            const MethodChannel('com.example.luluna/background_monitor');

  final MethodChannel _channel;

  Future<void> start({String title = 'Luluna izliyor'}) async {
    try {
      await _channel.invokeMethod<void>('start', {'title': title});
    } on MissingPluginException {
      // iOS / masaüstü: sessizce yok say.
    } on PlatformException {
      // Emülatör veya izin sorunları MVP'yi kırmaz.
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      // ignore
    } on PlatformException {
      // ignore
    }
  }
}
