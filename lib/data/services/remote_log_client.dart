import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/assistant_log.dart';
import '../models/queued_log.dart';

/// Uzak log deposu (Supabase / Firebase Functions) arayüzü.
abstract class RemoteLogClient {
  Future<void> upload(List<QueuedLog> logs);

  /// Rapor geçmişini desteklemeyen uç noktalar boş liste döndürür.
  Future<List<AssistantLog>> fetchRecent({int limit = 1000}) async => const [];
}

/// Kuluçka demosu: SYNC_ENDPOINT yoksa logları bellekte tutar.
class InMemoryRemoteLogClient implements RemoteLogClient {
  final uploaded = <QueuedLog>[];

  @override
  Future<void> upload(List<QueuedLog> logs) async {
    uploaded.addAll(logs);
  }

  @override
  Future<List<AssistantLog>> fetchRecent({int limit = 1000}) async => const [];
}

/// Dio ile gerçek HTTP POST. Interceptor, ağ hatalarını OfflineSyncException
/// olarak etiketler; SyncService kuyruğu bozmadan sonra tekrar dener.
class DioRemoteLogClient implements RemoteLogClient {
  DioRemoteLogClient({required this.endpoint, Dio? dio}) : _dio = dio ?? Dio() {
    _dio.interceptors.add(LogSyncInterceptor());
  }

  final String endpoint;
  final Dio _dio;

  @override
  Future<void> upload(List<QueuedLog> logs) async {
    if (logs.isEmpty) return;
    try {
      await _dio.post<void>(
        endpoint,
        data: {'logs': logs.map((l) => l.toRemotePayload()).toList()},
      );
    } on DioException catch (e) {
      final offline = e.error;
      if (offline is OfflineSyncException) throw offline;
      rethrow;
    }
  }

  @override
  Future<List<AssistantLog>> fetchRecent({int limit = 1000}) async => const [];
}

/// Supabase `assistant_logs` tablosuna yazan gerçek istemci.
/// Oturum yoksa OfflineSyncException fırlatır; kuyruk bozulmaz,
/// giriş yapılınca SyncService tekrar dener.
class SupabaseRemoteLogClient implements RemoteLogClient {
  SupabaseRemoteLogClient(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upload(List<QueuedLog> logs) async {
    if (logs.isEmpty) return;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw OfflineSyncException('Oturum yok — log senkronu ertelendi');
    }
    await _client.from('assistant_logs').insert([
      for (final log in logs)
        {
          'user_id': userId,
          'logged_at': log.timestamp.toIso8601String(),
          'type': log.type.name,
          'message': log.message,
        },
    ]);
  }

  @override
  Future<List<AssistantLog>> fetchRecent({int limit = 1000}) async {
    if (_client.auth.currentUser == null) return const [];
    final rows = await _client
        .from('assistant_logs')
        .select('logged_at,type,message')
        .order('logged_at', ascending: false)
        .limit(limit);

    return rows.map(_parseLog).whereType<AssistantLog>().toList();
  }

  static AssistantLog? _parseLog(Map<String, dynamic> row) {
    final timestamp = DateTime.tryParse(row['logged_at'] as String? ?? '');
    final type = LogType.values.asNameMap()[row['type'] as String?];
    final message = row['message'] as String?;
    if (timestamp == null || type == null || message == null) return null;
    return AssistantLog(
      timestamp: timestamp.toLocal(),
      type: type,
      message: message,
    );
  }
}

/// Senkron isteklerinde bağlantı kopmasını ayırt etmek için etiketler.
class LogSyncInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_isConnectivityError(err)) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          type: err.type,
          response: err.response,
          message: err.message,
          error: OfflineSyncException(err.message ?? 'Çevrimdışı'),
        ),
      );
      return;
    }
    handler.next(err);
  }

  static bool _isConnectivityError(DioException err) {
    return err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.unknown;
  }
}

class OfflineSyncException implements Exception {
  OfflineSyncException(this.message);

  final String message;

  @override
  String toString() => 'OfflineSyncException: $message';
}
