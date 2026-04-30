import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants.dart';

class BpmDisplay extends StatelessWidget {
  final int bpm;
  final ValueChanged<int> onChanged;

  const BpmDisplay({super.key, required this.bpm, required this.onChanged});

  Future<void> _showInputDialog(BuildContext context) async {
    final controller = TextEditingController(text: bpm.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('输入 BPM'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          decoration: InputDecoration(
            hintText: '$kBpmMin–$kBpmMax',
          ),
          onSubmitted: (_) => Navigator.of(ctx).pop(
            int.tryParse(controller.text)?.clamp(kBpmMin, kBpmMax),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(
              int.tryParse(controller.text)?.clamp(kBpmMin, kBpmMax),
            ),
            child: const Text('确认'),
          ),
        ],
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () => _showInputDialog(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            bpm.toString(),
            style: textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 96,
            ),
          ),
          Text('BPM', style: textTheme.labelLarge),
        ],
      ),
    );
  }
}
