import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luluna/data/services/permissions_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PermissionsService', () {
    test('izin reddi / hata olsa bile introSeen işaretlenir', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = PermissionsService(prefs, userId: 'demo');

      expect(svc.introSeen, isFalse);

      // Platform kanalı yokken request hata verebilir — yutulmalı.
      final snap = await svc.requestAll();
      expect(svc.introSeen, isTrue);
      expect(snap.microphone, isA<PermissionStatus>());
      expect(snap.notification, isA<PermissionStatus>());
    });

    test('markIntroSeen skip yolunu açar', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = PermissionsService(prefs, userId: 'u1');
      await svc.markIntroSeen();
      expect(svc.introSeen, isTrue);
    });
  });
}
