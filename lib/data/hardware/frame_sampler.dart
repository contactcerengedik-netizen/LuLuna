import 'dart:async';

import 'esp32_stream_client.dart';

/// Kameradan gelen kareleri throttle eder (varsayılan 1 fps) ve
/// son JPEG'i tutar. HardwareMonitor bunu Gemini'ye yollar.
class FrameSampler {
  FrameSampler({
    required CameraStreamClient client,
    this.minInterval = const Duration(seconds: 1),
  }) : _client = client;

  final CameraStreamClient _client;
  final Duration minInterval;

  StreamSubscription<List<int>>? _sub;
  DateTime? _lastEmitted;
  final _controller = StreamController<List<int>>.broadcast();

  List<int>? latestFrame;

  Stream<List<int>> get frames => _controller.stream;

  void start() {
    _sub?.cancel();
    _sub = _client.watchFrames(interval: minInterval).listen((frame) {
      final now = DateTime.now();
      if (_lastEmitted != null &&
          now.difference(_lastEmitted!) < minInterval) {
        return;
      }
      _lastEmitted = now;
      latestFrame = frame;
      if (!_controller.isClosed) _controller.add(frame);
    });
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
    await _client.dispose();
  }
}
