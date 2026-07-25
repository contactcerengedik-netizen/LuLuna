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
 *  GET /status   → {"battery":87,"uptime_ms":...}
 *  GET /mic      → ham PCM chunk (I2S mikrofon bağlıysa; yoksa 204 boş)
 */

#include "esp_camera.h"
#include <WiFi.h>
#include "esp_http_server.h"

// --------- Yapılandırma ---------
const char *WIFI_SSID = "YOUR_WIFI_SSID";
const char *WIFI_PASS = "YOUR_WIFI_PASSWORD";

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
  char json[96];
  // Gerçek batarya ölçümü donanıma bağlı; MVP için sabit/placeholder.
  snprintf(json, sizeof(json),
           "{\"battery\":87,\"uptime_ms\":%lu,\"role\":\"sense_organ\"}",
           (unsigned long)millis());
  httpd_resp_set_type(req, "application/json");
  httpd_resp_set_hdr(req, "Access-Control-Allow-Origin", "*");
  return httpd_resp_send(req, json, HTTPD_RESP_USE_STRLEN);
}

static esp_err_t mic_handler(httpd_req_t *req) {
  // I2S mikrofon entegrasyonu sonraki donanım iterasyonunda.
  // Şimdilik 204: içerik yok — uygulama mikrofonu opsiyonel sayar.
  httpd_resp_set_status(req, "204 No Content");
  httpd_resp_send(req, NULL, 0);
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
    if (httpd_resp_send_chunk(req, _STREAM_BOUNDARY, strlen(_STREAM_BOUNDARY)) != ESP_OK ||
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

  httpd_uri_t capture_uri = {
      .uri = "/capture", .method = HTTP_GET,
      .handler = capture_handler, .user_ctx = NULL};
  httpd_uri_t stream_uri = {
      .uri = "/stream", .method = HTTP_GET,
      .handler = stream_handler, .user_ctx = NULL};
  httpd_uri_t status_uri = {
      .uri = "/status", .method = HTTP_GET,
      .handler = status_handler, .user_ctx = NULL};
  httpd_uri_t mic_uri = {
      .uri = "/mic", .method = HTTP_GET,
      .handler = mic_handler, .user_ctx = NULL};

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
