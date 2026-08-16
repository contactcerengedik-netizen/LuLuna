/// Kavram motoru modelleri (prompt v3 §2.1).
enum ConceptCategory {
  object,
  animal,
  emotion,
  action,
  food,
  place,
  other;

  String get label => switch (this) {
        ConceptCategory.object => 'Nesne',
        ConceptCategory.animal => 'Hayvan',
        ConceptCategory.emotion => 'Duygu',
        ConceptCategory.action => 'Eylem',
        ConceptCategory.food => 'Yiyecek',
        ConceptCategory.place => 'Yer',
        ConceptCategory.other => 'Diğer',
      };
}

/// Desteklenen modül hedefleri — generator’lar event-driven bağlanır.
/// v3 §1: 15 beceri alanına yayılım (Faz 17).
enum ConceptModule {
  listening,
  mathematics,
  turkish,
  tracing,
  coloring,
  matching,
  pattern,
  data,
  memory,
  speech,
  emotion,
  routine,
  aac,
  puzzle,
  counting;

  String get label => switch (this) {
        ConceptModule.listening => 'Dinleme–Anlama',
        ConceptModule.mathematics => 'Dört İşlem',
        ConceptModule.turkish => 'Türkçe',
        ConceptModule.tracing => 'Çizgi / Motor',
        ConceptModule.coloring => 'Boyama',
        ConceptModule.matching => 'Eşleştirme',
        ConceptModule.pattern => 'Örüntü / Mantık',
        ConceptModule.data => 'Grafik / Veri',
        ConceptModule.memory => 'Hafıza / Dikkat',
        ConceptModule.speech => 'Konuşma / Telaffuz',
        ConceptModule.emotion => 'Duygu / Sosyal',
        ConceptModule.routine => 'Günlük Yaşam',
        ConceptModule.aac => 'AAC Panosu',
        ConceptModule.puzzle => 'Puzzle',
        ConceptModule.counting => 'Sayma',
      };

  /// Öğrenci uygulamasındaki rota (yayın sonrası deep link).
  String get studentRoute => switch (this) {
        ConceptModule.listening || ConceptModule.turkish => '/student/language',
        ConceptModule.mathematics || ConceptModule.counting => '/student/math',
        ConceptModule.tracing => '/student/tracing',
        ConceptModule.coloring => '/student/coloring',
        ConceptModule.matching => '/student/categorize',
        ConceptModule.pattern || ConceptModule.data => '/student/cognition',
        ConceptModule.memory => '/student/memory',
        ConceptModule.speech || ConceptModule.emotion => '/student/speech',
        ConceptModule.routine => '/student/daily-life/routine',
        ConceptModule.aac => '/student/daily-life/aac',
        ConceptModule.puzzle => '/student/puzzle',
      };
}

enum ConceptAssignmentStatus { draft, generating, readyForReview, published }

enum ConceptModuleOutputStatus { pending, ready, published }

class Concept {
  const Concept({
    required this.id,
    required this.name,
    required this.category,
    required this.imagePromptSeed,
    this.relatedSkills = const [],
  });

  final String id;
  final String name;
  final ConceptCategory category;
  final String imagePromptSeed;
  final List<ConceptModule> relatedSkills;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category.name,
        'imagePromptSeed': imagePromptSeed,
        'relatedSkills': relatedSkills.map((e) => e.name).toList(),
      };

  factory Concept.fromMap(Map<String, dynamic> map) {
    return Concept(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: ConceptCategory.values.asNameMap()[map['category'] as String?] ??
          ConceptCategory.other,
      imagePromptSeed: map['imagePromptSeed'] as String? ?? '',
      relatedSkills: [
        for (final e in (map['relatedSkills'] as List? ?? const []))
          if (ConceptModule.values.asNameMap()['$e'] != null)
            ConceptModule.values.asNameMap()['$e']!,
      ],
    );
  }
}

class ConceptAssignment {
  const ConceptAssignment({
    required this.id,
    required this.conceptId,
    required this.conceptName,
    required this.studentId,
    required this.teacherId,
    required this.createdAt,
    required this.status,
    this.outputs = const [],
    this.consistencyGroupId,
  });

  final String id;
  final String conceptId;
  final String conceptName;
  final String studentId;
  final String teacherId;
  final DateTime createdAt;
  final ConceptAssignmentStatus status;
  final List<ConceptModuleOutput> outputs;
  /// Aynı atamadaki sorular stil tutarlılığı için aynı grup id.
  final String? consistencyGroupId;

  ConceptAssignment copyWith({
    ConceptAssignmentStatus? status,
    List<ConceptModuleOutput>? outputs,
  }) {
    return ConceptAssignment(
      id: id,
      conceptId: conceptId,
      conceptName: conceptName,
      studentId: studentId,
      teacherId: teacherId,
      createdAt: createdAt,
      status: status ?? this.status,
      outputs: outputs ?? this.outputs,
      consistencyGroupId: consistencyGroupId,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'conceptId': conceptId,
        'conceptName': conceptName,
        'studentId': studentId,
        'teacherId': teacherId,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'consistencyGroupId': consistencyGroupId,
        'outputs': outputs.map((e) => e.toMap()).toList(),
      };

  factory ConceptAssignment.fromMap(Map<String, dynamic> map) {
    return ConceptAssignment(
      id: map['id'] as String? ?? '',
      conceptId: map['conceptId'] as String? ?? '',
      conceptName: map['conceptName'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      teacherId: map['teacherId'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      status: ConceptAssignmentStatus.values
              .asNameMap()[map['status'] as String?] ??
          ConceptAssignmentStatus.draft,
      consistencyGroupId: map['consistencyGroupId'] as String?,
      outputs: [
        for (final e in (map['outputs'] as List? ?? const []))
          ConceptModuleOutput.fromMap(Map<String, dynamic>.from(e as Map)),
      ],
    );
  }
}

class ConceptModuleOutput {
  const ConceptModuleOutput({
    required this.id,
    required this.module,
    required this.status,
    this.generatedContentId,
    this.previewTitle,
    this.previewBody,
    this.imageSeed,
    this.studentRoute,
  });

  final String id;
  final ConceptModule module;
  final ConceptModuleOutputStatus status;
  final String? generatedContentId;
  final String? previewTitle;
  final String? previewBody;
  /// Mock / gerçek görsel için benzersiz seed (Kural A).
  final String? imageSeed;
  final String? studentRoute;

  ConceptModuleOutput copyWith({
    ConceptModuleOutputStatus? status,
    String? generatedContentId,
    String? previewTitle,
    String? previewBody,
    String? imageSeed,
    String? studentRoute,
  }) {
    return ConceptModuleOutput(
      id: id,
      module: module,
      status: status ?? this.status,
      generatedContentId: generatedContentId ?? this.generatedContentId,
      previewTitle: previewTitle ?? this.previewTitle,
      previewBody: previewBody ?? this.previewBody,
      imageSeed: imageSeed ?? this.imageSeed,
      studentRoute: studentRoute ?? this.studentRoute,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'module': module.name,
        'status': status.name,
        'generatedContentId': generatedContentId,
        'previewTitle': previewTitle,
        'previewBody': previewBody,
        'imageSeed': imageSeed,
        'studentRoute': studentRoute,
      };

  factory ConceptModuleOutput.fromMap(Map<String, dynamic> map) {
    return ConceptModuleOutput(
      id: map['id'] as String? ?? '',
      module: ConceptModule.values.asNameMap()[map['module'] as String?] ??
          ConceptModule.turkish,
      status: ConceptModuleOutputStatus.values
              .asNameMap()[map['status'] as String?] ??
          ConceptModuleOutputStatus.pending,
      generatedContentId: map['generatedContentId'] as String?,
      previewTitle: map['previewTitle'] as String?,
      previewBody: map['previewBody'] as String?,
      imageSeed: map['imageSeed'] as String?,
      studentRoute: map['studentRoute'] as String?,
    );
  }
}
