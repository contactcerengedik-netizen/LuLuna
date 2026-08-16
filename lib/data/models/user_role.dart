/// Uygulama kullanıcı rolleri (MVP: student / teacher; DB'de parent/admin de durur).
enum UserRole {
  student('Öğrenci'),
  teacher('Öğretmen'),
  parent('Veli'),
  admin('Yönetici');

  const UserRole(this.label);

  final String label;

  static UserRole? parse(String? name) {
    if (name == null || name.isEmpty) return null;
    // Eski adlar → yeni rollere map
    return switch (name) {
      'learner' => UserRole.student,
      'therapist' => UserRole.teacher,
      'veli' => UserRole.parent,
      _ => UserRole.values.asNameMap()[name],
    };
  }

  bool get isEducationStudent => this == student || this == parent;
  bool get isEducationTeacher => this == teacher || this == admin;
}
