/// Test amaçlı sabit demo hesaplar (geliştirme / manuel QA).
class TestAccounts {
  const TestAccounts._();

  static const parent = TestAccount(
    email: 'veli@luluna.app',
    password: 'veli12',
    displayName: 'Demo Veli',
    roleHint: 'veli',
  );

  static const therapist = TestAccount(
    email: 'terapi@luluna.app',
    password: 'terapi',
    displayName: 'Demo Terapist',
    roleHint: 'terapist',
  );

  static const all = [parent, therapist];
}

class TestAccount {
  const TestAccount({
    required this.email,
    required this.password,
    required this.displayName,
    required this.roleHint,
  });

  final String email;
  final String password;
  final String displayName;
  final String roleHint;
}
