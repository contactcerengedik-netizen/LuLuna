import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/assistant_log.dart';
import '../models/queued_log.dart';

/// Yerel asistan log kuyruğu. İnternet yokken kayıtlar burada birikir;
/// SyncService internet gelince uzak veritabanına fırlatır.
class LogQueueRepository {
  LogQueueRepository({
    DatabaseFactory? databaseFactory,
    String? databasePath,
  })  : _factory = databaseFactory,
        _databasePath = databasePath;

  final DatabaseFactory? _factory;
  final String? _databasePath;
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final factory = _factory ?? databaseFactory;
    final path = _databasePath ??
        p.join(await getDatabasesPath(), 'luluna_logs.db');
    _db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE log_queue (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              timestamp TEXT NOT NULL,
              type TEXT NOT NULL,
              message TEXT NOT NULL,
              synced INTEGER NOT NULL DEFAULT 0
            )
          ''');
        },
      ),
    );
    return _db!;
  }

  Future<int> enqueue(AssistantLog log) async {
    final db = await database;
    return db.insert('log_queue', {
      'timestamp': log.timestamp.toIso8601String(),
      'type': log.type.name,
      'message': log.message,
      'synced': 0,
    });
  }

  Future<List<QueuedLog>> pending({int limit = 100}) async {
    final db = await database;
    final rows = await db.query(
      'log_queue',
      where: 'synced = 0',
      orderBy: 'id ASC',
      limit: limit,
    );
    return rows.map(QueuedLog.fromMap).toList();
  }

  Future<int> pendingCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM log_queue WHERE synced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> markSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE log_queue SET synced = 1 WHERE id IN ($placeholders)',
      ids,
    );
  }

  Future<void> clear() async {
    final db = await database;
    await db.delete('log_queue');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
