import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luluna/data/models/auth_session.dart';
import 'package:luluna/data/models/child_profile.dart';
import 'package:luluna/data/repositories/auth_repository.dart';
import 'package:luluna/data/repositories/pairing_repository.dart';

void main() {
  const kvkk = KvkkConsent(
    privacyNotice: true,
    dataProcessing: true,
    healthData: true,
    micCamera: true,
  );

  test('kayıt oturum açmaz; giriş sonrası KVKK ayrı güncellenir', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = LocalAuthRepository(prefs);

    await auth.registerEmail(email: 'a@b.com', password: 'abcdef');
    expect(auth.loadSession(), isNull);

    final session = await auth.signInEmail(
      email: 'a@b.com',
      password: 'abcdef',
    );
    expect(session.isReady, isFalse);

    await auth.updateKvkk(kvkk);
    expect(auth.loadSession()?.isReady, isTrue);
  });

  test('veli kod üretir, terapist eşleşir', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final parentPairing = LocalPairingRepository(prefs, userId: 'parent-1');
    final therapistPairing = LocalPairingRepository(
      prefs,
      userId: 'therapist-1',
    );
    const profile = ChildProfile(name: 'Ela', triggers: ['Köpek']);

    final invite = await parentPairing.createOrRefreshInvite(profile: profile);
    expect(invite.code, startsWith('LUNA-'));
    expect(invite.parentId, 'parent-1');

    final joined = await therapistPairing.joinWithCode(invite.code);
    expect(joined.childName, 'Ela');
    expect(joined.parentId, 'parent-1');
    expect(therapistPairing.isPairedAsTherapist, isTrue);
    expect(ChildProfile.fromJson(joined.profileJson).triggers, ['Köpek']);
  });
}
