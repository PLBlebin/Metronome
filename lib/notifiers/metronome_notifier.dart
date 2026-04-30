import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../models/enums.dart';
import '../models/metronome_state.dart';
import '../models/preset.dart';
import '../services/metronome_audio_handler.dart';
import '../services/metronome_engine.dart';
import '../services/preset_repository.dart';

class MetronomeNotifier extends ChangeNotifier {
  final MetronomeAudioHandler _handler;
  final PresetRepository _presetRepo = PresetRepository();

  MetronomeState _state = const MetronomeState();
  List<Preset> _presets = [];

  MetronomeState get state => _state;
  List<Preset> get presets => _presets;

  Stream<ScheduledBeat> get beatStream => _handler.beatStream;

  MetronomeNotifier(this._handler) {
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    _presets = await _presetRepo.getAll();
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (_state.isRunning) {
      await _handler.stopMetronome();
      _state = _state.copyWith(isRunning: false, currentBeat: 0, currentSubdivision: 0);
    } else {
      await _handler.startMetronome(_state);
      _state = _state.copyWith(isRunning: true);
    }
    notifyListeners();
  }

  void setBpm(int bpm) {
    final clamped = bpm.clamp(kBpmMin, kBpmMax);
    _state = _state.copyWith(bpm: clamped);
    if (_state.isRunning) _handler.updateConfig(_state);
    notifyListeners();
  }

  void setBeatsPerMeasure(int beats) {
    _state = _state.copyWith(beatsPerMeasure: beats);
    if (_state.isRunning) _handler.updateConfig(_state);
    notifyListeners();
  }

  void setNoteValue(NoteValue nv) {
    _state = _state.copyWith(noteValue: nv);
    notifyListeners();
  }

  void setSoundType(SoundType type) {
    _state = _state.copyWith(soundType: type);
    if (_state.isRunning) _handler.updateConfig(_state);
    notifyListeners();
  }

  void setVolume(double vol) {
    _state = _state.copyWith(volume: vol);
    if (_state.isRunning) _handler.updateConfig(_state);
    notifyListeners();
  }

  void setSubdivision(Subdivision sub) {
    _state = _state.copyWith(subdivision: sub);
    if (_state.isRunning) _handler.updateConfig(_state);
    notifyListeners();
  }

  void setRampEnabled(bool v) { _state = _state.copyWith(rampEnabled: v); if (_state.isRunning) _handler.updateConfig(_state); notifyListeners(); }
  void setRampEveryNBars(int v) { _state = _state.copyWith(rampEveryNBars: v); if (_state.isRunning) _handler.updateConfig(_state); notifyListeners(); }
  void setRampByBpm(int v) { _state = _state.copyWith(rampByBpm: v); if (_state.isRunning) _handler.updateConfig(_state); notifyListeners(); }
  void setMuteEnabled(bool v) { _state = _state.copyWith(muteEnabled: v); if (_state.isRunning) _handler.updateConfig(_state); notifyListeners(); }
  void setMuteEveryNBars(int v) { _state = _state.copyWith(muteEveryNBars: v); if (_state.isRunning) _handler.updateConfig(_state); notifyListeners(); }
  void setMuteDurationBars(int v) { _state = _state.copyWith(muteDurationBars: v); if (_state.isRunning) _handler.updateConfig(_state); notifyListeners(); }

  // Sync engine state (e.g., ramp mode changed BPM)
  void syncFromEngine() {
    final engineState = _handler.engineState;
    if (engineState.bpm != _state.bpm) {
      _state = _state.copyWith(bpm: engineState.bpm);
      notifyListeners();
    }
  }

  Future<void> savePreset(String name) async {
    final preset = Preset(
      name: name,
      bpm: _state.bpm,
      beatsPerMeasure: _state.beatsPerMeasure,
      noteValue: _state.noteValue,
      soundType: _state.soundType,
    );
    await _presetRepo.save(preset);
    await _loadPresets();
  }

  Future<void> loadPreset(Preset preset) async {
    _state = _state.copyWith(
      bpm: preset.bpm,
      beatsPerMeasure: preset.beatsPerMeasure,
      noteValue: preset.noteValue,
      soundType: preset.soundType,
    );
    if (_state.isRunning) _handler.updateConfig(_state);
    notifyListeners();
  }

  Future<void> deletePreset(String name) async {
    await _presetRepo.delete(name);
    await _loadPresets();
  }

  Future<void> refreshPresets() async {
    await _loadPresets();
  }
}
