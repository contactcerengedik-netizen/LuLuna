import 'dart:async';

import '../repositories/assistant_repository.dart';
import 'ble_audio_output.dart';
import 'esp32_stream_client.dart';
import 'frame_sampler.dart';

enum MonitorMode { idle, mock, live }

/// ESP32 kare akışını asistan pipeline'ına bağlayan orkestratör.
class HardwareMonitor {
  HardwareMonitor({
    required AssistantRepository assistant,
    required BleAudioOutput bleAudio,
    this.sampleInterval = const Duration(seconds: 1),
  })  : _assistant = assistant,
        _bleAudio = bleAudio;

  final AssistantRepository _assistant;
  final BleAudioOutput _bleAudio;
  final Duration sampleInterval;

  FrameSampler? _sampler;
  StreamSubscription<List<int>>? _frameSub;
  MonitorMode _mode = MonitorMode.idle;
  var _busy = false;
  var _frameIndex = 0;

  MonitorMode get mode => _mode;

  bool get isRunning => _mode != MonitorMode.idle;

  /// Donanımsız demo: sahte JPEG → Gemini/mock pipeline.
  Future<void> startMock() async {
    await stop();
    final client = MockCameraStreamClient();
    await _begin(client, MonitorMode.mock);
  }

  /// Gerçek ESP32: `http://host` tabanlı /capture örnekleme.
  Future<void> startLive(String baseUrl) async {
    await stop();
    final normalized = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final client = HttpCaptureStreamClient(baseUrl: normalized);
    await _begin(client, MonitorMode.live);
  }

  Future<void> _begin(CameraStreamClient client, MonitorMode mode) async {
    _mode = mode;
    if (!_bleAudio.isConnected) {
      await _bleAudio.connect();
    }
    _sampler = FrameSampler(client: client, minInterval: sampleInterval);
    _frameSub = _sampler!.frames.listen(_onFrame);
    _sampler!.start();
  }

  Future<void> _onFrame(List<int> jpeg) async {
    if (_busy) return;
    _busy = true;
    _frameIndex++;
    try {
      await _assistant.processObservation(
        'Kamera karesi #$_frameIndex alındı. '
        'Görüntüdeki olası tetikleyicileri değerlendir.',
        jpegBytes: jpeg,
      );
    } finally {
      _busy = false;
    }
  }

  Future<void> stop() async {
    await _frameSub?.cancel();
    _frameSub = null;
    await _sampler?.dispose();
    _sampler = null;
    _mode = MonitorMode.idle;
    _frameIndex = 0;
  }

  Future<void> dispose() async {
    await stop();
  }
}
