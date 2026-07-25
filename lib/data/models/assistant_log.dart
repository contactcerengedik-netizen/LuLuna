/// Asistanın ürettiği tek bir olay kaydı. Canlı akış ekranında mesaj
/// balonu olarak gösterilir; Adım 5'te SQLite kuyruğuna da yazılacak.
enum LogType {
  /// Çevresel gözlem: "Önde köpek görüldü."
  observation,

  /// Çocuğa iletilen yönlendirme: "Korkma, o sadece küçük bir köpek."
  intervention,

  /// Pekiştireç: "Harikasın!"
  praise,

  /// Sistem olayları: bağlantı, batarya, mod değişimi.
  system,
}

class AssistantLog {
  const AssistantLog({
    required this.timestamp,
    required this.type,
    required this.message,
  });

  final DateTime timestamp;
  final LogType type;
  final String message;
}
