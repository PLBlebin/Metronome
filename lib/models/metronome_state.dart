import '../core/constants.dart';
import 'enums.dart';

class MetronomeState {
  final int bpm;
  final int beatsPerMeasure;
  final NoteValue noteValue;
  final SoundType soundType;
  final double volume;
  final Subdivision subdivision;
  final bool isRunning;
  final int currentBeat; // 0-based, within the measure
  final int currentSubdivision; // 0-based subdivision step within a beat
  // Ramp mode
  final bool rampEnabled;
  final int rampEveryNBars;
  final int rampByBpm;
  // Mute mode
  final bool muteEnabled;
  final int muteEveryNBars;
  final int muteDurationBars;

  const MetronomeState({
    this.bpm = 120,
    this.beatsPerMeasure = 4,
    this.noteValue = NoteValue.quarter,
    this.soundType = SoundType.tick,
    this.volume = kVolumeDefault,
    this.subdivision = Subdivision.quarter,
    this.isRunning = false,
    this.currentBeat = 0,
    this.currentSubdivision = 0,
    this.rampEnabled = false,
    this.rampEveryNBars = 4,
    this.rampByBpm = 5,
    this.muteEnabled = false,
    this.muteEveryNBars = 4,
    this.muteDurationBars = 1,
  });

  MetronomeState copyWith({
    int? bpm,
    int? beatsPerMeasure,
    NoteValue? noteValue,
    SoundType? soundType,
    double? volume,
    Subdivision? subdivision,
    bool? isRunning,
    int? currentBeat,
    int? currentSubdivision,
    bool? rampEnabled,
    int? rampEveryNBars,
    int? rampByBpm,
    bool? muteEnabled,
    int? muteEveryNBars,
    int? muteDurationBars,
  }) {
    return MetronomeState(
      bpm: bpm ?? this.bpm,
      beatsPerMeasure: beatsPerMeasure ?? this.beatsPerMeasure,
      noteValue: noteValue ?? this.noteValue,
      soundType: soundType ?? this.soundType,
      volume: volume ?? this.volume,
      subdivision: subdivision ?? this.subdivision,
      isRunning: isRunning ?? this.isRunning,
      currentBeat: currentBeat ?? this.currentBeat,
      currentSubdivision: currentSubdivision ?? this.currentSubdivision,
      rampEnabled: rampEnabled ?? this.rampEnabled,
      rampEveryNBars: rampEveryNBars ?? this.rampEveryNBars,
      rampByBpm: rampByBpm ?? this.rampByBpm,
      muteEnabled: muteEnabled ?? this.muteEnabled,
      muteEveryNBars: muteEveryNBars ?? this.muteEveryNBars,
      muteDurationBars: muteDurationBars ?? this.muteDurationBars,
    );
  }
}
