import 'dart:math';

import '../../../core/routine/routine_engine.dart';
import '../../../data/models/sequence_question.dart';

/// Sürükle-bırak rutin sıralama aktivitesi (Faz 18.6).
class RoutineSequenceActivity {
  const RoutineSequenceActivity({
    required this.id,
    required this.title,
    required this.steps,
  });

  final String id;
  final String title;
  final List<RoutineStep> steps;

  List<String> get correctOrder => [for (final s in steps) s.id];

  List<String> get labelsInOrder => [for (final s in steps) s.label];

  SequenceQuestion shuffledSequence({Random? random}) {
    return SequenceQuestion.shuffled(labelsInOrder, random: random);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'steps': [for (final s in steps) s.toMap()],
      };

  factory RoutineSequenceActivity.fromMap(Map<String, dynamic> map) {
    return RoutineSequenceActivity(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Rutin',
      steps: [
        for (final e in (map['steps'] as List? ?? const []))
          RoutineStep.fromMap(Map<String, dynamic>.from(e as Map)),
      ],
    );
  }
}

/// Hazır rutin setleri + öğretmen eklemeleri (yerel).
abstract final class RoutineSequenceCatalog {
  static final List<RoutineSequenceActivity> builtins = [
    RoutineSequenceActivity(
      id: 'morning',
      title: 'Sabah Rutini',
      steps: RoutineEngine.morningSample(),
    ),
    const RoutineSequenceActivity(
      id: 'school_prep',
      title: 'Okula Hazırlanma',
      steps: [
        RoutineStep(id: 'wash', label: 'Yüzünü yıka', iconName: 'soap'),
        RoutineStep(id: 'dress', label: 'Üniformanı giy', iconName: 'checkroom'),
        RoutineStep(
          id: 'breakfast',
          label: 'Kahvaltı yap',
          iconName: 'restaurant',
        ),
        RoutineStep(id: 'bag', label: 'Çantayı al', iconName: 'backpack'),
        RoutineStep(
          id: 'leave',
          label: 'Kapıdan çık',
          iconName: 'door_front_door',
        ),
      ],
    ),
    const RoutineSequenceActivity(
      id: 'after_meal',
      title: 'Yemek Sonrası',
      steps: [
        RoutineStep(id: 'thanks', label: 'Teşekkür et', iconName: 'favorite'),
        RoutineStep(
          id: 'plate',
          label: 'Tabağını götür',
          iconName: 'dinner_dining',
        ),
        RoutineStep(id: 'wash_hands', label: 'Ellerini yıka', iconName: 'soap'),
        RoutineStep(
          id: 'brush',
          label: 'Dişlerini fırçala',
          iconName: 'cleaning_services',
        ),
      ],
    ),
    const RoutineSequenceActivity(
      id: 'bedtime',
      title: 'Uyku Öncesi',
      steps: [
        RoutineStep(id: 'pyjamas', label: 'Pijama giy', iconName: 'checkroom'),
        RoutineStep(
          id: 'brush',
          label: 'Diş fırçala',
          iconName: 'cleaning_services',
        ),
        RoutineStep(id: 'story', label: 'Kitap oku', iconName: 'menu_book'),
        RoutineStep(id: 'lights', label: 'Işığı kapat', iconName: 'bedtime'),
      ],
    ),
    const RoutineSequenceActivity(
      id: 'going_out',
      title: 'Dışarı Çıkmadan Önce',
      steps: [
        RoutineStep(id: 'shoes', label: 'Ayakkabı giy', iconName: 'ice_skating'),
        RoutineStep(id: 'coat', label: 'Montunu giy', iconName: 'checkroom'),
        RoutineStep(id: 'keys', label: 'Anahtarı al', iconName: 'key'),
        RoutineStep(id: 'lock', label: 'Kapıyı kilitle', iconName: 'lock'),
      ],
    ),
  ];

  static final List<RoutineSequenceActivity> _custom = [];

  static List<RoutineSequenceActivity> get all => [...builtins, ..._custom];

  static void addCustom(RoutineSequenceActivity activity) {
    _custom.removeWhere((e) => e.id == activity.id);
    _custom.add(activity);
  }

  static RoutineSequenceActivity? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }
}
