# Luluna ESP32-CAM Firmware

Gözlük modülü yalnızca **duyu organı**dır: JPEG kare + (opsiyonel) mikrofon
verisini telefona akıtır. Yapay zeka kararları Flutter uygulamasında verilir.

## Hızlı başlangıç

1. [Arduino IDE](https://www.arduino.cc/) + ESP32 board paketi
2. Board: **AI Thinker ESP32-CAM**, PSRAM: Enabled
3. `luluna_cam.ino` içinde `WIFI_SSID` / `WIFI_PASS` doldurun
4. Yükleyin → Seri monitörde IP'yi okuyun
5. Uygulama: **Ayarlar → Cihaz bağlantısı** → `http://<IP>`

## Uç noktalar

| Yol | Açıklama |
|-----|----------|
| `GET /capture` | Tek JPEG kare (uygulama ~1 fps örnekler) |
| `GET /stream` | MJPEG sürekli akış |
| `GET /status` | Batarya / uptime JSON |
| `GET /mic` | Ham PCM (mikrofon yoksa 204) |

## Mimari notu

Thin Client & Brain: firmware'de model çalıştırılmaz; ısınma ve batarya
maliyetini düşük tutmak için tüm Gemini çağrıları telefonda yapılır.
