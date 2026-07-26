import 'package:dio/dio.dart';

/// SoftAP üzerinden ESP32'ye ev Wi-Fi kimlik bilgisi gönderir.
class Esp32ProvisionClient {
  Esp32ProvisionClient({
    this.softApBaseUrl = defaultSoftApUrl,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  static const defaultSoftApUrl = 'http://192.168.4.1';
  static const softApSsid = 'Luluna-Setup';
  static const softApPassword = 'luluna1234';
  static const mdnsHint = 'http://luluna.local';

  final String softApBaseUrl;
  final Dio _dio;

  /// `application/x-www-form-urlencoded` gövdesi üretir (test edilebilir).
  static String encodeWifiForm({
    required String ssid,
    required String password,
  }) {
    return 'ssid=${Uri.encodeQueryComponent(ssid)}'
        '&pass=${Uri.encodeQueryComponent(password)}';
  }

  Future<ProvisionResult> provision({
    required String ssid,
    required String password,
  }) async {
    final trimmed = ssid.trim();
    if (trimmed.isEmpty) {
      return const ProvisionResult(
        ok: false,
        message: 'Wi-Fi adı (SSID) gerekli',
      );
    }

    final normalized = softApBaseUrl.endsWith('/')
        ? softApBaseUrl.substring(0, softApBaseUrl.length - 1)
        : softApBaseUrl;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$normalized/wifi',
        data: encodeWifiForm(ssid: trimmed, password: password),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
          // Cihaz yanıt sonrası restart eder; bağlantı kopması normal olabilir.
          validateStatus: (code) =>
              code != null && code >= 200 && code < 500,
        ),
      );

      if (response.statusCode == 200) {
        final msg = response.data?['message'] as String? ??
            'Kaydedildi. Cihaz yeniden başlıyor.';
        return ProvisionResult(ok: true, message: msg);
      }
      return ProvisionResult(
        ok: false,
        message: 'Kurulum reddedildi (HTTP ${response.statusCode})',
      );
    } on DioException catch (e) {
      // Restart sırasında socket kapanması başarı sayılabilir.
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return const ProvisionResult(
          ok: true,
          message:
              'İstek gönderildi (cihaz yeniden başlıyor olabilir). '
              'Ev Wi-Fi’ye dönüp http://luluna.local deneyin.',
        );
      }
      return ProvisionResult(ok: false, message: 'Kurulum hatası: $e');
    } catch (e) {
      return ProvisionResult(ok: false, message: 'Kurulum hatası: $e');
    }
  }

  Future<ProvisionResult> resetWifi() async {
    final normalized = softApBaseUrl.endsWith('/')
        ? softApBaseUrl.substring(0, softApBaseUrl.length - 1)
        : softApBaseUrl;
    try {
      await _dio.post<void>(
        '$normalized/wifi/reset',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          validateStatus: (code) => code != null && code < 500,
        ),
      );
      return const ProvisionResult(
        ok: true,
        message: 'Wi-Fi sıfırlandı. SoftAP yeniden açılacak.',
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        return const ProvisionResult(
          ok: true,
          message: 'Sıfırlama gönderildi (cihaz yeniden başlıyor olabilir).',
        );
      }
      return ProvisionResult(ok: false, message: 'Sıfırlama hatası: $e');
    }
  }
}

class ProvisionResult {
  const ProvisionResult({required this.ok, required this.message});

  final bool ok;
  final String message;
}
