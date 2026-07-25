import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/queued_log.dart';

/// Uzak log deposu (Supabase / Firebase Functions) arayüzü.
abstract class RemoteLogClient {
  Future<void> upload(List<QueuedLog> logs);
}

/// Kuluçka demosu: SYNC_ENDPOINT yoksa logları bellekte tutar.
class InMemoryRemoteLogClient implements RemoteLogClient {
  final uploaded = <QueuedLog>[];

  @override
  Future<void> upload(List<QueuedLog> logs) async {
    uploaded.addAll(logs);
  }
}

/// Dio ile gerçek HTTP POST. Interceptor, ağ hatalarını OfflineSyncException
/// olarak etiketler; SyncService kuyruğu bozmadan sonra tekrar dener.
class DioRemoteLogClient implements RemoteLogClient {
  DioRemoteLogClient({
    required this.endpoint,
    Dio? dio,
  }) : _dio = dio ?? Dio() {
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
        data: {
          'logs': logs.map((l) => l.toRemotePayload()).toList(),
        },
      );
    } on DioException catch (e) {
      final offline = e.error;
      if (offline is OfflineSyncException) throw offline;
      rethrow;
    }
  }
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
