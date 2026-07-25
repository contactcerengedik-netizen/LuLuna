import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kriz modu için veli ses kaydının yerel yolu.
class ParentVoiceRepository {
  ParentVoiceRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _pathKey = 'parent_voice_path';

  String? loadPath() {
    final path = _prefs.getString(_pathKey);
    if (path == null) return null;
    try {
      if (!File(path).existsSync()) return null;
    } catch (_) {
      // Web gibi dosya sistemi olmayan platformlarda yolu olduğu gibi döndür.
      return path;
    }
    return path;
  }

  bool get hasRecording => loadPath() != null;

  Future<String> recordingTargetPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'parent_crisis_voice.m4a');
  }

  Future<void> savePath(String path) => _prefs.setString(_pathKey, path);

  Future<void> clear() async {
    final path = _prefs.getString(_pathKey);
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    await _prefs.remove(_pathKey);
  }
}
