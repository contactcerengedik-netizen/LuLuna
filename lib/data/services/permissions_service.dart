import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Temel uygulama izinleri (sesli yönerge, bildirim).
/// İzinler isteğe bağlıdır; reddedilse veya platform desteklemese
/// onboarding yine de tamamlanır.
class PermissionsService {
  PermissionsService(this._prefs, {this.userId});

  final SharedPreferences _prefs;
  final String? userId;

  static const _introSeenKey = 'permissions_intro_seen';

  String get _key =>
      userId == null ? _introSeenKey : '${_introSeenKey}_$userId';

  bool get introSeen => _prefs.getBool(_key) ?? false;

  Future<void> markIntroSeen() => _prefs.setBool(_key, true);

  Future<PermissionSnapshot> current() async {
    try {
      return PermissionSnapshot(
        microphone: await Permission.microphone.status,
        notification: await Permission.notification.status,
      );
    } catch (_) {
      return const PermissionSnapshot(
        microphone: PermissionStatus.denied,
        notification: PermissionStatus.denied,
      );
    }
  }

  /// İzin ister; red / hata olsa bile [markIntroSeen] yapılır.
  Future<PermissionSnapshot> requestAll() async {
    try {
      // Web'de permission_handler çoğu izni desteklemez / hata fırlatabilir.
      if (!kIsWeb) {
        await [
          Permission.microphone,
          Permission.notification,
        ].request();
      } else {
        try {
          await Permission.microphone.request();
        } catch (_) {}
        try {
          await Permission.notification.request();
        } catch (_) {}
      }
    } catch (_) {
      // Reddedildi veya desteklenmiyor — akışı bozma.
    }
    await markIntroSeen();
    return current();
  }
}

class PermissionSnapshot {
  const PermissionSnapshot({
    required this.microphone,
    required this.notification,
  });

  final PermissionStatus microphone;
  final PermissionStatus notification;

  bool get allGranted => microphone.isGranted && notification.isGranted;
}
