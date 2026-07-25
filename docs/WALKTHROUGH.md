# Luluna – Geliştirme Yol Haritası (Walkthrough)

Bu doküman, Master Rapor'daki mimariyi (Thin Client & Brain) çalışan bir MVP'ye
dönüştürmek için adım adım izleyeceğimiz planı tanımlar. Her adım bir öncekinin
üzerine inşa edilir ve donanım olmadan da test edilebilir şekilde kurgulanmıştır.

## Mimari Özet

- **Duyu Organı (ESP32 / Gözlük):** Kamera + mikrofon verisini işlemeden telefona akıtır.
- **Beyin (Flutter Uygulaması):** Karar mekanizması, Gemini API, TTS, BLE ses çıkışı, loglama.
- **Bulut:** Gemini Flash (karar — güncel model: gemini-3.5-flash), Supabase/Firebase (log senkronizasyonu).

## Adımlar

### Adım 1 — Mobil Uygulama İskeleti ✅

- [x] Klasör yapısı: `app/` (tema, router), `data/` (model + repository), `features/` (ekranlar)
- [x] State yönetimi: Riverpod, navigasyon: go_router
- [x] Onboarding: rol seçimi (Veli/Terapist) → çocuk profili (tetikleyiciler, ses tonu)
- [x] Ana kabuk: Dashboard, Canlı Asistan, Raporlar, Ayarlar sekmeleri
- [x] Kriz/Acil durum modu ekranı (placeholder)
- [x] Mock repository'ler: AI asistan akışı ve cihaz durumu (donanımsız demo için)

### Adım 2 — Profil ve Prompt Enjeksiyonu ✅

- [x] Çocuk profilinin kalıcı saklanması (SharedPreferences; ileride SQLite)
- [x] Profil verilerinden dinamik System Prompt üretimi (`PromptBuilder`)
- [x] Terapist tarafından güncellenebilir prompt kuralları (yerel taslak)
- [x] System prompt önizleme ekranı + Raporlar/Ayarlar girişi
- [x] `systemPromptProvider` — Adım 3 Gemini çağrısı bunu tüketir

### Adım 3 — AI Pipeline (Gemini + TTS) ✅

> Not: Rapor `google_generative_ai` paketi + `gemini-1.5-flash` öngörüyordu.
> Paket Google tarafından kullanımdan kaldırıldı (Kasım 2025) ve model
> emekliye ayrıldı (Eylül 2025). Bu yüzden Gemini Developer API'sine
> Dio ile doğrudan REST çağrısı yapılıyor; varsayılan model `gemini-3.5-flash`
> (`--dart-define=GEMINI_MODEL=...` ile değiştirilebilir).

- [x] `GeminiAssistantRepository` — `AssistantRepository` arayüzünün gerçek
      implementasyonu (Repository Pattern sayesinde ekranlar değişmedi)
- [x] Gözlem (+ opsiyonel JPEG kare) → system prompt + Gemini → kısa yönlendirme
- [x] `flutter_tts` ile sesli çıktı; ses tonu → hız/perde haritalaması
- [x] API anahtarı yönetimi: `--dart-define=GEMINI_API_KEY=...`
      (anahtar yoksa otomatik demo/mock moduna düşer)
- [x] Canlı Asistan ekranında gözlem simülasyon girişi (donanımsız uçtan uca test)

Çalıştırma (önerilen — anahtar git'e sızmaz):

```
# config/gemini.example.json → config/gemini.json kopyalayıp anahtarınızı yazın
flutter run --dart-define-from-file=config/gemini.json
# veya kısayol:
./run.ps1
```

Alternatif (tek seferlik):

```
flutter run --dart-define=GEMINI_API_KEY=API_ANAHTARINIZ
```

> `config/gemini.json` `.gitignore`'dadır; anahtar asla commit edilmez.

### Adım 4 — Dashboard ve Kriz Modunun Gerçeklenmesi ✅

- [x] Canlı asistan akışının AI / mock loglarıyla beslenmesi (Adım 3)
- [x] Kriz modu: AI susturulur (`isMuted`) → veli sesi / sakinleştirici müzik
      (`assets/audio/*.wav` + audioplayers)
- [x] Başarı pekiştireçleri → veli paneline rozet düşmesi (`BadgesNotifier`)
- [x] Panelde rozet şeridi + kriz durumu metni

### Adım 5 — Offline Fallback ve Senkronizasyon ✅

- [x] SQLite ile yerel log kuyruğu (`LogQueueRepository`)
- [x] `SyncService` + Dio `LogSyncInterceptor`: internet gelince uzak istemciye
      flush (`SYNC_ENDPOINT` veya InMemory demo client)
- [x] Çevrimdışı yedek ses (`offline_comfort.wav` + `OfflineFallbackService`)
- [x] Panelde çevrimiçi/çevrimdışı + bekleyen sync sayısı rozeti

### Adım 6 — Donanım Entegrasyonu (ESP32 + BLE) ✅ (bu adımdayız)

- [x] ESP32-CAM firmware iskeleti (`firmware/esp32_cam/`) — `/capture`, `/stream`, `/status`
- [x] `HttpCaptureStreamClient` + `FrameSampler` (~1 fps → Gemini)
- [x] `MockCameraStreamClient` ile donanımsız pipeline demosu
- [x] `BleAudioOutput` arayüzü + yerel TTS fallback (`LocalBleAudioOutput`)
- [x] `HardwareMonitor` orkestrasyonu + Cihaz bağlantısı ekranı
- [x] Android `LulunaMonitorService` foreground service (MethodChannel)

### Adım 7 — Terapist Paneli ve Raporlama ✅ (son adım)

- [x] `ReportStats` + saf `buildReportStats` agregasyonu (loglardan)
- [x] Saatlik stres yoğunluğu grafiği (fl_chart LineChart)
- [x] Haftalık AI müdahale oranı (fl_chart BarChart)
- [x] Tetikleyici dağılımı + özet kartları (gözlem/müdahale/oran)
- [x] Dinamik prompt yönetimi girişi (Adım 2 ile bağlı)

### Adım 8 — Auth / KVKK / Eşleştirme / Rol Kabuğu ✅

- [x] Sayfa 0: Giriş-Kayıt + KVKK açık rıza (`AuthGateScreen`) — router kapısı
- [x] Yerel auth repository (e-posta/şifre + Google demo stub; Supabase/Firebase’e hazır)
- [x] Veli ↔ Terapist eşleştirme (`PairingScreen`, LUNA-XXXX davet kodu)
- [x] Çocuk profilinde kriz ses kaydedici (lokal m4a)
- [x] İzin karşılama ekranı + Cihaz ekranında izin kartı
- [x] HomeShell rol ayrımı: terapist → Raporlar + Ayarlar (Panel/Asistan/Kriz/Cihaz yok)

### Adım 9 — Supabase istemci iskeleti ✅

- [x] `supabase_flutter` paketi
- [x] `Supabase.initialize` in `main.dart` (`SUPABASE_URL` + `SUPABASE_ANON_KEY`)
- [x] `supabaseClientProvider` — log/auth/eşleştirme buluta taşınırken buradan tüketilir
- [x] Anahtarlar `config/gemini.json` (git-ignored) + `--dart-define-from-file`

### Adım 10 — Supabase veri katmanı ✅

- [x] `supabase/schema.sql` — profiles, kvkk_consents, pairing_codes,
      assistant_logs tabloları + RLS politikaları (SQL Editor'e yapıştırılır)
- [x] `SupabaseAuthRepository` — gerçek kayıt/giriş, KVKK upsert
      (e-posta doğrulama açıksa kullanıcıya yönlendirme mesajı)
- [x] `SupabasePairingRepository` — davet kodları bulutta; veli/terapist
      farklı cihazlarda eşleşir; terapist claim → RLS rapor erişimi
- [x] `SupabaseRemoteLogClient` — SQLite kuyruğu → `assistant_logs`
- [x] Rol seçimi `profiles.role` alanına yazılır (best-effort)
- [x] Anahtar yoksa tüm katman otomatik yerel demo moduna düşer

### Adım 11 — Hesaba bağlı rol ve profil ✅

- [x] `ProfileRepository` ve yerel eşleştirme anahtarları `userId` ile
      ayrıştırıldı (`user_role_<uid>`, `child_profile_<uid>` …)
- [x] Rol her hesap için bir kez sorulur: KVKK → izinler → **rol seçimi** →
      (veli: çocuk profili / terapist: hasta kodu)
- [x] Farklı hesapla girildiğinde önceki kullanıcının rolü ve eşleşmesi
      devralınmaz

## Klasör Yapısı (Adım 9 sonrası)

```
firmware/esp32_cam/
  luluna_cam.ino
  README.md
lib/data/hardware/
  esp32_stream_client.dart
  frame_sampler.dart
  ble_audio_output.dart
  hardware_monitor.dart
  background_monitor_service.dart
  minimal_jpeg.dart
lib/features/device/
  device_connection_screen.dart
android/.../LulunaMonitorService.kt
```
