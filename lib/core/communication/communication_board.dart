/// AAC iletişim panosu (v3 Faz 16).
/// Dokun → TTS; [usageCount] ile sık kullanılanı öne çıkar.
class CommCard {
  CommCard({
    required this.id,
    required this.label,
    required this.iconName,
    this.audioUrl,
    this.usageCount = 0,
  });

  final String id;
  final String label;
  final String iconName;
  final String? audioUrl;
  int usageCount;

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'iconName': iconName,
        'audioUrl': audioUrl,
        'usageCount': usageCount,
      };

  factory CommCard.fromMap(Map<String, dynamic> map) {
    return CommCard(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
      iconName: map['iconName'] as String? ?? 'chat',
      audioUrl: map['audioUrl'] as String?,
      usageCount: map['usageCount'] as int? ?? 0,
    );
  }

  CommCard copyWith({int? usageCount}) {
    return CommCard(
      id: id,
      label: label,
      iconName: iconName,
      audioUrl: audioUrl,
      usageCount: usageCount ?? this.usageCount,
    );
  }
}

class CommunicationBoard {
  CommunicationBoard({required List<CommCard> cards})
      : _cards = List<CommCard>.from(cards);

  final List<CommCard> _cards;

  /// usageCount azalan; eşitlikte orijinal sıra.
  List<CommCard> get cardsSorted {
    final indexed = [
      for (var i = 0; i < _cards.length; i++) (i: i, c: _cards[i]),
    ];
    indexed.sort((a, b) {
      final byUsage = b.c.usageCount.compareTo(a.c.usageCount);
      if (byUsage != 0) return byUsage;
      return a.i.compareTo(b.i);
    });
    return [for (final e in indexed) e.c];
  }

  List<CommCard> get cards => List.unmodifiable(_cards);

  /// Dokunma: sayacı artır, kartı döndür (TTS için).
  CommCard? tap(String id) {
    for (final c in _cards) {
      if (c.id == id) {
        c.usageCount++;
        return c;
      }
    }
    return null;
  }

  void setUsageCounts(Map<String, int> counts) {
    for (final c in _cards) {
      final n = counts[c.id];
      if (n != null) c.usageCount = n;
    }
  }

  Map<String, int> usageSnapshot() => {
        for (final c in _cards) c.id: c.usageCount,
      };

  static List<CommCard> defaultCards() => [
        CommCard(id: 'water', label: 'Su istiyorum', iconName: 'water_drop'),
        CommCard(id: 'hungry', label: 'Acıktım', iconName: 'restaurant'),
        CommCard(id: 'help', label: 'Yardım', iconName: 'handshake'),
        CommCard(id: 'bathroom', label: 'Tuvalet', iconName: 'wc'),
        CommCard(id: 'break', label: 'Mola', iconName: 'pause_circle'),
        CommCard(id: 'yes', label: 'Evet', iconName: 'thumb_up'),
        CommCard(id: 'no', label: 'Hayır', iconName: 'thumb_down'),
        CommCard(id: 'more', label: 'Daha fazla', iconName: 'add_circle'),
      ];
}
