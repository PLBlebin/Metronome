import 'package:flutter/material.dart';
import '../../models/metronome_state.dart';

class PracticeModePanel extends StatelessWidget {
  final MetronomeState state;
  final void Function(bool) onRampEnabledChanged;
  final void Function(int) onRampEveryNBarsChanged;
  final void Function(int) onRampByBpmChanged;
  final void Function(bool) onMuteEnabledChanged;
  final void Function(int) onMuteEveryNBarsChanged;
  final void Function(int) onMuteDurationBarsChanged;

  const PracticeModePanel({
    super.key,
    required this.state,
    required this.onRampEnabledChanged,
    required this.onRampEveryNBarsChanged,
    required this.onRampByBpmChanged,
    required this.onMuteEnabledChanged,
    required this.onMuteEveryNBarsChanged,
    required this.onMuteDurationBarsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpansionTile(
          title: const Text('渐速练习'),
          leading: Switch(
            value: state.rampEnabled,
            onChanged: onRampEnabledChanged,
          ),
          children: [
            _intRow(
              '每 N 小节加速',
              state.rampEveryNBars,
              1, 32,
              onRampEveryNBarsChanged,
            ),
            _intRow(
              '每次加速 BPM',
              state.rampByBpm,
              1, 20,
              onRampByBpmChanged,
            ),
          ],
        ),
        ExpansionTile(
          title: const Text('静音练习'),
          leading: Switch(
            value: state.muteEnabled,
            onChanged: onMuteEnabledChanged,
          ),
          children: [
            _intRow(
              '每 N 小节静音',
              state.muteEveryNBars,
              1, 32,
              onMuteEveryNBarsChanged,
            ),
            _intRow(
              '静音持续小节',
              state.muteDurationBars,
              1, 16,
              onMuteDurationBarsChanged,
            ),
          ],
        ),
      ],
    );
  }

  Widget _intRow(String label, int value, int min, int max, void Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
