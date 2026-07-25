import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Ağ bağlantısı durumu. Testlerde FakeConnectivityService ile değiştirilir.
abstract class ConnectivityService {
  Future<bool> get isOnline;

  Stream<bool> get onStatusChanged;
}

class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  @override
  Stream<bool> get onStatusChanged =>
      _connectivity.onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );
}

/// Widget/birim testleri için kontrol edilebilir bağlantı durumu.
class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService({bool online = true}) : _online = online;

  bool _online;
  final _controller = StreamController<bool>.broadcast();

  set online(bool value) {
    _online = value;
    _controller.add(value);
  }

  @override
  Future<bool> get isOnline async => _online;

  @override
  Stream<bool> get onStatusChanged => _controller.stream;

  void dispose() => _controller.close();
}
