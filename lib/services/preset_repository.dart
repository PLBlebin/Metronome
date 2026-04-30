import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/preset.dart';

class PresetRepository {
  static const _fileName = 'metronome_presets.json';

  Future<File> get _presetFile async {
    final dir = await getDownloadsDirectory();
    if (dir != null) {
      return File('${dir.path}/$_fileName');
    }
    final appDir = await getApplicationDocumentsDirectory();
    return File('${appDir.path}/$_fileName');
  }

  Future<List<Preset>> getAll() async {
    try {
      final file = await _presetFile;
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      if (raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Preset.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> save(Preset preset) async {
    final presets = await getAll();
    final idx = presets.indexWhere((p) => p.name == preset.name);
    if (idx >= 0) {
      presets[idx] = preset;
    } else {
      presets.add(preset);
    }
    await _persist(presets);
  }

  Future<void> delete(String name) async {
    final presets = await getAll();
    presets.removeWhere((p) => p.name == name);
    await _persist(presets);
  }

  Future<void> saveAll(List<Preset> presets) async {
    await _persist(presets);
  }

  Future<void> _persist(List<Preset> presets) async {
    final file = await _presetFile;
    await file.writeAsString(jsonEncode(presets.map((p) => p.toJson()).toList()));
  }
}