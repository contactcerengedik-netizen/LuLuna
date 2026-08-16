/// Gemini görsel kotası (429 / RESOURCE_EXHAUSTED) — retry yok.
class ImageQuotaExceededException implements Exception {
  const ImageQuotaExceededException([
    this.message =
        'Günlük görsel üretim kotası doldu, yarın tekrar deneyin.',
  ]);

  final String message;

  @override
  String toString() => message;

  /// Dio / HTTP / proxy gövdesinden kota hatası mı?
  static bool matches(Object error) {
    final s = error.toString().toLowerCase();
    if (s.contains('429')) return true;
    if (s.contains('resource_exhausted')) return true;
    if (s.contains('quota')) return true;
    if (s.contains('rate limit') || s.contains('ratelimit')) return true;
    return false;
  }

  static Never throwFrom(Object error) {
    throw ImageQuotaExceededException(
      matches(error)
          ? 'Günlük görsel üretim kotası doldu, yarın tekrar deneyin.'
          : 'Görsel üretimi başarısız: $error',
    );
  }
}
