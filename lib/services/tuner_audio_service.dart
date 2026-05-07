import 'dart:async';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../models/note.dart';
import '../core/music_constants.dart';
import '../core/constants.dart';

class TunerAudioService {
  final Map<String, AudioSource> _sources = {};
  final List<SoundHandle> _handles = [];

  Future<void> init() async {
    if (!SoLoud.instance.isInitialized) {
      await SoLoud.instance.init();
    }
    for (final string in guitarStrings(kA4Default)) {
      final key = string.displayName;
      final path = 'assets/sounds/tuner/tuner_${string.name.toLowerCase()}${string.octave}.wav';
      _sources[key] = await SoLoud.instance.loadAsset(path);
    }
  }

  void playNote(Note note, {double volume = kVolumeDefault}) {
    final source = _sources[note.displayName];
    if (source == null) return;
    SoLoud.instance.play(source, volume: volume).then((h) => _handles.add(h));
  }

  void stopAll() {
    for (final h in _handles) {
      SoLoud.instance.stop(h);
    }
    _handles.clear();
  }

  Future<void> dispose() async {
    stopAll();
    for (final source in _sources.values) {
      SoLoud.instance.disposeSource(source);
    }
    _sources.clear();
  }
}