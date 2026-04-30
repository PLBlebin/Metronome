class Note {
  final String name;
  final int octave;
  final double frequency;

  const Note(this.name, this.octave, this.frequency);

  String get displayName => '$name$octave';

  @override
  bool operator ==(Object other) =>
      other is Note && other.name == name && other.octave == octave;

  @override
  int get hashCode => name.hashCode ^ octave.hashCode;
}