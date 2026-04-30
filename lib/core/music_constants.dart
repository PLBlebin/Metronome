import 'dart:math';
import '../models/note.dart';

const double kA4Default = 440.0;
const double kA4Min = 420.0;
const double kA4Max = 460.0;

// Standard guitar string frequencies (A4 = 440Hz)
List<Note> guitarStrings(double a4) {
  final a4Ratio = a4 / 440.0;
  return [
    Note('E', 2, 82.41 * a4Ratio),
    Note('A', 2, 110.00 * a4Ratio),
    Note('D', 3, 146.83 * a4Ratio),
    Note('G', 3, 196.00 * a4Ratio),
    Note('B', 3, 246.94 * a4Ratio),
    Note('E', 4, 329.63 * a4Ratio),
  ];
}

// Chromatic scale notes for a given A4 reference
List<Note> chromaticScale(double a4) {
  const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  const a4Midi = 69;

  double midiToFreq(int midi) => a4 * pow(2.0, (midi - a4Midi) / 12.0);

  const a4MidiNote = 57; // A3 = 57
  final notes = <Note>[];
  for (int octave = 1; octave <= 6; octave++) {
    for (int i = 0; i < 12; i++) {
      final midi = a4MidiNote + (octave - 3) * 12 + i;
      if (midi < 24 || midi > 96) continue;
      notes.add(Note(noteNames[i], octave, midiToFreq(midi)));
    }
  }
  return notes;
}