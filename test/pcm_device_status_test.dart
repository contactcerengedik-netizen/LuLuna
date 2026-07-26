import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:luluna/data/hardware/pcm_audio_stats.dart';
import 'package:luluna/data/models/device_status.dart';

void main() {
  group('analyzePcm16leMono', () {
    test('boş buffer sıfır istatistik döner', () {
      final stats = analyzePcm16leMono(const []);
      expect(stats.sampleCount, 0);
      expect(stats.rms, 0);
      expect(stats.isLoud, isFalse);
    });

    test('yüksek genlikli sinüs benzeri örnekleri yüksek RMS sayar', () {
      final samples = Int16List(64);
      for (var i = 0; i < samples.length; i++) {
        samples[i] = i.isEven ? 20000 : -20000;
      }
      final stats = analyzePcm16leMono(samples.buffer.asUint8List());
      expect(stats.sampleCount, 64);
      expect(stats.rms, greaterThan(0.5));
      expect(stats.isLoud, isTrue);
    });

    test('sessiz örnekler yüksek ses sayılmaz', () {
      final samples = Int16List.fromList(List.filled(32, 40));
      final stats = analyzePcm16leMono(samples.buffer.asUint8List());
      expect(stats.isLoud, isFalse);
      expect(stats.rms, lessThan(0.05));
    });
  });

  group('DeviceStatus.fromEsp32StatusJson', () {
    test('yeni alanları parse eder', () {
      final status = DeviceStatus.fromEsp32StatusJson({
        'battery': 73,
        'battery_source': 'adc',
        'mic_available': true,
        'uptime_ms': 9000,
        'free_heap': 110000,
      });
      expect(status.batteryPercent, 73);
      expect(status.batterySource, 'adc');
      expect(status.micAvailable, isTrue);
      expect(status.uptimeMs, 9000);
      expect(status.batteryLabel, '%73 (ADC)');
      expect(status.isConnected, isTrue);
    });
  });
}
