import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../data/providers.dart';

/// Kriz modu için 3–10 sn veli ses kaydı. Dosya cihazda tutulur.
class ParentVoiceRecorderCard extends ConsumerStatefulWidget {
  const ParentVoiceRecorderCard({super.key});

  @override
  ConsumerState<ParentVoiceRecorderCard> createState() =>
      _ParentVoiceRecorderCardState();
}

class _ParentVoiceRecorderCardState
    extends ConsumerState<ParentVoiceRecorderCard> {
  AudioRecorder? _recorder;
  var _recording = false;
  var _seconds = 0;
  Timer? _ticker;
  String? _error;

  AudioRecorder get _audio {
    return _recorder ??= AudioRecorder();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_recording) {
      await _stop();
      return;
    }
    setState(() => _error = null);
    try {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        setState(() => _error = 'Mikrofon izni gerekli.');
        return;
      }
      if (!await _audio.hasPermission()) {
        setState(() => _error = 'Bu cihazda kayıt izni alınamadı.');
        return;
      }
      final path =
          await ref.read(parentVoiceRepositoryProvider).recordingTargetPath();
      await _audio.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      setState(() {
        _recording = true;
        _seconds = 0;
      });
      _ticker = Timer.periodic(const Duration(seconds: 1), (t) async {
        setState(() => _seconds++);
        if (_seconds >= 10) {
          await _stop();
        }
      });
    } catch (e) {
      _ticker?.cancel();
      _ticker = null;
      if (mounted) {
        setState(() {
          _recording = false;
          _error = 'Kayıt başlatılamadı: $e';
        });
      }
    }
  }

  Future<void> _stop() async {
    _ticker?.cancel();
    _ticker = null;
    String? path;
    try {
      path = await _audio.stop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _recording = false;
          _error = 'Kayıt durdurulamadı: $e';
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() => _recording = false);
    if (path == null || path.isEmpty) {
      setState(() => _error = 'Kayıt alınamadı.');
      return;
    }
    if (_seconds < 2) {
      setState(() => _error = 'En az 2–3 saniye konuşun.');
      return;
    }
    await ref.read(parentVoicePathProvider.notifier).save(path);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kriz sesi kaydedildi (cihazda)')),
      );
    }
  }

  Future<void> _clear() async {
    await ref.read(parentVoicePathProvider.notifier).clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final path = ref.watch(parentVoicePathProvider);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kriz ses kaydı',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '“Geçecek annecim, ben buradayım” gibi 3–10 sn’lik bir '
              'telkin kaydedin. Kriz modunda bu ses çalınır; dosya '
              'yalnızca bu cihazda saklanır.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _toggle,
                  icon: Icon(_recording ? Icons.stop : Icons.mic),
                  label: Text(
                    _recording ? 'Durdur ($_seconds sn)' : 'Kaydet',
                  ),
                ),
                if (path != null && !_recording)
                  TextButton(
                    onPressed: _clear,
                    child: const Text('Sil'),
                  ),
              ],
            ),
            if (path != null && !_recording) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, color: scheme.primary, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Kayıt hazır',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}
