enum SoundType {
  tick('滴答'),
  wood('木块'),
  electronic('电子');

  const SoundType(this.label);
  final String label;
}

enum Subdivision {
  quarter(1, '♩'),
  eighth(2, '♪'),
  sixteenth(4, '♬'),
  triplet(3, '3');

  const Subdivision(this.factor, this.label);
  final int factor;
  final String label;
}

enum NoteValue {
  half(2, '2'),
  quarter(4, '4'),
  eighth(8, '8'),
  sixteenth(16, '16');

  const NoteValue(this.value, this.label);
  final int value;
  final String label;
}
