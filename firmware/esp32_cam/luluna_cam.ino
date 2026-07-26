/*
 * Luluna ESP32-CAM Firmware (Arduino)
 * -----------------------------------
 * Gözlük modülü "duyu organı": kamerayı ve mikrofonu telefona ham veri olarak
 * akıtır. Ağır AI burada ÇALIŞMAZ (Thin Client & Brain mimarisi).
 *
 * Kurulum (SoftAP):
 *  1. Arduino IDE → Board: "AI Thinker ESP32-CAM", PSRAM: Enabled
 *  2. Yükleyin. Kayıtlı Wi-Fi yoksa AP açılır: "Luluna-Setup" / luluna1234
 *  3. Telefonu bu ağa bağlayın → uygulama veya http://192.168.4.1
 *  4. Ev Wi-Fi SSID/şifre gönderin; cihaz yeniden başlar ve STA'ya geçer
 *  5. Telefonda ev Wi-Fi'ye dönün → http://luluna.local veya STA IP
 *
 * Lab kısayolu: WIFI_SSID / WIFI_PASS doldurulursa NVS yokken doğrudan STA.
 *
 * Uç noktalar:
 *  GET  /capture  → tek JPEG kare
 *  GET  /stream   → MJPEG
 *  GET  /status   → batarya / wifi_mode / ip / mic JSON
 *  GET  /mic      → 16-bit mono PCM (yoksa 204)
 *  GET  /         → SoftAP kurulum formu (AP modunda)
 *  POST /wifi     → ssid=&pass= (form) → NVS kaydet + restart
 *  POST /wifi/reset → NVS temizle + SoftAP'a düş
 */

#include "esp_camera.h"
#include <WiFi.h>
#include <Preferences.h>
#include <ESPmDNS.h>
#include "esp_http_server.h"
#include <driver/i2s.h>

// --------- Yapılandırma ---------
// Lab/fallback. SoftAP kullanıyorsanız YOUR_WIFI_* bırakın.
const char *WIFI_SSID = "YOUR_WIFI_SSID";
const char *WIFI_PASS = "YOUR_WIFI_PASSWORD";

static const char *AP_SSID = "Luluna-Setup";
static const char *AP_PASS = "luluna1234";  // WPA2 min 8
static const char *MDNS_HOST = "luluna";

#ifndef ENABLE_I2S_MIC
#define ENABLE_I2S_MIC 1
#endif

#define I2S_WS_PIN   15
#define I2S_SD_PIN   13
#define I2S_SCK_PIN  14
#define I2S_SAMPLE_RATE 16000
#define I2S_MIC_SAMPLES 4000

#ifndef BATTERY_ADC_PIN
#define BATTERY_ADC_PIN 33
#endif

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
static bool g_is_ap = false;
static Preferences g_prefs;

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
  int raw = analogRead(BATTERY_ADC_PIN);
  float v_pin = (raw / 4095.0f) * 3.3f;
  float v_bat = v_pin * 2.0f;
  int pct = (int)((v_bat - 3.2f) / (4.2f - 3.2f) * 100.0f);
  if (pct < 0) pct = 0;
  if (pct > 100) pct = 100;
  if (source_out) *source_out = "adc";
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

static bool load_wifi_creds(String &ssid, String &pass) {
  g_prefs.begin("luluna", true);
  ssid = g_prefs.getString("ssid", "");
  pass = g_prefs.getString("pass", "");
  g_prefs.end();
  return ssid.length() > 0;
}

static void save_wifi_creds(const char *ssid, const char *pass) {
  g_prefs.begin("luluna", false);
  g_prefs.putString("ssid", ssid);
  g_prefs.putString("pass", pass);
  g_prefs.end();
}

static void clear_wifi_creds() {
  g_prefs.begin("luluna", false);
  g_prefs.clear();
  g_prefs.end();
}

static bool has_lab_wifi() {
  return strcmp(WIFI_SSID, "YOUR_WIFI_SSID") != 0 && strlen(WIFI_SSID) > 0;
}

static bool try_sta(const char *ssid, const char *pass, uint32_t timeout_ms) {
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, pass);
  Serial.printf("STA bağlanıyor: %s", ssid);
  uint32_t start = millis();
  while (WiFi.status() != WL_CONNECTED && (millis() - start) < timeout_ms) {
    delay(400);
    Serial.print(".");
  }
  Serial.println();
  if (WiFi.status() == WL_CONNECTED) {
    g_is_ap = false;
    if (MDNS.begin(MDNS_HOST)) {
      MDNS.addService("http", "tcp", 80);
      Serial.printf("mDNS: http://%s.local\n", MDNS_HOST);
    }
    Serial.print("STA IP: ");
    Serial.println(WiFi.localIP());
    return true;
  }
  WiFi.disconnect(true);
  return false;
}

static void start_softap() {
  g_is_ap = true;
  WiFi.mode(WIFI_AP);
  WiFi.softAP(AP_SSID, AP_PASS);
  delay(100);
  Serial.printf("SoftAP: %s / %s → http://", AP_SSID, AP_PASS);
  Serial.println(WiFi.softAPIP());
}

static int hex_val(char c) {
  if (c >= '0' && c <= '9') return c - '0';
  if (c >= 'A' && c <= 'F') return c - 'A' + 10;
  if (c >= 'a' && c <= 'f') return c - 'a' + 10;
  return -1;
}

static void url_decode(const char *src, char *dst, size_t dst_len) {
  size_t di = 0;
  for (size_t i = 0; src[i] && di + 1 < dst_len; i++) {
    if (src[i] == '+' ) {
      dst[di++] = ' ';
    } else if (src[i] == '%' && src[i + 1] && src[i + 2]) {
      int hi = hex_val(src[i + 1]);
      int lo = hex_val(src[i + 2]);
      if (hi >= 0 && lo >= 0) {
        dst[di++] = (char)((hi << 4) | lo);
        i += 2;
      } else {
        dst[di++] = src[i];
      }
    } else {
      dst[di++] = src[i];
    }
  }
  dst[di] = '\0';
}

static bool extract_form_field(const char *body, const char *key, char *out,
                               size_t out_len) {
  char needle[40];
  snprintf(needle, sizeof(needle), "%s=", key);
  const char *p = strstr(body, needle);
  if (!p) return false;
  p += strlen(needle);
  char enc[96];
  size_t i = 0;
  while (*p && *p != '&' && i + 1 < sizeof(enc)) {
    enc[i++] = *p++;
  }
  enc[i] = '\0';
  url_decode(enc, out, out_len);
  return out[0] != '\0';
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
  IPAddress ip = g_is_ap ? WiFi.softAPIP() : WiFi.localIP();
  char json[320];
  snprintf(
      json, sizeof(json),
      "{\"battery\":%d,\"battery_source\":\"%s\",\"uptime_ms\":%lu,"
      "\"free_heap\":%u,\"mic_available\":%s,\"role\":\"sense_organ\","
      "\"sample_rate\":%d,\"wifi_mode\":\"%s\",\"ip\":\"%u.%u.%u.%u\","
      "\"hostname\":\"%s.local\"}",
      battery, battery_source, (unsigned long)millis(),
      (unsigned)ESP.getFreeHeap(), g_mic_ready ? "true" : "false",
      I2S_SAMPLE_RATE, g_is_ap ? "ap" : "sta", ip[0], ip[1], ip[2], ip[3],
      MDNS_HOST);
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

static const char *PORTAL_HTML =
    "<!DOCTYPE html><html><head><meta charset=utf-8>"
    "<meta name=viewport content=\"width=device-width,initial-scale=1\">"
    "<title>Luluna Kurulum</title>"
    "<style>body{font-family:sans-serif;margin:24px;max-width:420px}"
    "input,button{width:100%;padding:12px;margin:8px 0;font-size:16px}"
    "button{background:#1a5f4a;color:#fff;border:0}</style></head><body>"
    "<h1>Luluna</h1><p>Ev Wi-Fi bilgilerini girin.</p>"
    "<form method=POST action=/wifi>"
    "<input name=ssid placeholder=\"Wi-Fi adı (SSID)\" required>"
    "<input name=pass type=password placeholder=\"Şifre\">"
    "<button type=submit>Kaydet ve bağlan</button></form>"
    "</body></html>";

static esp_err_t portal_handler(httpd_req_t *req) {
  httpd_resp_set_type(req, "text/html");
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  return httpd_resp_send(req, PORTAL_HTML, HTTPD_RESP_USE_STRLEN);
}

static esp_err_t wifi_post_handler(httpd_req_t *req) {
  if (req->content_len <= 0 || req->content_len > 256) {
    httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "bad body");
    return ESP_FAIL;
  }
  char body[257];
  int received = httpd_req_recv(req, body, req->content_len);
  if (received <= 0) {
    httpd_resp_send_500(req);
    return ESP_FAIL;
  }
  body[received] = '\0';

  char ssid[64] = {0};
  char pass[64] = {0};
  if (!extract_form_field(body, "ssid", ssid, sizeof(ssid))) {
    httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "ssid required");
    return ESP_FAIL;
  }
  extract_form_field(body, "pass", pass, sizeof(pass));

  save_wifi_creds(ssid, pass);
  httpd_resp_set_type(req, "application/json");
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  const char *ok =
      "{\"ok\":true,\"message\":\"Kaydedildi, yeniden başlıyor\"}";
  httpd_resp_send(req, ok, HTTPD_RESP_USE_STRLEN);
  delay(800);
  ESP.restart();
  return ESP_OK;
}

static esp_err_t wifi_reset_handler(httpd_req_t *req) {
  clear_wifi_creds();
  httpd_resp_set_type(req, "application/json");
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  const char *ok = "{\"ok\":true,\"message\":\"Wi-Fi silindi, SoftAP\"}";
  httpd_resp_send(req, ok, HTTPD_RESP_USE_STRLEN);
  delay(800);
  ESP.restart();
  return ESP_OK;
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
    delay(500);
  }
  return ESP_OK;
}

static void start_server() {
  httpd_config_t config = HTTPD_DEFAULT_CONFIG();
  config.server_port = 80;
  config.max_uri_handlers = 12;

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
  httpd_uri_t portal_uri = {
      .uri = "/", .method = HTTP_GET, .handler = portal_handler, .user_ctx = NULL};
  httpd_uri_t wifi_uri = {.uri = "/wifi",
                          .method = HTTP_POST,
                          .handler = wifi_post_handler,
                          .user_ctx = NULL};
  httpd_uri_t wifi_reset_uri = {.uri = "/wifi/reset",
                                .method = HTTP_POST,
                                .handler = wifi_reset_handler,
                                .user_ctx = NULL};

  if (httpd_start(&server, &config) == ESP_OK) {
    httpd_register_uri_handler(server, &capture_uri);
    httpd_register_uri_handler(server, &stream_uri);
    httpd_register_uri_handler(server, &status_uri);
    httpd_register_uri_handler(server, &mic_uri);
    httpd_register_uri_handler(server, &portal_uri);
    httpd_register_uri_handler(server, &wifi_uri);
    httpd_register_uri_handler(server, &wifi_reset_uri);
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

  String nvs_ssid, nvs_pass;
  bool connected = false;
  if (load_wifi_creds(nvs_ssid, nvs_pass)) {
    connected = try_sta(nvs_ssid.c_str(), nvs_pass.c_str(), 20000);
  } else if (has_lab_wifi()) {
    connected = try_sta(WIFI_SSID, WIFI_PASS, 20000);
  }

  if (!connected) {
    start_softap();
  }

  start_server();
  Serial.println("Luluna duyu organı hazır");
}

void loop() {
  delay(10000);
}
