import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/preset.dart';

class PresetRepository {
  static const _key = 'metronome_presets';

  Future<List<Preset>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Preset.fromJson(e as Map<String, dynamic>)).toList();
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

  Future<void> _persist(List<Preset> presets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(presets.map((p) => p.toJson()).toList()));
  }
}
