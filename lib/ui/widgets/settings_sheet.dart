import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/preset.dart';
import '../../notifiers/metronome_notifier.dart';
import '../../services/preset_repository.dart';

class SettingsSheet extends StatelessWidget {
  final MetronomeNotifier notifier;

  const SettingsSheet({super.key, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text('设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('导出预设'),
            subtitle: const Text('保存到系统 Downloads 目录'),
            onTap: () => _exportPresets(context),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('导入预设'),
            subtitle: const Text('从系统 Downloads 目录读取'),
            onTap: () => _importPresets(context),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // For Android 11+ (API 30+)
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }

    // For Android 10 and below
    if (await Permission.storage.request().isGranted) {
      return true;
    }

    return false;
  }

  Future<Directory> _getDownloadsDir() async {
    if (Platform.isAndroid) {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final path = extDir.path;
        final idx = path.indexOf('/Android');
        if (idx > 0) {
          final downloadsPath = '${path.substring(0, idx)}/Download';
          final downloads = Directory(downloadsPath);
          return downloads;
        }
      }
    }
    return await getApplicationDocumentsDirectory();
  }

  Future<void> _exportPresets(BuildContext context) async {
    try {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        if (!context.mounted) return;
        _showSnackBar(context, '需要存储权限才能导出，请在设置中开启');
        return;
      }

      final repo = PresetRepository();
      final presets = await repo.getAll();
      if (presets.isEmpty) {
        if (!context.mounted) return;
        _showSnackBar(context, '没有预设可导出');
        return;
      }
      final json = jsonEncode(presets.map((p) => p.toJson()).toList());
      final downloadsDir = await _getDownloadsDir();
      
      // Ensure directory exists
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      
      final file = File('${downloadsDir.path}/metronome_presets.json');
      await file.writeAsString(json);
      
      if (!context.mounted) return;
      _showSnackBar(context, '已导出到 ${file.path}');
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, '导出失败: $e');
    }
  }

  Future<void> _importPresets(BuildContext context) async {
    try {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        if (!context.mounted) return;
        _showSnackBar(context, '需要存储权限才能导入');
        return;
      }

      final downloadsDir = await _getDownloadsDir();
      final file = File('${downloadsDir.path}/metronome_presets.json');
      if (!await file.exists()) {
        if (!context.mounted) return;
        _showSnackBar(context, '未找到备份文件: ${file.path}');
        return;
      }

      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>;

      final repo = PresetRepository();
      final existing = await repo.getAll();
      final newPresets = list.map((e) => Preset.fromJson(e as Map<String, dynamic>)).toList();

      int imported = 0;
      for (final preset in newPresets) {
        final idx = existing.indexWhere((p) => p.name == preset.name);
        if (idx >= 0) {
          existing[idx] = preset;
        } else {
          existing.add(preset);
        }
        imported++;
      }

      await repo.saveAll(existing);
      await notifier.refreshPresets();
      if (!context.mounted) return;
      _showSnackBar(context, '成功导入 $imported 个预设');
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, '导入失败: $e');
    }
  }

  void _showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}