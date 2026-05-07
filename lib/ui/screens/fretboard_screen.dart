import 'package:flutter/material.dart';
import '../../core/music_constants.dart';
import '../../models/note.dart';
import '../../notifiers/tuner_notifier.dart';

class FretboardScreen extends StatelessWidget {
  final TunerNotifier tunerNotifier;

  const FretboardScreen({super.key, required this.tunerNotifier});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('吉他指板图'),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: tunerNotifier,
        builder: (context, _) {
          final a4 = tunerNotifier.state.a4Reference;
          final fretboard = guitarFretboard(a4);
          
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('纵向滚动查看完整指板', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Center(
                      child: IntrinsicWidth(
                        child: Column(
                          children: List.generate(23, (fretIndex) {
                            return _FretRow(
                              fretIndex: fretIndex,
                              notes: fretboard.map((s) => s[fretIndex]).toList(), // 0:E2, 1:A2, 2:D3, 3:G3, 4:B3, 5:E4
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FretRow extends StatelessWidget {
  final int fretIndex;
  final List<Note> notes;

  const _FretRow({required this.fretIndex, required this.notes});

  @override
  Widget build(BuildContext context) {
    final isNut = fretIndex == 0;
    final isMarked = [3, 5, 7, 9, 12, 15, 17, 19, 21].contains(fretIndex);
    final isDoubleMarked = fretIndex == 12;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Fret number on the left
        SizedBox(
          width: 30,
          child: Text(
            isNut ? '0' : '$fretIndex',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isNut ? Colors.orange : Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
        // Strings in this fret
        ...List.generate(notes.length, (stringIndex) {
          // Left to Right: 6th string (E2) to 1st string (E4)
          // stringIndex 0 maps to notes[0] (E2), stringIndex 5 maps to notes[5] (E4)
          final note = notes[stringIndex]; 
          
          return Container(
            width: 50,
            height: isNut ? 30 : 60,
            decoration: BoxDecoration(
              color: Colors.brown.shade800,
              border: Border(
                // Fret wire (horizontal)
                bottom: isNut 
                    ? BorderSide(color: Colors.brown.shade300, width: 6)
                    : BorderSide(color: Colors.grey.shade600, width: 2),
                // String "grooves" or visual separation
                left: BorderSide(color: Colors.black26, width: 0.5),
                right: stringIndex == notes.length - 1 
                    ? BorderSide(color: Colors.black26, width: 0.5) 
                    : BorderSide.none,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Fret dots (centered in the fret)
                if (!isNut) ...[
                   if ((stringIndex == 2 || stringIndex == 3) && isMarked && !isDoubleMarked)
                      _fretDot(),
                   if (isDoubleMarked && (stringIndex == 1 || stringIndex == 4))
                      _fretDot(),
                ],
                
                // Vertical String line
                Center(
                  child: Container(
                    width: 3.5 - stringIndex * 0.5, // Thicker (6th string) on left, Thinner (1st) on right
                    height: double.infinity,
                    color: Colors.grey.shade400,
                  ),
                ),

                // Note label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: _getNoteColor(note.name),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 2,
                        offset: const Offset(1, 1),
                      )
                    ],
                  ),
                  child: Text(
                    note.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _fretDot() {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getNoteColor(String name) {
    if (name.contains('#')) return Colors.blueGrey.shade800;
    switch (name) {
      case 'C': return Colors.red.shade800;
      case 'D': return Colors.orange.shade800;
      case 'E': return Colors.yellow.shade900;
      case 'F': return Colors.green.shade800;
      case 'G': return Colors.blue.shade800;
      case 'A': return Colors.indigo.shade800;
      case 'B': return Colors.purple.shade800;
      default: return Colors.grey.shade800;
    }
  }
}
