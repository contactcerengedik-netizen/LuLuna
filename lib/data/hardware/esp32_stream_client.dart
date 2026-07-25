import 'dart:async';

import 'package:dio/dio.dart';

import 'minimal_jpeg.dart';

/// ESP32-CAM'den periyodik JPEG kare üreten kaynak.
abstract class CameraStreamClient {
  /// [interval] sıklığında JPEG byte dizileri üretir.
  Stream<List<int>> watchFrames({
    Duration interval = const Duration(seconds: 1),
  });

  Future<void> dispose();
}

/// Gerçek donanım: `GET http://host/capture` ile kare örnekler.
class HttpCaptureStreamClient implements CameraStreamClient {
  HttpCaptureStreamClient({
    required this.baseUrl,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  /// Örn. `http://192.168.1.42` (trailing slash olmadan).
  final String baseUrl;
  final Dio _dio;
  Timer? _timer;
  StreamController<List<int>>? _controller;

  @override
  Stream<List<int>> watchFrames({
    Duration interval = const Duration(seconds: 1),
  }) {
    _controller?.close();
    final controller = StreamController<List<int>>.broadcast(
      onListen: () => _start(interval),
      onCancel: () {
        if (!(_controller?.hasListener ?? false)) _stop();
      },
    );
    _controller = controller;
    return controller.stream;
  }

  void _start(Duration interval) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _fetchFrame());
    unawaited(_fetchFrame());
  }

  Future<void> _fetchFrame() async {
    final controller = _controller;
    if (controller == null || controller.isClosed) return;
    try {
      final response = await _dio.get<List<int>>(
        '$baseUrl/capture',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes != null && bytes.isNotEmpty) {
        controller.add(bytes);
      }
    } catch (_) {
      // Geçici ağ hatası: bir sonraki tick'te tekrar dene.
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> dispose() async {
    _stop();
    await _controller?.close();
    _controller = null;
  }
}

/// Donanım yokken 1 fps sahte JPEG üretir (pipeline demo).
class MockCameraStreamClient implements CameraStreamClient {
  MockCameraStreamClient({List<int>? jpegBytes})
      : _jpeg = jpegBytes ?? minimalJpegBytes();

  final List<int> _jpeg;
  Timer? _timer;
  StreamController<List<int>>? _controller;

  @override
  Stream<List<int>> watchFrames({
    Duration interval = const Duration(seconds: 1),
  }) {
    _controller?.close();
    final controller = StreamController<List<int>>.broadcast();
    _controller = controller;
    _timer = Timer.periodic(interval, (_) {
      if (!controller.isClosed) controller.add(_jpeg);
    });
    // İlk kareyi hemen ver.
    scheduleMicrotask(() {
      if (!controller.isClosed) controller.add(_jpeg);
    });
    return controller.stream;
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    await _controller?.close();
    _controller = null;
  }
}
