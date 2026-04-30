import 'enums.dart';

class Preset {
  final String name;
  final int bpm;
  final int beatsPerMeasure;
  final NoteValue noteValue;
  final SoundType soundType;

  const Preset({
    required this.name,
    required this.bpm,
    required this.beatsPerMeasure,
    required this.noteValue,
    required this.soundType,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'bpm': bpm,
        'beatsPerMeasure': beatsPerMeasure,
        'noteValue': noteValue.name,
        'soundType': soundType.name,
      };

  factory Preset.fromJson(Map<String, dynamic> json) => Preset(
        name: json['name'] as String,
        bpm: json['bpm'] as int,
        beatsPerMeasure: json['beatsPerMeasure'] as int,
        noteValue: NoteValue.values.firstWhere((e) => e.name == json['noteValue']),
        soundType: SoundType.values.firstWhere((e) => e.name == json['soundType']),
      );
}
