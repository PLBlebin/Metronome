import 'package:flutter/material.dart';
import '../../models/note.dart';

class ReferenceTonePanel extends StatelessWidget {
  final List<Note> strings;
  final Note? currentNote;
  final bool isPlaying;
  final void Function(Note) onPlay;
  final VoidCallback onStop;

  const ReferenceTonePanel({
    super.key,
    required this.strings,
    this.currentNote,
    required this.isPlaying,
    required this.onPlay,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text('参考音', style: Theme.of(context).textTheme.labelLarge),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: strings.map((string) {
            final isActive = currentNote?.displayName == string.displayName && isPlaying;
            final bgColor = isActive ? colors.primary : colors.surfaceContainerHighest;
            final textColor = isActive ? colors.onPrimary : colors.onSurface;
            return SizedBox(
              width: 48,
              height: 48,
              child: Material(
                color: bgColor,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => isActive ? onStop() : onPlay(string),
                  child: Center(
                    child: Text(
                      string.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
