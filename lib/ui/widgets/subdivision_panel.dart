import 'package:flutter/material.dart';
import '../../models/enums.dart';

class SubdivisionPanel extends StatelessWidget {
  final Subdivision subdivision;
  final ValueChanged<Subdivision> onChanged;

  const SubdivisionPanel({
    super.key,
    required this.subdivision,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('细分：'),
        const SizedBox(width: 8),
        ...Subdivision.values.map((sub) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text(sub.label),
            selected: subdivision == sub,
            onSelected: (_) => onChanged(sub),
          ),
        )),
      ],
    );
  }
}
