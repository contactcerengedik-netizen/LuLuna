import '../../../data/models/skill_keys.dart';
import '../../../data/models/skill_level.dart';

/// Faz 19 — kapalı skill_key + confidence ile AI parse sonucu.
class TeacherAiParseResult {
  const TeacherAiParseResult({
    required this.structured,
    required this.confidence,
    this.skillKey,
    this.imagePrompt,
    this.needsCategoryReview = false,
  });

  final StructuredActivity structured;
  final String? skillKey;
  final double confidence;
  final String? imagePrompt;
  final bool needsCategoryReview;

  static const confidenceThreshold = 0.6;

  factory TeacherAiParseResult.fromAiMap(
    Map<String, dynamic> map, {
    required List<String> validSkillKeys,
  }) {
    final rawKey = '${map['skillKey'] ?? map['skill_key'] ?? ''}'.trim();
    final confidence = (map['confidence'] is num)
        ? (map['confidence'] as num).toDouble()
        : double.tryParse('${map['confidence']}') ?? 0.0;
    final inList = rawKey.isNotEmpty && validSkillKeys.contains(rawKey);
    final needsReview = !inList || confidence < confidenceThreshold;
    final structured = StructuredActivity.fromMap({
      ...map,
      'activityType': map['activityType'] ??
          (inList ? 'teacher_ai_$rawKey' : 'teacher_ai_pending'),
      'difficulty': map['difficulty'] ?? 'medium',
      'instruction': map['instruction'] ?? 'Soruyu görsele bakarak çöz.',
      'questionText': map['questionText'] ?? map['question'] ?? '',
      'answer': map['correctAnswer'] ?? map['answer'] ?? '',
      'choices': map['choices'] ?? const [],
    });
    return TeacherAiParseResult(
      structured: structured,
      skillKey: inList ? rawKey : null,
      confidence: confidence.clamp(0.0, 1.0),
      imagePrompt:
          map['imagePrompt'] as String? ?? map['image_prompt'] as String?,
      needsCategoryReview: needsReview,
    );
  }
}

/// AI'dan gelen yapılandırılmış etkinlik (görsel üretiminden ayrı).
class StructuredActivity {
  const StructuredActivity({
    required this.activityType,
    required this.difficulty,
    required this.instruction,
    required this.questionText,
    required this.answer,
    this.choices = const [],
    this.characters = const [],
    this.objects = const [],
    this.operation,
    this.explanation,
    this.raw = const {},
  });

  final String activityType;
  final SkillTier difficulty;
  final String instruction;
  final String questionText;
  final String answer;
  final List<String> choices;
  final List<Map<String, dynamic>> characters;
  final List<Map<String, dynamic>> objects;
  final String? operation;
  final String? explanation;
  final Map<String, dynamic> raw;

  StructuredActivity copyWith({
    String? instruction,
    String? questionText,
    String? answer,
    List<String>? choices,
    String? explanation,
    SkillTier? difficulty,
    String? activityType,
  }) {
    return StructuredActivity(
      activityType: activityType ?? this.activityType,
      difficulty: difficulty ?? this.difficulty,
      instruction: instruction ?? this.instruction,
      questionText: questionText ?? this.questionText,
      answer: answer ?? this.answer,
      choices: choices ?? this.choices,
      characters: characters,
      objects: objects,
      operation: operation,
      explanation: explanation ?? this.explanation,
      raw: raw,
    );
  }

  Map<String, dynamic> toMap() => {
        'activityType': activityType,
        'difficulty': difficulty.name,
        'instruction': instruction,
        'questionText': questionText,
        'answer': answer,
        'choices': choices,
        'characters': characters,
        'objects': objects,
        'operation': operation,
        'explanation': explanation,
      };

  factory StructuredActivity.fromMap(Map<String, dynamic> map) {
    return StructuredActivity(
      activityType: map['activityType'] as String? ?? 'math_addition',
      difficulty:
          SkillTier.values.asNameMap()[map['difficulty'] as String?] ??
              SkillTier.medium,
      instruction: map['instruction'] as String? ?? '',
      questionText: map['questionText'] as String? ??
          map['question'] as String? ??
          '',
      answer: '${map['answer'] ?? map['correctAnswer'] ?? ''}',
      choices: [
        for (final e in (map['choices'] as List? ?? const [])) '$e',
      ],
      characters: [
        for (final e in (map['characters'] as List? ?? const []))
          Map<String, dynamic>.from(e as Map),
      ],
      objects: [
        for (final e in (map['objects'] as List? ?? const []))
          Map<String, dynamic>.from(e as Map),
      ],
      operation: map['operation'] as String?,
      explanation: map['explanation'] as String?,
      raw: Map<String, dynamic>.from(map),
    );
  }
}

class GeneratedImage {
  const GeneratedImage({
    required this.prompt,
    this.assetPath,
    this.description,
    this.isMock = true,
  });

  final String prompt;
  final String? assetPath;
  final String? description;
  final bool isMock;

  Map<String, dynamic> toMap() => {
        'prompt': prompt,
        'assetPath': assetPath,
        'description': description,
        'isMock': isMock,
      };

  factory GeneratedImage.fromMap(Map<String, dynamic> map) {
    return GeneratedImage(
      prompt: map['prompt'] as String? ?? '',
      assetPath: map['assetPath'] as String?,
      description: map['description'] as String?,
      isMock: map['isMock'] as bool? ?? true,
    );
  }
}

enum AiActivityStatus {
  draft,
  preview,
  approved,
  published,
  /// Kota doldu — görsel sonra üretilecek (otomatik retry yok).
  pendingRetry,
}

/// Öğretmen onay akışındaki AI etkinliği.
class TeacherAiActivity {
  const TeacherAiActivity({
    required this.id,
    required this.teacherPrompt,
    required this.structured,
    required this.visualPrompt,
    required this.image,
    required this.status,
    required this.createdAt,
    this.analysis,
    this.scenePlan,
    this.approvedAt,
    this.publishedAt,
    this.skillKey,
    this.confidence = 0,
    this.needsCategoryReview = false,
    this.targetStudentId,
    this.imagePending = false,
    this.source = 'teacher_ai_generated',
  });

  final String id;
  final String teacherPrompt;
  final StructuredActivity structured;
  final String visualPrompt;
  final GeneratedImage image;
  final AiActivityStatus status;
  final DateTime createdAt;
  final ContentAnalysis? analysis;
  final VisualScenePlan? scenePlan;
  final DateTime? approvedAt;
  final DateTime? publishedAt;
  final String? skillKey;
  final double confidence;
  final bool needsCategoryReview;
  final String? targetStudentId;
  final bool imagePending;
  final String source;

  /// Öğrenci yalnızca yayınlanmış içeriği görür (önizleme/onay yeterli değil).
  bool get isStudentVisible => status == AiActivityStatus.published;

  bool get canPublish =>
      !needsCategoryReview &&
      skillKey != null &&
      SkillKeys.mvp.contains(skillKey);

  String get statusLabel => switch (status) {
        AiActivityStatus.draft => 'Taslak',
        AiActivityStatus.preview => 'Önizleme',
        AiActivityStatus.approved => 'Onaylı (yayın bekliyor)',
        AiActivityStatus.published => 'Yayında',
        AiActivityStatus.pendingRetry => 'Görsel bekliyor (kota)',
      };

  TeacherAiActivity copyWith({
    StructuredActivity? structured,
    String? visualPrompt,
    GeneratedImage? image,
    AiActivityStatus? status,
    ContentAnalysis? analysis,
    VisualScenePlan? scenePlan,
    DateTime? approvedAt,
    DateTime? publishedAt,
    String? skillKey,
    double? confidence,
    bool? needsCategoryReview,
    String? targetStudentId,
    bool? imagePending,
    String? source,
    bool clearSkillKey = false,
    bool clearTargetStudent = false,
  }) {
    return TeacherAiActivity(
      id: id,
      teacherPrompt: teacherPrompt,
      structured: structured ?? this.structured,
      visualPrompt: visualPrompt ?? this.visualPrompt,
      image: image ?? this.image,
      status: status ?? this.status,
      createdAt: createdAt,
      analysis: analysis ?? this.analysis,
      scenePlan: scenePlan ?? this.scenePlan,
      approvedAt: approvedAt ?? this.approvedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      skillKey: clearSkillKey ? null : (skillKey ?? this.skillKey),
      confidence: confidence ?? this.confidence,
      needsCategoryReview: needsCategoryReview ?? this.needsCategoryReview,
      targetStudentId:
          clearTargetStudent ? null : (targetStudentId ?? this.targetStudentId),
      imagePending: imagePending ?? this.imagePending,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'teacherPrompt': teacherPrompt,
        'structured': structured.toMap(),
        'visualPrompt': visualPrompt,
        'image': image.toMap(),
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'approvedAt': approvedAt?.toIso8601String(),
        'publishedAt': publishedAt?.toIso8601String(),
        'analysis': analysis?.toMap(),
        'scenePlan': scenePlan?.toMap(),
        'skillKey': skillKey,
        'confidence': confidence,
        'needsCategoryReview': needsCategoryReview,
        'targetStudentId': targetStudentId,
        'imagePending': imagePending,
        'source': source,
      };

  factory TeacherAiActivity.fromMap(Map<String, dynamic> map) {
    return TeacherAiActivity(
      id: map['id'] as String? ?? '',
      teacherPrompt: map['teacherPrompt'] as String? ?? '',
      structured: StructuredActivity.fromMap(
        Map<String, dynamic>.from(map['structured'] as Map? ?? const {}),
      ),
      visualPrompt: map['visualPrompt'] as String? ?? '',
      image: GeneratedImage.fromMap(
        Map<String, dynamic>.from(map['image'] as Map? ?? const {}),
      ),
      status: AiActivityStatus.values.asNameMap()[map['status'] as String?] ??
          AiActivityStatus.draft,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      approvedAt: DateTime.tryParse(map['approvedAt'] as String? ?? ''),
      publishedAt: DateTime.tryParse(map['publishedAt'] as String? ?? ''),
      analysis: map['analysis'] is Map
          ? ContentAnalysis.fromMap(
              Map<String, dynamic>.from(map['analysis'] as Map),
            )
          : null,
      scenePlan: map['scenePlan'] is Map
          ? VisualScenePlan.fromMap(
              Map<String, dynamic>.from(map['scenePlan'] as Map),
            )
          : null,
      skillKey: map['skillKey'] as String?,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      needsCategoryReview: map['needsCategoryReview'] as bool? ?? false,
      targetStudentId: map['targetStudentId'] as String?,
      imagePending: map['imagePending'] as bool? ?? false,
      source: map['source'] as String? ?? 'teacher_ai_generated',
    );
  }
}

/// Prompt analizi — kişi / nesne / sayı / işlem çıkarımı.
class ContentAnalysis {
  const ContentAnalysis({
    this.people = const [],
    this.objects = const [],
    this.numbers = const [],
    this.operation,
    this.notes = const [],
  });

  final List<String> people;
  final List<String> objects;
  final List<int> numbers;
  final String? operation;
  final List<String> notes;

  Map<String, dynamic> toMap() => {
        'people': people,
        'objects': objects,
        'numbers': numbers,
        'operation': operation,
        'notes': notes,
      };

  factory ContentAnalysis.fromMap(Map<String, dynamic> map) {
    return ContentAnalysis(
      people: [for (final e in (map['people'] as List? ?? const [])) '$e'],
      objects: [for (final e in (map['objects'] as List? ?? const [])) '$e'],
      numbers: [
        for (final e in (map['numbers'] as List? ?? const []))
          e is int ? e : int.tryParse('$e') ?? 0,
      ],
      operation: map['operation'] as String?,
      notes: [for (final e in (map['notes'] as List? ?? const [])) '$e'],
    );
  }
}

/// Structured JSON'dan türetilen görsel sahne planı (görsel prompttan ayrı).
class VisualScenePlan {
  const VisualScenePlan({
    required this.background,
    required this.mainSubject,
    this.elements = const [],
    this.forbidden = const [],
  });

  final String background;
  final String mainSubject;
  final List<String> elements;
  final List<String> forbidden;

  Map<String, dynamic> toMap() => {
        'background': background,
        'mainSubject': mainSubject,
        'elements': elements,
        'forbidden': forbidden,
      };

  factory VisualScenePlan.fromMap(Map<String, dynamic> map) {
    return VisualScenePlan(
      background: map['background'] as String? ?? 'plain',
      mainSubject: map['mainSubject'] as String? ?? '',
      elements: [for (final e in (map['elements'] as List? ?? const [])) '$e'],
      forbidden: [for (final e in (map['forbidden'] as List? ?? const [])) '$e'],
    );
  }

  factory VisualScenePlan.fromStructured(StructuredActivity a) {
    final elements = <String>[
      for (final c in a.characters) '${c['name'] ?? 'kişi'}',
      for (final o in a.objects)
        '${o['count'] ?? 1} ${o['type'] ?? 'nesne'}'
            '${o['location'] != null ? ' (${o['location']})' : ''}',
    ];
    return VisualScenePlan(
      background: 'sade düz arka plan',
      mainSubject: elements.isNotEmpty ? elements.first : a.questionText,
      elements: elements,
      forbidden: const [
        'gereksiz dekorasyon',
        'metinde olmayan obje',
        'dikkat dağıtıcı arka plan',
      ],
    );
  }
}
