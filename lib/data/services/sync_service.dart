import 'dart:async';

import '../models/assistant_log.dart';
import '../repositories/log_queue_repository.dart';
import 'connectivity_service.dart';
import 'remote_log_client.dart';

/// Logları SQLite'a yazar; internet gelince uzak veritabanına fırlatır.
class SyncService {
  SyncService({
    required LogQueueRepository queue,
    required RemoteLogClient remote,
    required ConnectivityService connectivity,
  })  : _queue = queue,
        _remote = remote,
        _connectivity = connectivity;

  final LogQueueRepository _queue;
  final RemoteLogClient _remote;
  final ConnectivityService _connectivity;

  StreamSubscription<bool>? _connectivitySub;
  var _flushing = false;

  final _pendingCountController = StreamController<int>.broadcast();

  Stream<int> get pendingCountStream => _pendingCountController.stream;

  Future<int> get pendingCount => _queue.pendingCount();

  /// Uygulama açılışında çağrılır: bağlantı değişimini dinler.
  void start() {
    _connectivitySub ??= _connectivity.onStatusChanged.listen((online) {
      if (online) unawaited(flushPending());
    });
    unawaited(_emitPendingCount());
    unawaited(flushPending());
  }

  Future<void> enqueue(AssistantLog log) async {
    await _queue.enqueue(log);
    await _emitPendingCount();
    if (await _connectivity.isOnline) {
      await flushPending();
    }
  }

  /// Bekleyen logları uzak istemciye gönderir; başarıda synced işaretler.
  Future<int> flushPending() async {
    if (_flushing) return 0;
    if (!await _connectivity.isOnline) return 0;

    _flushing = true;
    var syncedTotal = 0;
    try {
      while (true) {
        final batch = await _queue.pending(limit: 50);
        if (batch.isEmpty) break;

        try {
          await _remote.upload(batch);
        } on OfflineSyncException {
          break;
        } on Exception {
          // Kalıcı hata: bir sonraki bağlantıda tekrar dene.
          break;
        }

        final ids = batch.map((l) => l.id).whereType<int>().toList();
        await _queue.markSynced(ids);
        syncedTotal += ids.length;
      }
    } finally {
      _flushing = false;
      await _emitPendingCount();
    }
    return syncedTotal;
  }

  Future<void> _emitPendingCount() async {
    if (!_pendingCountController.isClosed) {
      _pendingCountController.add(await _queue.pendingCount());
    }
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    await _pendingCountController.close();
  }
}
