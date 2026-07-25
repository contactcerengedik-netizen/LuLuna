import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sistem izinlerini (mikrofon, bildirim, Bluetooth) yönetir.
class PermissionsService {
  PermissionsService(this._prefs);

  final SharedPreferences _prefs;

  static const _introSeenKey = 'permissions_intro_seen';

  bool get introSeen => _prefs.getBool(_introSeenKey) ?? false;

  Future<void> markIntroSeen() => _prefs.setBool(_introSeenKey, true);

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
