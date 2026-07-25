/// Kriz modunda çalınabilecek sakinleştirici içerik kaynakları.
enum CrisisAudioSource {
  none,
  parentVoice,
  calmingMusic,
}

class CrisisState {
  const CrisisState({
    this.active = false,
    this.playing = CrisisAudioSource.none,
  });

  final bool active;
  final CrisisAudioSource playing;

  CrisisState copyWith({bool? active, CrisisAudioSource? playing}) {
    return CrisisState(
      active: active ?? this.active,
      playing: playing ?? this.playing,
    );
  }
}
