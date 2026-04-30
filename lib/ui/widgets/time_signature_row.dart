import 'package:flutter/material.dart';
import '../../models/enums.dart';

class TimeSignatureRow extends StatelessWidget {
  final int beatsPerMeasure;
  final NoteValue noteValue;
  final ValueChanged<int> onBeatsChanged;
  final ValueChanged<NoteValue> onNoteValueChanged;

  const TimeSignatureRow({
    super.key,
    required this.beatsPerMeasure,
    required this.noteValue,
    required this.onBeatsChanged,
    required this.onNoteValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('拍号：'),
        DropdownButton<int>(
          value: beatsPerMeasure,
          items: List.generate(16, (i) => i + 1)
              .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
              .toList(),
          onChanged: (v) { if (v != null) onBeatsChanged(v); },
        ),
        const Text(' / '),
        DropdownButton<NoteValue>(
          value: noteValue,
          items: NoteValue.values
              .map((v) => DropdownMenuItem(value: v, child: Text(v.label)))
              .toList(),
          onChanged: (v) { if (v != null) onNoteValueChanged(v); },
        ),
      ],
    );
  }
}
