import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants.dart';

class BpmStepButtons extends StatelessWidget {
  final int bpm;
  final ValueChanged<int> onChanged;

  const BpmStepButtons({super.key, required this.bpm, required this.onChanged});

  void _change(int delta) {
    onChanged((bpm + delta).clamp(kBpmMin, kBpmMax));
  }

  Widget _btn(String label, int delta) {
    return _RepeatButton(
      label: label,
      onPress: () => _change(delta),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _btn('-10', -10),
        const SizedBox(width: 8),
        _btn('-1', -1),
        const SizedBox(width: 8),
        _btn('+1', 1),
        const SizedBox(width: 8),
        _btn('+10', 10),
      ],
    );
  }
}

class _RepeatButton extends StatefulWidget {
  final String label;
  final VoidCallback onPress;

  const _RepeatButton({required this.label, required this.onPress});

  @override
  State<_RepeatButton> createState() => _RepeatButtonState();
}

class _RepeatButtonState extends State<_RepeatButton> {
  Timer? _timer;

  void _startRepeat() {
    widget.onPress();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (_) => widget.onPress());
  }

  void _stopRepeat() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _startRepeat(),
      onLongPressEnd: (_) => _stopRepeat(),
      onLongPressCancel: _stopRepeat,
      child: OutlinedButton(
        onPressed: widget.onPress,
        child: Text(widget.label),
      ),
    );
  }
}
