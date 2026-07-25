import 'package:flutter_test/flutter_test.dart';
import 'package:luluna/data/models/assistant_log.dart';
import 'package:luluna/data/repositories/log_queue_repository.dart';
import 'package:luluna/data/services/connectivity_service.dart';
import 'package:luluna/data/services/remote_log_client.dart';
import 'package:luluna/data/services/sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late LogQueueRepository queue;
  late InMemoryRemoteLogClient remote;
  late FakeConnectivityService connectivity;
  late SyncService sync;

  setUp(() async {
    queue = LogQueueRepository(
      databaseFactory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    remote = InMemoryRemoteLogClient();
    connectivity = FakeConnectivityService(online: false);
    sync = SyncService(
      queue: queue,
      remote: remote,
      connectivity: connectivity,
    );
  });

  tearDown(() async {
    await sync.dispose();
    await queue.close();
    connectivity.dispose();
  });

  test('çevrimdışıyken loglar kuyrukta birikir, uzak istemciye gitmez', () async {
    await sync.enqueue(
      AssistantLog(
        timestamp: DateTime.now(),
        type: LogType.observation,
        message: 'Köpek görüldü',
      ),
    );

    expect(await queue.pendingCount(), 1);
    expect(remote.uploaded, isEmpty);
  });

  test('internet gelince bekleyen loglar senkronize edilir', () async {
    await sync.enqueue(
      AssistantLog(
        timestamp: DateTime.now(),
        type: LogType.intervention,
        message: 'Sakin ol',
      ),
    );
    await sync.enqueue(
      AssistantLog(
        timestamp: DateTime.now(),
        type: LogType.praise,
        message: 'Harikasın!',
      ),
    );

    expect(await queue.pendingCount(), 2);

    connectivity.online = true;
    final synced = await sync.flushPending();

    expect(synced, 2);
    expect(await queue.pendingCount(), 0);
    expect(remote.uploaded, hasLength(2));
  });

  test('start() bağlantı gelince otomatik flush tetikler', () async {
    await sync.enqueue(
      AssistantLog(
        timestamp: DateTime.now(),
        type: LogType.system,
        message: 'test',
      ),
    );
    sync.start();

    connectivity.online = true;
    // stream listener async; kısa bekle
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sync.flushPending();

    expect(await queue.pendingCount(), 0);
    expect(remote.uploaded, isNotEmpty);
  });
}
