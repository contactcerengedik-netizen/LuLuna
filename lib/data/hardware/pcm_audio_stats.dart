import 'dart:math' as math;
import 'dart:typed_data';

/// 16-bit little-endian mono PCM örneklerinden ses enerjisi özeti.
class PcmAudioStats {
  const PcmAudioStats({
    required this.sampleCount,
    required this.rms,
    required this.peak,
  });

  final int sampleCount;

  /// 0..1 normalize RMS.
  final double rms;

  /// 0..1 normalize peak.
  final double peak;

  bool get isLoud => rms >= 0.18 || peak >= 0.55;
}

/// Ham PCM baytlarından istatistik üretir (saf — kolay test edilir).
PcmAudioStats analyzePcm16leMono(List<int> bytes) {
  if (bytes.length < 2) {
    return const PcmAudioStats(sampleCount: 0, rms: 0, peak: 0);
  }
  final evenLen = bytes.length - (bytes.length % 2);
  final data = Uint8List.fromList(bytes.sublist(0, evenLen));
  final samples = Int16List.view(data.buffer, data.offsetInBytes, evenLen ~/ 2);
  if (samples.isEmpty) {
    return const PcmAudioStats(sampleCount: 0, rms: 0, peak: 0);
  }

  var sumSq = 0.0;
  var peakAbs = 0;
  for (final sample in samples) {
    final abs = sample.abs();
    if (abs > peakAbs) peakAbs = abs;
    sumSq += sample * sample;
  }
  final rms = math.sqrt(sumSq / samples.length) / 32768.0;
  final peak = peakAbs / 32768.0;
  return PcmAudioStats(
    sampleCount: samples.length,
    rms: rms.clamp(0.0, 1.0),
    peak: peak.clamp(0.0, 1.0),
  );
}
