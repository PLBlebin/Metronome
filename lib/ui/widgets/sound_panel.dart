import 'package:flutter/material.dart';
import '../../models/enums.dart';

class SoundPanel extends StatelessWidget {
  final SoundType soundType;
  final double volume;
  final ValueChanged<SoundType> onSoundTypeChanged;
  final ValueChanged<double> onVolumeChanged;

  const SoundPanel({
    super.key,
    required this.soundType,
    required this.volume,
    required this.onSoundTypeChanged,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: SoundType.values.map((type) {
            return ChoiceChip(
              label: Text(type.label),
              selected: soundType == type,
              onSelected: (_) => onSoundTypeChanged(type),
            );
          }).toList(),
        ),
        Row(
          children: [
            const Icon(Icons.volume_down),
            Expanded(
              child: Slider(
                value: volume,
                min: 0,
                max: 1,
                divisions: 20,
                label: '${(volume * 100).round()}%',
                onChanged: onVolumeChanged,
              ),
            ),
            const Icon(Icons.volume_up),
          ],
        ),
      ],
    );
  }
}
