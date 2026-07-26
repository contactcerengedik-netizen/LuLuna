import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/env.dart';
import 'data/providers.dart';
import 'data/repositories/auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase: URL + anon key --dart-define / config/gemini.json ile gelir.
  // Anahtar yoksa yerel demo modu devam eder (testler bozulmaz).
  if (Env.hasSupabase) {
    // Not: eski `anon` JWT anahtarı da publishableKey olarak geçerlidir.
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    );
    debugPrint('Supabase initialized: ${Env.supabaseUrl}');
  } else {
    debugPrint(
      'Supabase atlandı — config/gemini.json içine SUPABASE_URL ve '
      'SUPABASE_ANON_KEY ekleyip --dart-define-from-file ile çalıştırın.',
    );
  }

  final prefs = await SharedPreferences.getInstance();

  // Test hesapları yalnızca debug + yerel demo modunda hazırlanır.
  if (kDebugMode && !Env.hasSupabase) {
    await LocalAuthRepository(prefs).ensureDemoAccounts();
  }

  // Her soğuk açılışta giriş ekranı gösterilsin: kayıtlı oturumu temizle.
  // Rol/profil kalır; kullanıcı tekrar giriş yaptıktan sonra kaldığı yerden devam eder.
  await _clearSessionOnLaunch(prefs);

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const LulunaApp(),
    ),
  );
}

Future<void> _clearSessionOnLaunch(SharedPreferences prefs) async {
  if (Env.hasSupabase) {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint('Supabase signOut atlandı: $e');
    }
  }
  await prefs.remove('auth_session');
}
