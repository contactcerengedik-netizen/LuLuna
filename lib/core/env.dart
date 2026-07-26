/// Derleme zamanı yapılandırması.
///
/// Çalıştırma örneği:
/// flutter run --dart-define-from-file=config/gemini.json
abstract final class Env {
  /// Yalnızca Supabase'siz debug geliştirme için doğrudan Gemini anahtarı.
  /// Release derlemesinde anahtar Edge Function secret'ında tutulmalıdır.
  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Rapor gemini-1.5-flash öngörüyordu; model Eylül 2025'te emekliye
  /// ayrıldığı için varsayılan güncel Flash modeline çekildi.
  static const geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.5-flash',
  );

  /// Opsiyonel log senkron uç noktası (Supabase REST / Firebase Functions).
  /// Boşsa InMemoryRemoteLogClient kullanılır (kuluçka demosu).
  static const syncEndpoint = String.fromEnvironment('SYNC_ENDPOINT');

  /// Supabase Project URL (Settings → API → Project URL).
  /// `/rest/v1` eki yanlışlıkla yapıştırıldıysa temizlenir.
  static const _supabaseUrlRaw = String.fromEnvironment('SUPABASE_URL');

  /// Supabase anon (public) key — istemci tarafı; RLS ile korunur.
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseUrl {
    var url = _supabaseUrlRaw.trim();
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    const rest = '/rest/v1';
    if (url.endsWith(rest)) {
      url = url.substring(0, url.length - rest.length);
    }
    return url;
  }

  /// Gizlilik politikası / aydınlatma metni URL'si (mağaza ve KVKK).
  static const privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://luluna.app/privacy',
  );

  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;

  static bool get hasSyncEndpoint => syncEndpoint.isNotEmpty;

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
