import 'package:flutter/material.dart';

class TapTempoButton extends StatefulWidget {
  final ValueChanged<int> onBpmChanged;

  const TapTempoButton({super.key, required this.onBpmChanged});

  @override
  State<TapTempoButton> createState() => _TapTempoButtonState();
}

class _TapTempoButtonState extends State<TapTempoButton> {
  final List<int> _tapTimesUs = [];

  void _onTap() {
    final now = DateTime.now().microsecondsSinceEpoch;

    // Remove taps older than 3 seconds
    _tapTimesUs.removeWhere((t) => now - t > 3000000);
    _tapTimesUs.add(now);

    if (_tapTimesUs.length < 2) return;

    // Keep last 4
    if (_tapTimesUs.length > 4) {
      _tapTimesUs.removeRange(0, _tapTimesUs.length - 4);
    }

    // Compute average interval
    int totalUs = 0;
    for (int i = 1; i < _tapTimesUs.length; i++) {
      totalUs += _tapTimesUs[i] - _tapTimesUs[i - 1];
    }
    final avgUs = totalUs / (_tapTimesUs.length - 1);
    final bpm = (60000000.0 / avgUs).round().clamp(20, 300);
    widget.onBpmChanged(bpm);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.secondaryContainer,
          border: Border.all(color: colors.secondary, width: 2),
        ),
        child: Center(
          child: Text(
            'TAP',
            style: TextStyle(
              color: colors.onSecondaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
