import 'package:flutter/material.dart';
import '../../core/music_constants.dart';
import '../../models/tuner_state.dart';
import '../../notifiers/tuner_notifier.dart';
import '../widgets/tuner_display.dart';
import '../widgets/tuner_string_buttons.dart';
import '../widgets/reference_tone_panel.dart';

class TunerScreen extends StatefulWidget {
  final TunerNotifier notifier;

  const TunerScreen({super.key, required this.notifier});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  TunerNotifier get _n => widget.notifier;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('调音器'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Tuner display — rebuilds when pitch data changes (throttled)
            _TunerDisplaySection(notifier: _n),
            const SizedBox(height: 24),
            // Mode toggle
            _ModeSection(notifier: _n),
            const SizedBox(height: 24),
            // Guitar string buttons
            _StringButtonsSection(notifier: _n),
            const SizedBox(height: 32),
            // Reference tone panel — only rebuilds when reference tone state changes
            _ReferenceToneSection(notifier: _n),
            const SizedBox(height: 32),
            // Start/Stop button
            _StartStopButton(notifier: _n),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    final s = _n.state;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('设置', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('A4 参考音: ${s.a4Reference.toStringAsFixed(1)} Hz'),
            Slider(
              value: s.a4Reference,
              min: 420,
              max: 460,
              divisions: 80,
              label: '${s.a4Reference.toStringAsFixed(1)} Hz',
              onChanged: (v) => _n.setA4Reference(v),
            ),
            TextButton(
              onPressed: () {
                _n.setA4Reference(440.0);
                Navigator.pop(ctx);
              },
              child: const Text('恢复默认 (440 Hz)'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Only rebuilds when pitch data (frequency/cents/note) changes
class _TunerDisplaySection extends StatelessWidget {
  final TunerNotifier notifier;

  const _TunerDisplaySection({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        final s = notifier.state;
        return Column(
          children: [
            TunerDisplay(
              detectedNote: s.detectedNote,
              detectedCents: s.detectedCents,
              isListening: s.isListening,
            ),
            if (s.detectedFrequency != null)
              SizedBox(
                height: 28,
                child: Text(
                  '${s.detectedFrequency!.toStringAsFixed(1)} Hz',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              )
            else
              SizedBox(height: 28),
          ],
        );
      },
    );
  }
}

// Only rebuilds when mode changes
class _ModeSection extends StatelessWidget {
  final TunerNotifier notifier;

  const _ModeSection({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        final mode = notifier.state.mode;
        return SegmentedButton<TunerMode>(
          segments: const [
            ButtonSegment(value: TunerMode.guitar, label: Text('吉他')),
            ButtonSegment(value: TunerMode.chromatic, label: Text('半音阶')),
          ],
          selected: {mode},
          onSelectionChanged: (m) => notifier.setMode(m.first),
        );
      },
    );
  }
}

// Only rebuilds when mode or targetNote changes
class _StringButtonsSection extends StatelessWidget {
  final TunerNotifier notifier;

  const _StringButtonsSection({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        final s = notifier.state;
        if (s.mode != TunerMode.guitar) return const SizedBox.shrink();
        final strings = guitarStrings(s.a4Reference);
        return TunerStringButtons(
          strings: strings,
          targetNote: s.targetNote,
          onStringSelected: notifier.selectString,
        );
      },
    );
  }
}

// Only rebuilds when isPlayingReference or targetNote changes
class _ReferenceToneSection extends StatelessWidget {
  final TunerNotifier notifier;

  const _ReferenceToneSection({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        final s = notifier.state;
        final strings = guitarStrings(s.a4Reference);
        return ReferenceTonePanel(
          strings: strings,
          currentNote: s.targetNote,
          isPlaying: s.isPlayingReference,
          onPlay: notifier.playReferenceTone,
          onStop: notifier.stopReferenceTone,
        );
      },
    );
  }
}

// Only rebuilds when isListening changes
class _StartStopButton extends StatelessWidget {
  final TunerNotifier notifier;

  const _StartStopButton({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        final isListening = notifier.state.isListening;
        return FilledButton.icon(
          onPressed: isListening
              ? notifier.stopListening
              : notifier.startListening,
          icon: Icon(isListening ? Icons.mic_off : Icons.mic),
          label: Text(isListening ? '停止监听' : '开始监听'),
          style: FilledButton.styleFrom(minimumSize: const Size(200, 52)),
        );
      },
    );
  }
}
