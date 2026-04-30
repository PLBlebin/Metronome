import 'package:flutter/material.dart';
import '../../models/note.dart';

class TunerStringButtons extends StatelessWidget {
  final List<Note> strings;
  final Note? targetNote;
  final void Function(int) onStringSelected;

  const TunerStringButtons({
    super.key,
    required this.strings,
    this.targetNote,
    required this.onStringSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(strings.length, (i) {
        final string = strings[i];
        final isSelected = targetNote?.displayName == string.displayName;
        return GestureDetector(
          onTap: () => onStringSelected(i),
          child: Container(
            width: 48,
            height: 64,
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primaryContainer
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? colors.primary : colors.outline,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  string.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: isSelected
                        ? colors.onPrimaryContainer
                        : colors.onSurface,
                  ),
                ),
                Text(
                  '${string.octave}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? colors.onPrimaryContainer.withValues(alpha: 0.8)
                        : colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}