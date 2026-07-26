import 'dart:async';

import '../repositories/assistant_repository.dart';
import 'ble_audio_output.dart';
import 'esp32_mic_client.dart';
import 'esp32_stream_client.dart';
import 'frame_sampler.dart';

enum MonitorMode { idle, mock, live }

/// ESP32 kare (ve opsiyonel mik) akışını asistan pipeline'ına bağlayan orkestratör.
class HardwareMonitor {
  HardwareMonitor({
    required AssistantRepository assistant,
    required BleAudioOutput bleAudio,
    this.sampleInterval = const Duration(seconds: 1),
    this.enableMicObservation = true,
    Esp32MicClient Function(String baseUrl)? micClientFactory,
    CameraStreamClient Function(String baseUrl)? liveStreamFactory,
  })  : _assistant = assistant,
        _bleAudio = bleAudio,
        _micClientFactory = micClientFactory ??
            ((url) => Esp32MicClient(baseUrl: url)),
        _liveStreamFactory = liveStreamFactory ??
            ((url) => HttpCaptureStreamClient(baseUrl: url));

  final AssistantRepository _assistant;
  final BleAudioOutput _bleAudio;
  final Duration sampleInterval;
  final bool enableMicObservation;
  final Esp32MicClient Function(String baseUrl) _micClientFactory;
  final CameraStreamClient Function(String baseUrl) _liveStreamFactory;

  FrameSampler? _sampler;
  Esp32MicClient? _micClient;
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
    await _begin(client, MonitorMode.mock, micClient: null);
  }

  /// Gerçek ESP32: `http://host` tabanlı /capture (+ opsiyonel /mic) örnekleme.
  Future<void> startLive(String baseUrl) async {
    await stop();
    final normalized = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final client = _liveStreamFactory(normalized);
    final mic = enableMicObservation ? _micClientFactory(normalized) : null;
    await _begin(client, MonitorMode.live, micClient: mic);
  }

  Future<void> _begin(
    CameraStreamClient client,
    MonitorMode mode, {
    Esp32MicClient? micClient,
  }) async {
    _mode = mode;
    _micClient = micClient;
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
      var observation =
          'Kamera karesi #$_frameIndex alındı. '
          'Görüntüdeki olası tetikleyicileri değerlendir.';

      final mic = _micClient;
      if (mic != null) {
        final sample = await mic.fetchSample();
        if (sample.available) {
          final rmsPct = (sample.stats.rms * 100).round();
          observation +=
              ' Ortam sesi RMS ~%$rmsPct'
              '${sample.isLoud ? ' (yüksek ses / gürültü olabilir).' : '.'}';
        }
      }

      await _assistant.processObservation(
        observation,
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
    _micClient = null;
    _mode = MonitorMode.idle;
    _frameIndex = 0;
  }

  Future<void> dispose() async {
    await stop();
  }
}
