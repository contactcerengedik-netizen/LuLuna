import 'package:dio/dio.dart';

import 'pcm_audio_stats.dart';

/// ESP32 `/mic` uç noktasından alınan kısa PCM örneği.
class Esp32MicSample {
  const Esp32MicSample({
    required this.available,
    required this.pcmBytes,
    required this.sampleRate,
    required this.stats,
  });

  final bool available;
  final List<int> pcmBytes;
  final int sampleRate;
  final PcmAudioStats stats;

  bool get isLoud => available && stats.isLoud;
}

/// ESP32-CAM I2S mikrofon istemcisi.
class Esp32MicClient {
  Esp32MicClient({
    required this.baseUrl,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final String baseUrl;
  final Dio _dio;

  Future<Esp32MicSample> fetchSample() async {
    final normalized = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    try {
      final response = await _dio.get<List<int>>(
        '$normalized/mic',
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
          validateStatus: (code) =>
              code != null && (code == 200 || code == 204),
        ),
      );
      if (response.statusCode == 204 || response.data == null) {
        return const Esp32MicSample(
          available: false,
          pcmBytes: [],
          sampleRate: 16000,
          stats: PcmAudioStats(sampleCount: 0, rms: 0, peak: 0),
        );
      }
      final headers = response.headers.map;
      final availableHeader = headers['x-mic-available']?.first;
      final sampleRate =
          int.tryParse(headers['x-sample-rate']?.first ?? '') ?? 16000;
      final bytes = response.data!;
      final stats = analyzePcm16leMono(bytes);
      return Esp32MicSample(
        available: availableHeader != '0' && bytes.isNotEmpty,
        pcmBytes: bytes,
        sampleRate: sampleRate,
        stats: stats,
      );
    } catch (_) {
      return const Esp32MicSample(
        available: false,
        pcmBytes: [],
        sampleRate: 16000,
        stats: PcmAudioStats(sampleCount: 0, rms: 0, peak: 0),
      );
    }
  }
}
