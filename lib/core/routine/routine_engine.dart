/// Günlük rutin motoru (v3 Faz 16) — first–then + adım tamamlama.
class RoutineStep {
  const RoutineStep({
    required this.id,
    required this.label,
    required this.iconName,
    this.audioUrl,
    this.estimatedMinutes = 1,
  });

  final String id;
  final String label;
  final String iconName;
  final String? audioUrl;
  final int estimatedMinutes;

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'iconName': iconName,
        'audioUrl': audioUrl,
        'estimatedMinutes': estimatedMinutes,
      };

  factory RoutineStep.fromMap(Map<String, dynamic> map) {
    return RoutineStep(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
      iconName: map['iconName'] as String? ?? 'circle',
      audioUrl: map['audioUrl'] as String?,
      estimatedMinutes: map['estimatedMinutes'] as int? ?? 1,
    );
  }
}

class RoutineEngine {
  RoutineEngine({
    required List<RoutineStep> steps,
    this.title = 'Rutin',
  }) : assert(steps.isNotEmpty),
        steps = List<RoutineStep>.from(steps);

  final String title;
  final List<RoutineStep> steps;
  final Set<String> _completedIds = {};
  var _index = 0;

  int get index => _index;
  int get total => steps.length;
  bool get isComplete => _completedIds.length >= steps.length;

  RoutineStep get current => steps[_index.clamp(0, steps.length - 1)];

  /// First–Then: şimdi + sonra (varsa).
  ({RoutineStep first, RoutineStep? then}) get firstThen {
    final first = current;
    final thenIdx = _index + 1;
    final then = thenIdx < steps.length ? steps[thenIdx] : null;
    return (first: first, then: then);
  }

  bool isStepDone(String id) => _completedIds.contains(id);

  double get progress =>
      steps.isEmpty ? 0 : _completedIds.length / steps.length;

  int get remainingMinutes {
    var sum = 0;
    for (final s in steps) {
      if (!_completedIds.contains(s.id)) sum += s.estimatedMinutes;
    }
    return sum;
  }

  /// Mevcut adımı tamamla; sıradakine geç.
  bool completeCurrent() {
    if (isComplete) return false;
    _completedIds.add(current.id);
    if (_index < steps.length - 1) {
      _index++;
    }
    return true;
  }

  void reset() {
    _completedIds.clear();
    _index = 0;
  }

  /// Öğretmen/veli düzenlemesi — adım listesini değiştir.
  void replaceSteps(List<RoutineStep> next) {
    assert(next.isNotEmpty);
    steps
      ..clear()
      ..addAll(next);
    reset();
  }

  static List<RoutineStep> morningSample() => const [
        RoutineStep(
          id: 'wake',
          label: 'Uyan',
          iconName: 'bedtime',
          estimatedMinutes: 2,
        ),
        RoutineStep(
          id: 'brush',
          label: 'Diş fırçala',
          iconName: 'cleaning_services',
          estimatedMinutes: 3,
        ),
        RoutineStep(
          id: 'dress',
          label: 'Giyin',
          iconName: 'checkroom',
          estimatedMinutes: 5,
        ),
        RoutineStep(
          id: 'bag',
          label: 'Çanta hazırla',
          iconName: 'backpack',
          estimatedMinutes: 3,
        ),
      ];
}
