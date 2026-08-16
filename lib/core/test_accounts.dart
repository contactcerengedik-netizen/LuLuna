/// Test / demo hesaplar.
class TestAccounts {
  const TestAccounts._();

  static const student = TestAccount(
    email: 'student@demo.com',
    password: 'demo1234',
    displayName: 'Demo Öğrenci',
    roleHint: 'student',
  );

  static const teacher = TestAccount(
    email: 'teacher@demo.com',
    password: 'demo1234',
    displayName: 'Demo Öğretmen',
    roleHint: 'teacher',
  );

  static const parent = TestAccount(
    email: 'veli@demo.com',
    password: 'demo1234',
    displayName: 'Demo Veli',
    roleHint: 'parent',
  );

  static const all = [student, teacher, parent];
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
