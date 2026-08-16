/// Per-question görsel üretimi (prompt v3 §2.2 — Kural A).
class QuestionImageSpec {
  const QuestionImageSpec({
    required this.sceneDescription,
    required this.questionId,
    this.objects = const [],
    this.mustMatchCount,
    this.style = 'special_education_simple',
    this.consistencyGroupId,
  });

  final String sceneDescription;
  final String questionId;
  final List<String> objects;
  final int? mustMatchCount;
  final String style;
  /// Aynı öğretmen isteğinden gelen sorular stil tutarlılığı için aynı grup.
  /// Her soru yine AYRI görsel üretir.
  final String? consistencyGroupId;

  Map<String, dynamic> toMap() => {
        'sceneDescription': sceneDescription,
        'questionId': questionId,
        'objects': objects,
        'mustMatchCount': mustMatchCount,
        'style': style,
        'consistencyGroupId': consistencyGroupId,
      };
}
