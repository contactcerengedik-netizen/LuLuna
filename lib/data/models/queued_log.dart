import 'assistant_log.dart';

/// SQLite kuyruğundaki tek bir asistan log kaydı.
class QueuedLog {
  const QueuedLog({
    this.id,
    required this.timestamp,
    required this.type,
    required this.message,
    this.synced = false,
  });

  final int? id;
  final DateTime timestamp;
  final LogType type;
  final String message;
  final bool synced;

  AssistantLog toAssistantLog() => AssistantLog(
        timestamp: timestamp,
        type: type,
        message: message,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        'message': message,
        'synced': synced ? 1 : 0,
      };

  factory QueuedLog.fromMap(Map<String, dynamic> map) {
    return QueuedLog(
      id: map['id'] as int?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      type: LogType.values.asNameMap()[map['type'] as String] ?? LogType.system,
      message: map['message'] as String,
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toRemotePayload() => {
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        'message': message,
      };
}
