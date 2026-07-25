import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/device_status.dart';

/// Gözlük modülünün (ESP32) durum ve bağlantı yönetimi.
abstract class DeviceRepository {
  Stream<DeviceStatus> watchStatus();

  String? get esp32BaseUrl;

  Future<void> saveEsp32BaseUrl(String? url);

  /// ESP32 `/status` uç noktasını yoklar; başarılıysa Wi-Fi bağlı sayılır.
  Future<DeviceStatus> probeEsp32(String baseUrl);

  void dispose();
}

class Esp32DeviceRepository implements DeviceRepository {
  Esp32DeviceRepository({
    required SharedPreferences prefs,
    Dio? dio,
  })  : _prefs = prefs,
        _dio = dio ?? Dio() {
    _controller = StreamController<DeviceStatus>.broadcast(
      onListen: _emitCurrent,
    );
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(_refresh());
    });
    unawaited(_refresh());
  }

  static const _urlKey = 'esp32_base_url';

  final SharedPreferences _prefs;
  final Dio _dio;
  late final StreamController<DeviceStatus> _controller;
  Timer? _pollTimer;
  DeviceStatus _status = const DeviceStatus(
    connection: DeviceConnection.disconnected,
    batteryPercent: 0,
  );

  @override
  String? get esp32BaseUrl => _prefs.getString(_urlKey);

  @override
  Future<void> saveEsp32BaseUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      await _prefs.remove(_urlKey);
    } else {
      var value = url.trim();
      if (value.endsWith('/')) {
        value = value.substring(0, value.length - 1);
      }
      await _prefs.setString(_urlKey, value);
    }
    await _refresh();
  }

  @override
  Stream<DeviceStatus> watchStatus() => _controller.stream;

  void _emitCurrent() {
    if (!_controller.isClosed) _controller.add(_status);
  }

  Future<void> _refresh() async {
    final url = esp32BaseUrl;
    if (url == null) {
      _status = const DeviceStatus(
        connection: DeviceConnection.disconnected,
        batteryPercent: 0,
      );
      _emitCurrent();
      return;
    }
    try {
      _status = await probeEsp32(url);
    } catch (_) {
      _status = const DeviceStatus(
        connection: DeviceConnection.disconnected,
        batteryPercent: 0,
      );
    }
    _emitCurrent();
  }

  @override
  Future<DeviceStatus> probeEsp32(String baseUrl) async {
    final normalized = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final response = await _dio.get<Map<String, dynamic>>(
      '$normalized/status',
      options: Options(
        receiveTimeout: const Duration(seconds: 3),
        sendTimeout: const Duration(seconds: 3),
      ),
    );
    final data = response.data ?? const {};
    final battery = (data['battery'] as num?)?.toInt() ?? 50;
    return DeviceStatus(
      connection: DeviceConnection.wifi,
      batteryPercent: battery.clamp(0, 100),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.close();
  }
}

/// Donanım yokken paneli dolduran sahte durum.
class MockDeviceRepository implements DeviceRepository {
  MockDeviceRepository() {
    _controller = StreamController<DeviceStatus>.broadcast(
      onListen: () {
        _controller.add(_status);
      },
    );
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      final next = (_status.batteryPercent - 1).clamp(5, 100);
      _status = DeviceStatus(
        connection: DeviceConnection.wifi,
        batteryPercent: next,
      );
      if (!_controller.isClosed) _controller.add(_status);
    });
  }

  late final StreamController<DeviceStatus> _controller;
  Timer? _timer;
  DeviceStatus _status = const DeviceStatus(
    connection: DeviceConnection.wifi,
    batteryPercent: 87,
  );
  String? _url;

  @override
  String? get esp32BaseUrl => _url;

  @override
  Future<void> saveEsp32BaseUrl(String? url) async {
    _url = url;
  }

  @override
  Stream<DeviceStatus> watchStatus() => _controller.stream;

  @override
  Future<DeviceStatus> probeEsp32(String baseUrl) async {
    return const DeviceStatus(
      connection: DeviceConnection.wifi,
      batteryPercent: 87,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
