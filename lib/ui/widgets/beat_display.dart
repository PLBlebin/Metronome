import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/metronome_engine.dart';

class BeatDisplay extends StatefulWidget {
  final Stream<ScheduledBeat> beatStream;
  final int beatsPerMeasure;

  const BeatDisplay({
    super.key,
    required this.beatStream,
    required this.beatsPerMeasure,
  });

  @override
  State<BeatDisplay> createState() => _BeatDisplayState();
}

class _BeatDisplayState extends State<BeatDisplay> {
  StreamSubscription<ScheduledBeat>? _sub;
  int _currentBeat = 0;

  @override
  void initState() {
    super.initState();
    _subscribeToStream();
  }

  @override
  void didUpdateWidget(BeatDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.beatStream != widget.beatStream) {
      _sub?.cancel();
      _subscribeToStream();
    }
  }

  void _subscribeToStream() {
    _sub = widget.beatStream.listen((beat) {
      if (!beat.isBeat) return;
      if (mounted) {
        setState(() {
          _currentBeat = beat.beatIndex;
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.beatsPerMeasure, (i) {
        final isActive = i == _currentBeat;
        final isStrong = i == 0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? (isStrong ? colors.primary : colors.secondary)
                  : colors.surfaceContainerHighest,
              border: Border.all(
                color: isStrong ? colors.primary : colors.secondary,
                width: 2,
              ),
            ),
          ),
        );
      }),
    );
  }
}
