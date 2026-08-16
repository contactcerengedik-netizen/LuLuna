import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/concept_models.dart';

/// Yerel kavram kataloğu + atamalar (demo / offline).
class ConceptRepository {
  ConceptRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _assignKey = 'concept_assignments_v1';

  /// MVP katalog — öğretmen araması; relatedSkills tüm alanlara yayılır (Faz 17).
  static final catalog = <Concept>[
    Concept(
      id: 'c_elma',
      name: 'elma',
      category: ConceptCategory.food,
      imagePromptSeed: 'tek kırmızı elma, sade arka plan, merkezde',
      relatedSkills: ConceptModule.values,
    ),
    Concept(
      id: 'c_kedi',
      name: 'kedi',
      category: ConceptCategory.animal,
      imagePromptSeed: 'tek kedi, sade arka plan, net sınırlar',
      relatedSkills: const [
        ConceptModule.turkish,
        ConceptModule.matching,
        ConceptModule.speech,
        ConceptModule.listening,
        ConceptModule.memory,
        ConceptModule.coloring,
        ConceptModule.tracing,
        ConceptModule.puzzle,
      ],
    ),
    Concept(
      id: 'c_mutlu',
      name: 'mutlu',
      category: ConceptCategory.emotion,
      imagePromptSeed: 'gülümseyen çocuk yüzü, sade arka plan',
      relatedSkills: const [
        ConceptModule.speech,
        ConceptModule.emotion,
        ConceptModule.turkish,
        ConceptModule.listening,
        ConceptModule.matching,
      ],
    ),
    Concept(
      id: 'c_okul',
      name: 'okul',
      category: ConceptCategory.place,
      imagePromptSeed: 'basit okul binası, az detay',
      relatedSkills: const [
        ConceptModule.turkish,
        ConceptModule.listening,
        ConceptModule.matching,
        ConceptModule.routine,
        ConceptModule.aac,
        ConceptModule.data,
        ConceptModule.pattern,
      ],
    ),
  ];

  Concept? byId(String id) {
    for (final c in catalog) {
      if (c.id == id) return c;
    }
    return null;
  }

  Concept? byName(String name) {
    final n = name.trim().toLowerCase();
    for (final c in catalog) {
      if (c.name == n) return c;
    }
    return null;
  }

  List<ConceptAssignment> loadAssignments() {
    final raw = _prefs.getString(_assignKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list)
          ConceptAssignment.fromMap(Map<String, dynamic>.from(e as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveAssignments(List<ConceptAssignment> items) async {
    await _prefs.setString(
      _assignKey,
      jsonEncode(items.map((e) => e.toMap()).toList()),
    );
  }

  Future<void> upsertAssignment(ConceptAssignment a) async {
    final all = [...loadAssignments()];
    final i = all.indexWhere((e) => e.id == a.id);
    if (i >= 0) {
      all[i] = a;
    } else {
      all.insert(0, a);
    }
    await saveAssignments(all);
  }
}
