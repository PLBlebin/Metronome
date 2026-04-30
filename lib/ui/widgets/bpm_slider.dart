import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants.dart';

class BpmSlider extends StatelessWidget {
  final int bpm;
  final ValueChanged<int> onChanged;

  const BpmSlider({super.key, required this.bpm, required this.onChanged});

  // Map linear slider 0..1 → BPM with logarithmic feel
  static double _bpmToSlider(int bpm) {
    final t = (bpm - kBpmMin) / (kBpmMax - kBpmMin);
    return sqrt(t);
  }

  static int _sliderToBpm(double v) {
    final t = v * v;
    return (kBpmMin + t * (kBpmMax - kBpmMin)).round().clamp(kBpmMin, kBpmMax);
  }

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: _bpmToSlider(bpm),
      min: 0,
      max: 1,
      onChanged: (v) => onChanged(_sliderToBpm(v)),
    );
  }
}
