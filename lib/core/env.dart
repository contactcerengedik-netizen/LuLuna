/// Derleme / runtime yapılandırması.
///
/// Anahtarlar:
/// - `flutter run --dart-define-from-file=config/gemini.json`
/// - Şablon: `.env.example` (dosyayı commit etme; değerleri dart-define ile geçir)
///
/// API anahtarları source code'a yazılmaz. Supabase yoksa Demo Mode çalışır.
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

  /// Görsel modeli (Nano Banana 2). Eski `gemini-2.5-flash-image` 404 verebilir.
  /// Docs: https://ai.google.dev/gemini-api/docs/models/gemini-3.1-flash-image
  static const geminiImageModel = String.fromEnvironment(
    'GEMINI_IMAGE_MODEL',
    defaultValue: 'gemini-3.1-flash-image',
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

  /// Google Cloud Console → OAuth 2.0 → **Web** istemci kimliği.
  /// Supabase Google provider + native `signInWithIdToken` için zorunlu.
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  /// Google Cloud Console → OAuth 2.0 → **iOS** istemci kimliği (opsiyonel).
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  /// Opsiyonel görsel üretim API anahtarı (PHASE 6+).
  static const imageApiKey = String.fromEnvironment('IMAGE_API_KEY');

  /// Opsiyonel OpenAI anahtarı (içerik LLM; mock yoksa).
  static const openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');

  /// Debug’da kotayı koru: mock görsel. Gerçek API için:
  /// `--dart-define=FORCE_REAL_AI_IMAGES=true`
  static const forceRealAiImages = bool.fromEnvironment(
    'FORCE_REAL_AI_IMAGES',
  );

  /// Açıkça mock görsel zorla (kota / UI testi).
  static const useMockImages = bool.fromEnvironment('USE_MOCK_IMAGES');

  /// Debug’da varsayılan mock görsel (kotayı korur). Gerçek görsel için:
  /// `--dart-define=FORCE_REAL_AI_IMAGES=true`
  static bool get shouldUseMockImages {
    if (forceRealAiImages) return false;
    if (useMockImages) return true;
    // kDebugMode import için foundation gerekir — burada dart-define yoksa
    // çağıran taraf kDebugMode ile birleştirir.
    return false;
  }

  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;

  static bool get hasImageApiKey => imageApiKey.isNotEmpty;

  static bool get hasOpenAiKey => openAiApiKey.isNotEmpty;

  static bool get hasSyncEndpoint => syncEndpoint.isNotEmpty;

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get hasGoogleSignIn => googleWebClientId.isNotEmpty;
}
