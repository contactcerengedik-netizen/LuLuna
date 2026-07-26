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
    this.wifiMode = 'unknown',
    this.ip,
    this.hostname,
  });

  final DeviceConnection connection;
  final int batteryPercent;

  /// `adc` | `estimated` | `unknown`
  final String batterySource;
  final bool micAvailable;
  final int uptimeMs;
  final int freeHeap;

  /// `ap` | `sta` | `unknown`
  final String wifiMode;
  final String? ip;
  final String? hostname;

  bool get isConnected => connection != DeviceConnection.disconnected;

  bool get isProvisioningAp => wifiMode == 'ap';

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
      wifiMode: data['wifi_mode'] as String? ?? 'unknown',
      ip: data['ip'] as String?,
      hostname: data['hostname'] as String?,
    );
  }
}
