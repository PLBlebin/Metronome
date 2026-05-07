import '../core/constants.dart';
import 'note.dart';

enum TunerMode { guitar, chromatic }

class TunerState {
  final bool isListening;
  final double? detectedFrequency;
  final double? detectedCents;
  final Note? detectedNote;
  final Note? targetNote;
  final double a4Reference;
  final TunerMode mode;
  final bool isPlayingReference;
  final double volume;

  const TunerState({
    this.isListening = false,
    this.detectedFrequency,
    this.detectedCents,
    this.detectedNote,
    this.targetNote,
    this.a4Reference = 440.0,
    this.mode = TunerMode.guitar,
    this.isPlayingReference = false,
    this.volume = kVolumeDefault,
  });

  TunerState copyWith({
    bool? isListening,
    double? detectedFrequency,
    double? detectedCents,
    Note? detectedNote,
    Note? targetNote,
    double? a4Reference,
    TunerMode? mode,
    bool? isPlayingReference,
    double? volume,
    bool clearFrequency = false,
    bool clearCents = false,
    bool clearDetectedNote = false,
    bool clearTargetNote = false,
  }) {
    return TunerState(
      isListening: isListening ?? this.isListening,
      detectedFrequency: clearFrequency ? null : (detectedFrequency ?? this.detectedFrequency),
      detectedCents: clearCents ? null : (detectedCents ?? this.detectedCents),
      detectedNote: clearDetectedNote ? null : (detectedNote ?? this.detectedNote),
      targetNote: clearTargetNote ? null : (targetNote ?? this.targetNote),
      a4Reference: a4Reference ?? this.a4Reference,
      mode: mode ?? this.mode,
      isPlayingReference: isPlayingReference ?? this.isPlayingReference,
      volume: volume ?? this.volume,
    );
  }
}