import 'package:flutter/material.dart';
import '../../models/preset.dart';

class PresetPanel extends StatelessWidget {
  final List<Preset> presets;
  final Future<void> Function(String name) onSave;
  final void Function(Preset) onLoad;
  final Future<void> Function(String name) onDelete;

  const PresetPanel({
    super.key,
    required this.presets,
    required this.onSave,
    required this.onLoad,
    required this.onDelete,
  });

  Future<void> _showSaveDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('保存预设'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '预设名称'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) await onSave(name);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('预设', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showSaveDialog(context),
              icon: const Icon(Icons.save),
              label: const Text('保存当前'),
            ),
          ],
        ),
        if (presets.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('暂无预设', style: TextStyle(color: Colors.grey)),
          )
        else
          ...presets.map((preset) => Dismissible(
                key: ValueKey(preset.name),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => onDelete(preset.name),
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(preset.name),
                  subtitle: Text('${preset.bpm} BPM · ${preset.beatsPerMeasure}/${preset.noteValue.label}'),
                  onTap: () => onLoad(preset),
                ),
              )),
      ],
    );
  }
}
