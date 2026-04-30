import 'package:flutter_soloud/flutter_soloud.dart';
import '../models/enums.dart';

class AudioPool {
  final Map<String, AudioSource> _sources = {};

  static String _key(SoundType type, bool isStrong) =>
      '${type.name}_${isStrong ? 'strong' : 'weak'}';

  static String _assetPath(SoundType type, bool isStrong) {
    final strength = isStrong ? 'strong' : 'weak';
    return 'assets/sounds/${type.name}_$strength.wav';
  }

  Future<void> init() async {
    await SoLoud.instance.init();
    for (final type in SoundType.values) {
      for (final isStrong in [true, false]) {
        final key = _key(type, isStrong);
        final path = _assetPath(type, isStrong);
        _sources[key] = await SoLoud.instance.loadAsset(path);
      }
    }
  }

  void playBeat({
    required SoundType type,
    required bool isStrong,
    required double volume,
    Duration delay = Duration.zero,
  }) {
    final key = _key(type, isStrong);
    final source = _sources[key];
    if (source == null) return;
    if (delay == Duration.zero) {
      SoLoud.instance.play(source, volume: volume);
    } else {
      Future.delayed(delay, () {
        if (SoLoud.instance.isInitialized) {
          SoLoud.instance.play(source, volume: volume);
        }
      });
    }
  }

  Future<void> dispose() async {
    for (final source in _sources.values) {
      SoLoud.instance.disposeSource(source);
    }
    _sources.clear();
    SoLoud.instance.deinit();
  }
}
