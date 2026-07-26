import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/navigation.dart';
import '../../data/hardware/hardware_monitor.dart';
import '../../data/providers.dart';

/// ESP32 Wi-Fi adresi, BLE çıkış ve izleme (mock/live) kontrolleri.
class DeviceConnectionScreen extends ConsumerStatefulWidget {
  const DeviceConnectionScreen({super.key});

  @override
  ConsumerState<DeviceConnectionScreen> createState() =>
      _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState
    extends ConsumerState<DeviceConnectionScreen> {
  late final TextEditingController _urlController;
  late final TextEditingController _bleController;
  var _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final url = ref.read(deviceRepositoryProvider).esp32BaseUrl ?? '';
    _urlController = TextEditingController(text: url);
    _bleController = TextEditingController(text: 'Luluna-Bone');
  }

  @override
  void dispose() {
    _urlController.dispose();
    _bleController.dispose();
    super.dispose();
  }

  Future<void> _saveUrl() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final url = _urlController.text.trim();
      await ref
          .read(deviceRepositoryProvider)
          .saveEsp32BaseUrl(url.isEmpty ? null : url);
      if (url.isNotEmpty) {
        final status = await ref.read(deviceRepositoryProvider).probeEsp32(url);
        setState(() {
          _message = status.isConnected
              ? 'ESP32 bağlı · ${status.batteryLabel}'
                    '${status.micAvailable ? ' · mik açık' : ' · mik yok'}'
              : 'ESP32 yanıt vermedi';
        });
      } else {
        setState(() => _message = 'ESP32 adresi temizlendi');
      }
    } catch (e) {
      setState(() => _message = 'Bağlantı hatası: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startMock() async {
    setState(() => _busy = true);
    await ref.read(hardwareMonitorProvider.notifier).startMock();
    if (mounted) {
      setState(() {
        _busy = false;
        _message = 'Mock kamera izlemesi başladı (1 fps)';
      });
    }
  }

  Future<void> _startLive() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _message = 'Önce ESP32 adresini kaydedin');
      return;
    }
    setState(() => _busy = true);
    await ref.read(deviceRepositoryProvider).saveEsp32BaseUrl(url);
    await ref.read(hardwareMonitorProvider.notifier).startLive(url);
    if (mounted) {
      setState(() {
        _busy = false;
        _message = 'Canlı ESP32 izlemesi başladı';
      });
    }
  }

  Future<void> _stop() async {
    setState(() => _busy = true);
    await ref.read(hardwareMonitorProvider.notifier).stop();
    if (mounted) {
      setState(() {
        _busy = false;
        _message = 'İzleme durduruldu';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(deviceStatusProvider).value;
    final monitor = ref.watch(hardwareMonitorProvider);
    final ble = ref.watch(bleAudioOutputProvider);

    return Scaffold(
      appBar: lulunaAppBar(context, title: 'Cihaz Bağlantısı'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
            Text(
            kDebugMode
                ? 'Gözlük (ESP32-CAM) Wi-Fi üzerinden kare ve (varsa) mik '
                      'örneği gönderir. Donanım yoksa Mock İzleme ile '
                      'pipeline test edilir.'
                : 'Gözlük (ESP32-CAM) Wi-Fi üzerinden kare ve ortam sesi '
                      'gönderir; ses çıkışı kemik iletimli kulaklığa yönlenir.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          const _PermissionsCard(),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: ListTile(
              leading: Icon(
                status?.isConnected == true
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              title: Text(status?.connection.label ?? 'Bağlı değil'),
              subtitle: Text(
                status == null
                    ? 'Durum bekleniyor…'
                    : '${status.batteryLabel} · '
                          'Mik: ${status.micAvailable ? 'hazır' : 'yok'} · '
                          'İzleme: ${_modeLabel(monitor.mode)}',
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'ESP32 adresi',
              hintText: 'http://192.168.1.42',
              prefixIcon: Icon(Icons.wifi_tethering),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bleController,
            decoration: const InputDecoration(
              labelText: 'BLE ses cihazı adı',
              hintText: 'Luluna-Bone',
              prefixIcon: Icon(Icons.hearing),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    await ble.connect(deviceName: _bleController.text.trim());
                    setState(
                      () => _message =
                          'BLE çıkış bağlandı: ${_bleController.text.trim()} '
                          '(yerel TTS fallback)',
                    );
                  },
            icon: const Icon(Icons.bluetooth_connected),
            label: Text(
              ble.isConnected ? 'BLE yeniden bağlan' : 'BLE çıkışa bağlan',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy ? null : _saveUrl,
            child: const Text('ESP32 adresini kaydet / yokla'),
          ),
          const SizedBox(height: 24),
          Text('İzleme', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              if (kDebugMode) ...[
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _busy || monitor.isRunning ? null : _startMock,
                    icon: const Icon(Icons.science),
                    label: const Text('Mock'),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy || monitor.isRunning ? null : _startLive,
                  icon: const Icon(Icons.videocam),
                  label: const Text('Canlı'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy || !monitor.isRunning ? null : _stop,
            icon: const Icon(Icons.stop),
            label: const Text('İzlemeyi durdur'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  String _modeLabel(MonitorMode mode) => switch (mode) {
    MonitorMode.idle => 'kapalı',
    MonitorMode.mock => 'mock',
    MonitorMode.live => 'canlı',
  };
}

class _PermissionsCard extends ConsumerStatefulWidget {
  const _PermissionsCard();

  @override
  ConsumerState<_PermissionsCard> createState() => _PermissionsCardState();
}

class _PermissionsCardState extends ConsumerState<_PermissionsCard> {
  var _busy = false;
  String? _summary;

  @override
  void initState() {
    super.initState();
    Future.microtask(_refresh);
  }

  Future<void> _refresh() async {
    final snap = await ref.read(permissionsServiceProvider).current();
    if (!mounted) return;
    setState(() {
      _summary = [
        'Mikrofon: ${snap.microphone.name}',
        'Bildirim: ${snap.notification.name}',
        'Bluetooth: ${snap.bluetooth.name}',
      ].join(' · ');
    });
  }

  Future<void> _request() async {
    setState(() => _busy = true);
    await ref.read(permissionsServiceProvider).requestAll();
    await _refresh();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.primaryContainer.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sistem izinleri',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Luluna’nın çalışması için Bluetooth ve bildirim '
              'izinlerine ihtiyacımız var. Mikrofon, kriz ses kaydı içindir.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_summary != null) ...[
              const SizedBox(height: 8),
              Text(_summary!, style: Theme.of(context).textTheme.labelSmall),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy ? null : _request,
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('İzinleri iste'),
            ),
          ],
        ),
      ),
    );
  }
}
