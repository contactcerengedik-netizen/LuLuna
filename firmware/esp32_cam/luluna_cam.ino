/*
 * Luluna ESP32-CAM Firmware (Arduino)
 * -----------------------------------
 * Gözlük modülü "duyu organı": kamerayı ve mikrofonu telefona ham veri olarak
 * akıtır. Ağır AI burada ÇALIŞMAZ (Thin Client & Brain mimarisi).
 *
 * Kurulum:
 *  1. Arduino IDE → Board: "AI Thinker ESP32-CAM"
 *  2. Tools → PSRAM: Enabled
 *  3. WIFI_SSID / WIFI_PASS doldurun, yükleyin
 *  4. Seri monitörde IP'yi okuyun (115200 baud)
 *  5. Telefonda Ayarlar → Cihaz bağlantısı → http://IP
 *
 * Uç noktalar:
 *  GET /capture  → tek JPEG kare (uygulama 1 fps örnekler)
 *  GET /stream   → MJPEG sürekli akış
 *  GET /status   → batarya / uptime / mic durumu JSON
 *  GET /mic      → 16-bit mono PCM chunk (I2S bağlıysa; yoksa 204)
 */

#include "esp_camera.h"
#include <WiFi.h>
#include "esp_http_server.h"
#include <driver/i2s.h>

// --------- Yapılandırma ---------
const char *WIFI_SSID = "YOUR_WIFI_SSID";
const char *WIFI_PASS = "YOUR_WIFI_PASSWORD";

// INMP441 / I2S MEMS mikrofon. Donanım yoksa 0 yapın → /mic 204 döner.
#ifndef ENABLE_I2S_MIC
#define ENABLE_I2S_MIC 1
#endif

// AI Thinker'da sık kullanılan serbest pinler (kamera ile çakışmaz).
#define I2S_WS_PIN   15  // LRCL / WS
#define I2S_SD_PIN   13  // DOUT / SD
#define I2S_SCK_PIN  14  // BCLK / SCK
#define I2S_SAMPLE_RATE 16000
#define I2S_MIC_SAMPLES 4000  // ~250 ms @ 16 kHz

// Batarya gerilim bölücü ADC pini. Yoksa -1 → uptime tabanlı tahmin.
#ifndef BATTERY_ADC_PIN
#define BATTERY_ADC_PIN 33
#endif

// AI Thinker ESP32-CAM pin haritası
#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27
#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

httpd_handle_t server = NULL;
static bool g_mic_ready = false;

#if ENABLE_I2S_MIC
static bool init_i2s_mic() {
  i2s_config_t cfg = {
      .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_RX),
      .sample_rate = I2S_SAMPLE_RATE,
      .bits_per_sample = I2S_BITS_PER_SAMPLE_32BIT,
      .channel_format = I2S_CHANNEL_FMT_ONLY_LEFT,
      .communication_format = I2S_COMM_FORMAT_STAND_I2S,
      .intr_alloc_flags = ESP_INTR_FLAG_LEVEL1,
      .dma_buf_count = 4,
      .dma_buf_len = 256,
      .use_apll = false,
      .tx_desc_auto_clear = false,
      .fixed_mclk = 0,
  };
  i2s_pin_config_t pins = {
      .bck_io_num = I2S_SCK_PIN,
      .ws_io_num = I2S_WS_PIN,
      .data_out_num = I2S_PIN_NO_CHANGE,
      .data_in_num = I2S_SD_PIN,
  };
  if (i2s_driver_install(I2S_NUM_0, &cfg, 0, NULL) != ESP_OK) return false;
  if (i2s_set_pin(I2S_NUM_0, &pins) != ESP_OK) return false;
  i2s_zero_dma_buffer(I2S_NUM_0);
  return true;
}
#endif

static int read_battery_percent(const char **source_out) {
#if BATTERY_ADC_PIN >= 0
  // Tipik 2S olmayan tek hücre + gerilim bölücü varsayımı:
  // ADC okuması 0..4095 → yaklaşık 0..3.3V pin; bölücüyle 3.0–4.2V hücre.
  int raw = analogRead(BATTERY_ADC_PIN);
  float v_pin = (raw / 4095.0f) * 3.3f;
  // 1:2 bölücü varsayımı (Vbat = 2 * Vpin)
  float v_bat = v_pin * 2.0f;
  int pct = (int)((v_bat - 3.2f) / (4.2f - 3.2f) * 100.0f);
  if (pct < 0) pct = 0;
  if (pct > 100) pct = 100;
  if (source_out) *source_out = "adc";
  // Okuma çok düşükse (pin boş) tahmine düş.
  if (raw < 50) {
    if (source_out) *source_out = "estimated";
    unsigned long minutes = millis() / 60000UL;
    pct = 92 - (int)(minutes % 40);
    if (pct < 15) pct = 15;
  }
  return pct;
#else
  if (source_out) *source_out = "estimated";
  unsigned long minutes = millis() / 60000UL;
  int pct = 92 - (int)(minutes % 40);
  if (pct < 15) pct = 15;
  return pct;
#endif
}

static esp_err_t capture_handler(httpd_req_t *req) {
  camera_fb_t *fb = esp_camera_fb_get();
  if (!fb) {
    httpd_resp_send_500(req);
    return ESP_FAIL;
  }
  httpd_resp_set_type(req, "image/jpeg");
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  esp_err_t res = httpd_resp_send(req, (const char *)fb->buf, fb->len);
  esp_camera_fb_return(fb);
  return res;
}

static esp_err_t status_handler(httpd_req_t *req) {
  const char *battery_source = "estimated";
  int battery = read_battery_percent(&battery_source);
  char json[220];
  snprintf(
      json, sizeof(json),
      "{\"battery\":%d,\"battery_source\":\"%s\",\"uptime_ms\":%lu,"
      "\"free_heap\":%u,\"mic_available\":%s,\"role\":\"sense_organ\","
      "\"sample_rate\":%d}",
      battery, battery_source, (unsigned long)millis(),
      (unsigned)ESP.getFreeHeap(), g_mic_ready ? "true" : "false",
      I2S_SAMPLE_RATE);
  httpd_resp_set_type(req, "application/json");
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  return httpd_resp_send(req, json, HTTPD_RESP_USE_STRLEN);
}

static esp_err_t mic_handler(httpd_req_t *req) {
  if (!g_mic_ready) {
    httpd_resp_set_status(req, "204 No Content");
    httpd_resp_set_hdr(req, "X-Mic-Available", "0");
    httpd_resp_send(req, NULL, 0);
    return ESP_OK;
  }

#if ENABLE_I2S_MIC
  // 32-bit I2S örneklerinden 16-bit PCM üret.
  const size_t samples = I2S_MIC_SAMPLES;
  int32_t *raw = (int32_t *)malloc(samples * sizeof(int32_t));
  int16_t *pcm = (int16_t *)malloc(samples * sizeof(int16_t));
  if (!raw || !pcm) {
    free(raw);
    free(pcm);
    httpd_resp_send_500(req);
    return ESP_FAIL;
  }

  size_t bytes_read = 0;
  esp_err_t err = i2s_read(I2S_NUM_0, raw, samples * sizeof(int32_t),
                           &bytes_read, pdMS_TO_TICKS(500));
  size_t got = bytes_read / sizeof(int32_t);
  for (size_t i = 0; i < got; i++) {
    // INMP441 genelde üst 24 bitte anlamlı veri taşır.
    pcm[i] = (int16_t)(raw[i] >> 14);
  }
  free(raw);

  if (err != ESP_OK || got == 0) {
    free(pcm);
    httpd_resp_set_status(req, "204 No Content");
    httpd_resp_set_hdr(req, "X-Mic-Available", "0");
    httpd_resp_send(req, NULL, 0);
    return ESP_OK;
  }

  httpd_resp_set_type(req, "application/octet-stream");
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  httpd_resp_set_hdr(req, "X-Mic-Available", "1");
  httpd_resp_set_hdr(req, "X-Sample-Rate", "16000");
  httpd_resp_set_hdr(req, "X-Channels", "1");
  httpd_resp_set_hdr(req, "X-Bits", "16");
  esp_err_t res =
      httpd_resp_send(req, (const char *)pcm, got * sizeof(int16_t));
  free(pcm);
  return res;
#else
  httpd_resp_set_status(req, "204 No Content");
  httpd_resp_set_hdr(req, "X-Mic-Available", "0");
  httpd_resp_send(req, NULL, 0);
  return ESP_OK;
#endif
}

#define PART_BOUNDARY "lulunaboundary"
static const char *_STREAM_CONTENT_TYPE =
    "multipart/x-mixed-replace;boundary=" PART_BOUNDARY;
static const char *_STREAM_BOUNDARY = "\r\n--" PART_BOUNDARY "\r\n";
static const char *_STREAM_PART =
    "Content-Type: image/jpeg\r\nContent-Length: %u\r\n\r\n";

static esp_err_t stream_handler(httpd_req_t *req) {
  httpd_resp_set_type(req, _STREAM_CONTENT_TYPE);
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");

  while (true) {
    camera_fb_t *fb = esp_camera_fb_get();
    if (!fb) break;

    char part[64];
    size_t hlen = snprintf(part, sizeof(part), _STREAM_PART, fb->len);
    if (httpd_resp_send_chunk(req, _STREAM_BOUNDARY, strlen(_STREAM_BOUNDARY)) !=
            ESP_OK ||
        httpd_resp_send_chunk(req, part, hlen) != ESP_OK ||
        httpd_resp_send_chunk(req, (const char *)fb->buf, fb->len) != ESP_OK) {
      esp_camera_fb_return(fb);
      break;
    }
    esp_camera_fb_return(fb);
    // ~2 fps stream; uygulama ayrıca /capture ile 1 fps örnekler.
    delay(500);
  }
  return ESP_OK;
}

static void start_server() {
  httpd_config_t config = HTTPD_DEFAULT_CONFIG();
  config.server_port = 80;
  config.max_uri_handlers = 8;

  httpd_uri_t capture_uri = {.uri = "/capture",
                             .method = HTTP_GET,
                             .handler = capture_handler,
                             .user_ctx = NULL};
  httpd_uri_t stream_uri = {.uri = "/stream",
                            .method = HTTP_GET,
                            .handler = stream_handler,
                            .user_ctx = NULL};
  httpd_uri_t status_uri = {.uri = "/status",
                            .method = HTTP_GET,
                            .handler = status_handler,
                            .user_ctx = NULL};
  httpd_uri_t mic_uri = {
      .uri = "/mic", .method = HTTP_GET, .handler = mic_handler, .user_ctx = NULL};

  if (httpd_start(&server, &config) == ESP_OK) {
    httpd_register_uri_handler(server, &capture_uri);
    httpd_register_uri_handler(server, &stream_uri);
    httpd_register_uri_handler(server, &status_uri);
    httpd_register_uri_handler(server, &mic_uri);
  }
}

void setup() {
  Serial.begin(115200);
  Serial.setDebugOutput(true);

#if BATTERY_ADC_PIN >= 0
  analogReadResolution(12);
  pinMode(BATTERY_ADC_PIN, INPUT);
#endif

  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  config.pin_d1 = Y3_GPIO_NUM;
  config.pin_d2 = Y4_GPIO_NUM;
  config.pin_d3 = Y5_GPIO_NUM;
  config.pin_d4 = Y6_GPIO_NUM;
  config.pin_d5 = Y7_GPIO_NUM;
  config.pin_d6 = Y8_GPIO_NUM;
  config.pin_d7 = Y9_GPIO_NUM;
  config.pin_xclk = XCLK_GPIO_NUM;
  config.pin_pclk = PCLK_GPIO_NUM;
  config.pin_vsync = VSYNC_GPIO_NUM;
  config.pin_href = HREF_GPIO_NUM;
  config.pin_sccb_sda = SIOD_GPIO_NUM;
  config.pin_sccb_scl = SIOC_GPIO_NUM;
  config.pin_pwdn = PWDN_GPIO_NUM;
  config.pin_reset = RESET_GPIO_NUM;
  config.xclk_freq_hz = 20000000;
  config.pixel_format = PIXFORMAT_JPEG;
  config.frame_size = FRAMESIZE_QVGA;
  config.jpeg_quality = 12;
  config.fb_count = 2;
  config.fb_location = CAMERA_FB_IN_PSRAM;
  config.grab_mode = CAMERA_GRAB_LATEST;

  if (esp_camera_init(&config) != ESP_OK) {
    Serial.println("Kamera init başarısız");
    return;
  }

#if ENABLE_I2S_MIC
  g_mic_ready = init_i2s_mic();
  Serial.printf("I2S mikrofon: %s\n", g_mic_ready ? "hazır" : "yok/hata");
#else
  g_mic_ready = false;
  Serial.println("I2S mikrofon derleme dışı (ENABLE_I2S_MIC=0)");
#endif

  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("Wi-Fi bağlanıyor");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();
  Serial.print("Luluna duyu organı hazır: http://");
  Serial.println(WiFi.localIP());

  start_server();
}

void loop() {
  delay(10000);
}
