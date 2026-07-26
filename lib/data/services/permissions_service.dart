import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sistem izinlerini (mikrofon, bildirim, Bluetooth) yönetir.
///
/// İzin karşılama ekranının görüldüğü bilgisi kullanıcıya göre ayrılır;
/// OS izinleri cihaz geneli kalır.
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
    return PermissionSnapshot(
      microphone: await Permission.microphone.status,
      notification: await Permission.notification.status,
      bluetooth: await Permission.bluetoothConnect.status,
    );
  }

  Future<PermissionSnapshot> requestAll() async {
    await [
      Permission.microphone,
      Permission.notification,
      Permission.bluetoothConnect,
    ].request();
    await markIntroSeen();
    return current();
  }
}

class PermissionSnapshot {
  const PermissionSnapshot({
    required this.microphone,
    required this.notification,
    required this.bluetooth,
  });

  final PermissionStatus microphone;
  final PermissionStatus notification;
  final PermissionStatus bluetooth;

  bool get allGranted =>
      microphone.isGranted &&
      notification.isGranted &&
      bluetooth.isGranted;
}
