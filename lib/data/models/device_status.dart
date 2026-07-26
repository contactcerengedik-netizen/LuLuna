enum DeviceConnection {
  disconnected('Bağlı değil'),
  bluetooth('Bluetooth'),
  wifi('Wi-Fi');

  const DeviceConnection(this.label);

  final String label;
}

/// Gözlük modülünün (ESP32) anlık durumu.
class DeviceStatus {
  const DeviceStatus({
    required this.connection,
    required this.batteryPercent,
    this.batterySource = 'unknown',
    this.micAvailable = false,
    this.uptimeMs = 0,
    this.freeHeap = 0,
  });

  final DeviceConnection connection;
  final int batteryPercent;

  /// `adc` | `estimated` | `unknown`
  final String batterySource;
  final bool micAvailable;
  final int uptimeMs;
  final int freeHeap;

  bool get isConnected => connection != DeviceConnection.disconnected;

  String get batteryLabel {
    final src = switch (batterySource) {
      'adc' => 'ADC',
      'estimated' => 'tahmini',
      _ => batterySource,
    };
    return '%$batteryPercent ($src)';
  }

  factory DeviceStatus.fromEsp32StatusJson(
    Map<String, dynamic> data, {
    DeviceConnection connection = DeviceConnection.wifi,
  }) {
    final battery = (data['battery'] as num?)?.toInt() ?? 50;
    return DeviceStatus(
      connection: connection,
      batteryPercent: battery.clamp(0, 100),
      batterySource: data['battery_source'] as String? ?? 'unknown',
      micAvailable: data['mic_available'] == true,
      uptimeMs: (data['uptime_ms'] as num?)?.toInt() ?? 0,
      freeHeap: (data['free_heap'] as num?)?.toInt() ?? 0,
    );
  }
}
