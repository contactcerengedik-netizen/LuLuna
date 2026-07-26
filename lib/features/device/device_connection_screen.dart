import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/navigation.dart';
import '../../app/theme.dart';
import '../../app/widgets/luluna_ui.dart';
import '../../data/hardware/esp32_provision_client.dart';
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
  late final TextEditingController _homeSsidController;
  late final TextEditingController _homePassController;
  var _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final url = ref.read(deviceRepositoryProvider).esp32BaseUrl ?? '';
    _urlController = TextEditingController(text: url);
    _bleController = TextEditingController(text: 'Luluna-Bone');
    _homeSsidController = TextEditingController();
    _homePassController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _bleController.dispose();
    _homeSsidController.dispose();
    _homePassController.dispose();
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

  Future<void> _provisionWifi() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final client = Esp32ProvisionClient();
    final result = await client.provision(
      ssid: _homeSsidController.text,
      password: _homePassController.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = result.message;
      if (result.ok) {
        _urlController.text = Esp32ProvisionClient.mdnsHint;
      }
    });
    if (result.ok) {
      await ref
          .read(deviceRepositoryProvider)
          .saveEsp32BaseUrl(Esp32ProvisionClient.mdnsHint);
    }
  }

  Future<void> _useSoftApUrl() async {
    _urlController.text = Esp32ProvisionClient.defaultSoftApUrl;
    await _saveUrl();
  }

  Future<void> _useMdnsUrl() async {
    _urlController.text = Esp32ProvisionClient.mdnsHint;
    await _saveUrl();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(deviceStatusProvider).value;
    final monitor = ref.watch(hardwareMonitorProvider);
    final ble = ref.watch(bleAudioOutputProvider);
    final connected = status?.isConnected == true;

    return Scaffold(
      appBar: lulunaAppBar(context, title: 'Cihaz Bağlantısı'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            kDebugMode
                ? 'Gözlük (ESP32-CAM) Wi-Fi üzerinden kare ve (varsa) mik '
                      'örneği gönderir. Donanım yoksa Mock İzleme ile '
                      'pipeline test edilir.'
                : 'Gözlük (ESP32-CAM) Wi-Fi üzerinden kare ve ortam sesi '
                      'gönderir; ses çıkışı kemik iletimli kulaklığa yönlenir.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: LulunaColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
          const _PermissionsCard(),
          const SizedBox(height: 16),
          LulunaCard(
            color: LulunaColors.surfaceContainerHighest,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: LulunaColors.surfaceContainer,
                  child: Icon(
                    connected ? Icons.visibility : Icons.visibility_off,
                    color: connected
                        ? LulunaColors.secondary
                        : LulunaColors.outline,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status?.connection.label ?? 'Bağlı değil',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        status == null
                            ? 'Durum bekleniyor…'
                            : '${status.batteryLabel} · '
                                  'Mik: ${status.micAvailable ? 'hazır' : 'yok'} · '
                                  'Wi-Fi: ${status.wifiMode}'
                                  '${status.ip != null ? ' (${status.ip})' : ''} · '
                                  'İzleme: ${_modeLabel(monitor.mode)}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: connected
                        ? LulunaColors.secondary
                        : LulunaColors.outline.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LulunaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wi-Fi Kurulumu (SoftAP)',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: LulunaColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: LulunaColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          LulunaColors.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '1) Telefonda «${Esp32ProvisionClient.softApSsid}» ağına bağlanın '
                    '(şifre: ${Esp32ProvisionClient.softApPassword}). '
                    '2) Ev Wi-Fi bilgisini gönderin. '
                    '3) Ev Wi-Fi’ye dönüp ${Esp32ProvisionClient.mdnsHint} deneyin.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: LulunaColors.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _homeSsidController,
                  decoration: const InputDecoration(
                    labelText: 'Ev Wi-Fi adı (SSID)',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _homePassController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Ev Wi-Fi şifresi',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : _provisionWifi,
                        child: const Text('Cihaza Gönder'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : _useSoftApUrl,
                        child: const Text('192.168.4.1'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _busy ? null : _useMdnsUrl,
                    child: const Text('luluna.local'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'ESP32 adresi',
              hintText: 'http://luluna.local',
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
          const SizedBox(height: 10),
          LulunaPrimaryButton(
            label: 'ESP32 adresini kaydet / yokla',
            onPressed: _busy ? null : _saveUrl,
          ),
          const SizedBox(height: 28),
          Text(
            'İzleme',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: LulunaColors.primary,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (kDebugMode) ...[
                Expanded(
                  child: _MonitorTile(
                    icon: Icons.science,
                    label: 'Mock',
                    filled: false,
                    onTap: _busy || monitor.isRunning ? null : _startMock,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _MonitorTile(
                  icon: Icons.videocam,
                  label: 'Canlı',
                  filled: true,
                  onTap: _busy || monitor.isRunning ? null : _startLive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy || !monitor.isRunning ? null : _stop,
            icon: const Icon(Icons.stop),
            label: const Text('İzlemeyi durdur'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(
              _message!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LulunaColors.onSurfaceVariant,
                  ),
            ),
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

class _MonitorTile extends StatelessWidget {
  const _MonitorTile({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? LulunaColors.primaryContainer
        : LulunaColors.secondaryContainer;
    final fg = filled ? Colors.white : LulunaColors.onSecondaryContainer;

    return Material(
      color: onTap == null ? bg.withValues(alpha: 0.45) : bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(icon, size: 32, color: fg),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LulunaColors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sistem izinleri',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: LulunaColors.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Luluna’nın çalışması için Bluetooth ve bildirim '
            'izinlerine ihtiyacımız var. Mikrofon, kriz ses kaydı içindir.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LulunaColors.onSecondaryContainer
                      .withValues(alpha: 0.9),
                ),
          ),
          if (_summary != null) ...[
            const SizedBox(height: 8),
            Text(
              _summary!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: LulunaColors.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: LulunaColors.onSecondaryContainer,
              side: const BorderSide(color: LulunaColors.onSecondaryContainer),
            ),
            onPressed: _busy ? null : _request,
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('İzinleri iste'),
          ),
        ],
      ),
    );
  }
}
