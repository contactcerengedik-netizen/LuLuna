# Luluna ESP32-CAM Firmware

Gözlük modülü yalnızca **duyu organı**dır: JPEG kare + (opsiyonel) I2S
mikrofon PCM verisini telefona akıtır. Yapay zeka kararları Flutter
uygulamasında verilir.

## Hızlı başlangıç

1. [Arduino IDE](https://www.arduino.cc/) + ESP32 board paketi
2. Board: **AI Thinker ESP32-CAM**, PSRAM: Enabled
3. `luluna_cam.ino` içinde `WIFI_SSID` / `WIFI_PASS` doldurun
4. (Opsiyonel) INMP441: WS=15, SD=13, SCK=14 — yoksa `ENABLE_I2S_MIC 0`
5. (Opsiyonel) Batarya gerilim bölücü: ADC pin 33 — yoksa tahmini yüzde
6. Yükleyin → Seri monitörde IP'yi okuyun (115200 baud)
7. Uygulama: **Ayarlar → Cihaz bağlantısı** → `http://<IP>`

## Uç noktalar

| Yol | Açıklama |
|-----|----------|
| `GET /capture` | Tek JPEG kare (uygulama ~1 fps örnekler) |
| `GET /stream` | MJPEG sürekli akış |
| `GET /status` | JSON: `battery`, `battery_source`, `mic_available`, `uptime_ms`, `free_heap`, `sample_rate` |
| `GET /mic` | 16-bit mono PCM (~250 ms @ 16 kHz); mik yoksa **204** + `X-Mic-Available: 0` |

### `/mic` yanıt başlıkları

- `X-Mic-Available`: `1` / `0`
- `X-Sample-Rate`: `16000`
- `X-Channels`: `1`
- `X-Bits`: `16`

## Mimari notu

Thin Client & Brain: firmware'de model çalıştırılmaz; ısınma ve batarya
maliyetini düşük tutmak için tüm Gemini çağrıları telefonda (veya Edge
Function üzerinden) yapılır. BLE ses çıkış protokolü henüz sabitlenmedi;
telefon TTS fallback kullanılır.
