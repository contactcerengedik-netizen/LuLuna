import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:luluna/data/hardware/ble_audio_output.dart';
import 'package:luluna/data/hardware/esp32_mic_client.dart';
import 'package:luluna/data/hardware/esp32_stream_client.dart';
import 'package:luluna/data/hardware/frame_sampler.dart';
import 'package:luluna/data/hardware/hardware_monitor.dart';
import 'package:luluna/data/hardware/minimal_jpeg.dart';
import 'package:luluna/data/hardware/pcm_audio_stats.dart';
import 'package:luluna/data/models/assistant_log.dart';
import 'package:luluna/data/repositories/assistant_repository.dart';

class _FakeAssistant implements AssistantRepository {
  final observations = <(String, List<int>?)>[];
  final _controller = StreamController<AssistantLog>.broadcast();

  @override
  Stream<AssistantLog> watchLogs() => _controller.stream;

  @override
  Future<void> processObservation(
    String observation, {
    List<int>? jpegBytes,
  }) async {
    observations.add((observation, jpegBytes));
  }

  @override
  void dispose() => _controller.close();
}

class _LoudMicClient extends Esp32MicClient {
  _LoudMicClient() : super(baseUrl: 'http://test');

  @override
  Future<Esp32MicSample> fetchSample() async {
    return const Esp32MicSample(
      available: true,
      pcmBytes: [],
      sampleRate: 16000,
      stats: PcmAudioStats(sampleCount: 100, rms: 0.4, peak: 0.7),
    );
  }
}

void main() {
  test('minimal JPEG geçerli SOI/EOI işaretleri içerir', () {
    final bytes = minimalJpegBytes();
    expect(bytes[0], 0xFF);
    expect(bytes[1], 0xD8);
    expect(bytes[bytes.length - 2], 0xFF);
    expect(bytes[bytes.length - 1], 0xD9);
  });

  test('MockCameraStreamClient periyodik kare üretir', () async {
    final client = MockCameraStreamClient();
    final frames = <List<int>>[];
    final sub = client
        .watchFrames(interval: const Duration(milliseconds: 50))
        .listen(frames.add);

    await Future<void>.delayed(const Duration(milliseconds: 180));
    await sub.cancel();
    await client.dispose();

    expect(frames.length, greaterThanOrEqualTo(2));
    expect(frames.first, isNotEmpty);
  });

  test('FrameSampler minInterval altında tekrar emit etmez', () async {
    final client = MockCameraStreamClient();
    final sampler = FrameSampler(
      client: client,
      minInterval: const Duration(milliseconds: 200),
    );
    final frames = <List<int>>[];
    final sub = sampler.frames.listen(frames.add);
    sampler.start();

    await Future<void>.delayed(const Duration(milliseconds: 250));
    await sub.cancel();
    await sampler.dispose();

    expect(frames, isNotEmpty);
    expect(sampler.latestFrame, isNotNull);
  });

  test('HardwareMonitor mock modda asistanı JPEG ile çağırır', () async {
    final assistant = _FakeAssistant();
    final ble = NoopBleAudioOutput();
    final monitor = HardwareMonitor(
      assistant: assistant,
      bleAudio: ble,
      sampleInterval: const Duration(milliseconds: 40),
    );

    await monitor.startMock();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await monitor.stop();
    await monitor.dispose();
    assistant.dispose();

    expect(monitor.mode, MonitorMode.idle);
    expect(assistant.observations, isNotEmpty);
    expect(assistant.observations.first.$2, isNotNull);
    expect(ble.isConnected, isTrue);
  });

  test('HardwareMonitor live modda mik enerjisini gözleme ekler', () async {
    final assistant = _FakeAssistant();
    final ble = NoopBleAudioOutput();
    final monitor = HardwareMonitor(
      assistant: assistant,
      bleAudio: ble,
      sampleInterval: const Duration(milliseconds: 40),
      liveStreamFactory: (_) => MockCameraStreamClient(),
      micClientFactory: (_) => _LoudMicClient(),
    );

    await monitor.startLive('http://esp32.test');
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await monitor.stop();
    await monitor.dispose();
    assistant.dispose();

    expect(assistant.observations, isNotEmpty);
    expect(
      assistant.observations.first.$1,
      contains('Ortam sesi RMS'),
    );
    expect(
      assistant.observations.first.$1,
      contains('yüksek ses'),
    );
  });
}
