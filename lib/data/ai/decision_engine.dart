import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Gözlemden (metin + opsiyonel kamera karesi) çocuğa söylenecek kısa
/// yönlendirme cümlesini üreten karar motoru arayüzü.
abstract class DecisionEngine {
  Future<String> decide({
    required String systemPrompt,
    required String observation,
    List<int>? jpegBytes,
  });
}

/// Gemini anahtarını mobil uygulamaya koymadan Supabase Edge Function
/// üzerinden karar üretir. Function çağrısı aktif Supabase oturumunun JWT'sini
/// taşır; gerçek GEMINI_API_KEY yalnızca sunucu secret'ında tutulur.
class SupabaseGeminiDecisionEngine implements DecisionEngine {
  SupabaseGeminiDecisionEngine(this._client);

  final SupabaseClient _client;

  @override
  Future<String> decide({
    required String systemPrompt,
    required String observation,
    List<int>? jpegBytes,
  }) async {
    final response = await _client.functions.invoke(
      'gemini-decide',
      body: {
        'systemPrompt': systemPrompt,
        'observation': observation,
        if (jpegBytes != null) 'jpegBase64': base64Encode(jpegBytes),
      },
    );

    final data = response.data;
    if (response.status != 200 || data is! Map) {
      throw StateError('AI servisi yanıt vermedi (${response.status}).');
    }
    final text = data['text'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw const FormatException('AI servisi yanıtında metin bulunamadı');
    }
    return text.trim();
  }
}

/// Gemini Developer API'sine doğrudan REST çağrısı yapan implementasyon.
///
/// Yalnızca Supabase'siz debug/demo geliştirmede kullanılır. Release
/// derlemesinde API anahtarı uygulamaya gömülmemelidir.
class GeminiDecisionEngine implements DecisionEngine {
  GeminiDecisionEngine({required this.apiKey, required this.model, Dio? dio})
    : _dio = dio ?? Dio();

  final String apiKey;
  final String model;
  final Dio _dio;

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  @override
  Future<String> decide({
    required String systemPrompt,
    required String observation,
    List<int>? jpegBytes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_baseUrl/$model:generateContent',
      options: Options(
        headers: {'x-goog-api-key': apiKey, 'Content-Type': 'application/json'},
      ),
      data: buildRequestBody(
        systemPrompt: systemPrompt,
        observation: observation,
        jpegBytes: jpegBytes,
      ),
    );

    final text = extractText(response.data ?? const {});
    if (text == null || text.isEmpty) {
      throw const FormatException('Gemini yanıtında metin bulunamadı');
    }
    return text.trim();
  }

  static Map<String, dynamic> buildRequestBody({
    required String systemPrompt,
    required String observation,
    List<int>? jpegBytes,
  }) {
    return {
      'system_instruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': observation},
            if (jpegBytes != null)
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Encode(jpegBytes),
                },
              },
          ],
        },
      ],
      // Çocuğa tek kısa cümle söyleneceği için çıktı sınırlı tutulur.
      'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 100},
    };
  }

  static String? extractText(Map<String, dynamic> json) {
    final candidates = json['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;
    final content =
        (candidates.first as Map<String, dynamic>)['content']
            as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    if (parts == null) return null;
    return parts
        .whereType<Map<String, dynamic>>()
        .map((p) => p['text'] as String? ?? '')
        .join()
        .trim();
  }
}
