# Luluna ESP32-CAM Firmware

Gözlük modülü yalnızca **duyu organı**dır: JPEG kare + (opsiyonel) I2S
mikrofon PCM verisini telefona akıtır. Yapay zeka kararları Flutter
uygulamasında verilir.

## SoftAP kurulum (önerilen)

1. Firmware’i yükleyin (SSID hardcode gerekmez).
2. Kayıtlı Wi-Fi yoksa cihaz **`Luluna-Setup`** AP açar (şifre: `luluna1234`).
3. Telefonu bu ağa bağlayın.
4. Uygulama → **Cihaz bağlantısı** → ev Wi-Fi SSID/şifre gönderin  
   veya tarayıcıda `http://192.168.4.1`
5. Cihaz yeniden başlar, ev ağına geçer.
6. Telefonda ev Wi-Fi’ye dönün → `http://luluna.local` (mDNS) veya STA IP.

Wi-Fi’yi sıfırlamak için (cihaz erişilebilirken): `POST /wifi/reset`

## Lab kısayolu

`WIFI_SSID` / `WIFI_PASS` doldurulursa NVS boşken doğrudan STA denenir.

## Uç noktalar

| Yol | Açıklama |
|-----|----------|
| `GET /` | SoftAP HTML kurulum formu |
| `POST /wifi` | `ssid=` & `pass=` form → NVS + restart |
| `POST /wifi/reset` | NVS temizle + SoftAP |
| `GET /capture` | Tek JPEG kare (~1 fps örnekleme) |
| `GET /stream` | MJPEG |
| `GET /status` | `battery`, `wifi_mode` (`ap`/`sta`), `ip`, `hostname`, `mic_available`, … |
| `GET /mic` | 16-bit mono PCM; yoksa **204** |

## Mimari notu

Thin Client & Brain: firmware’de model yok. BLE ses protokolü henüz
sabitlenmedi; telefon TTS fallback kullanılır.
