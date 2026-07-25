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
  });

  final DeviceConnection connection;
  final int batteryPercent;

  bool get isConnected => connection != DeviceConnection.disconnected;
}
