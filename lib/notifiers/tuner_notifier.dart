import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/music_constants.dart';
import '../models/note.dart';
import '../models/tuner_state.dart';
import '../services/pitch_detector.dart';
import '../services/tuner_audio_service.dart';

class TunerNotifier extends ChangeNotifier {
  final PitchDetector _pitchDetector;
  final TunerAudioService _audioService;

  TunerState _state = const TunerState();
  TunerState get state => _state;

  StreamSubscription<PitchResult>? _pitchSubscription;
  DateTime? _lastNotifyTime;
  static const _notifyInterval = Duration(milliseconds: 80); // ~12 fps for UI
  Timer? _displayClearTimer;
  bool _stopped = true; // Guard: ignore pitch events after stop

  void _throttledNotify() {
    final now = DateTime.now();
    if (_lastNotifyTime == null || now.difference(_lastNotifyTime!) >= _notifyInterval) {
      _lastNotifyTime = now;
      notifyListeners();
    }
  }

  void _resetDisplayClearTimer() {
    _displayClearTimer?.cancel();
    _displayClearTimer = Timer(const Duration(seconds: 2), () {
      _state = _state.copyWith(clearFrequency: true, clearCents: true, clearDetectedNote: true);
      notifyListeners();
    });
  }

  static const String _a4PrefKey = 'tuner_a4_reference';

  TunerNotifier(this._pitchDetector, this._audioService) {
    _pitchDetector.pitchStream.listen(_onPitchDetected);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final a4 = prefs.getDouble(_a4PrefKey) ?? 440.0;
    _state = _state.copyWith(a4Reference: a4);
    notifyListeners();
  }

  List<Note> get _guitarStrings => guitarStrings(_state.a4Reference);

  Future<void> startListening() async {
    final granted = await _pitchDetector.requestPermission();
    if (!granted) return;
    await _pitchDetector.start();
    _lastNotifyTime = null;
    _stopped = false;
    _displayClearTimer?.cancel(); // Cancel any pending clear timer from previous session
    _state = _state.copyWith(isListening: true, clearFrequency: true, clearCents: true, clearDetectedNote: true);
    notifyListeners();
  }

  Future<void> stopListening() async {
    _stopped = true; // Block any pending pitch events from updating state
    _displayClearTimer?.cancel();
    await _pitchDetector.stop();
    _lastNotifyTime = null;
    // Directly set detected fields to null to prevent subsequent pitch events
    // from overwriting the cleared state before notifyListeners completes.
    _state = TunerState(
      isListening: false,
      detectedFrequency: null,
      detectedCents: null,
      detectedNote: null,
      targetNote: _state.targetNote,
      a4Reference: _state.a4Reference,
      mode: _state.mode,
      isPlayingReference: _state.isPlayingReference,
      volume: _state.volume,
    );
    notifyListeners();
  }

  void _onPitchDetected(PitchResult result) {
    if (_stopped) return;
    if (result.confidence < 0.1 || result.frequency < 50) {
      // Weak signal: don't reset timer — let it run and fire after 1s of silence
      return;
    }

    // Reset the 1-second clear timer on every valid pitch.
    // When user stops playing, the timer will fire after 1s and clear the note.
    _resetDisplayClearTimer();
    final note = _findNearestNote(result.frequency);
    final cents = _calculateCents(result.frequency, note.frequency);
    _state = _state.copyWith(
      detectedFrequency: result.frequency,
      detectedNote: note,
      detectedCents: cents,
    );
    _throttledNotify();
  }

  Note _findNearestNote(double freq) {
    if (_state.mode == TunerMode.guitar) {
      final strings = _guitarStrings;
      // E2附近检测频率容易偏高，给予轻微偏低补偿
      const e2Freq = 82.41;
      const e2Bias = 0.005; // 约0.5%的偏低补偿
      double adjustedFreq = freq;
      if (freq >= e2Freq * (1 - e2Bias) && freq < e2Freq * (1 + 0.03)) {
        adjustedFreq = freq * (1 - e2Bias);
      }

      Note nearest = strings[0];
      double minDiff = (adjustedFreq - nearest.frequency).abs();
      for (final s in strings) {
        final diff = (adjustedFreq - s.frequency).abs();
        if (diff < minDiff) {
          minDiff = diff;
          nearest = s;
        }
      }
      return nearest;
    } else {
      // Chromatic: find nearest note in 12-tone scale
      const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
      const a4Midi = 69;
      final a4 = _state.a4Reference;
      // Find nearest MIDI note
      final midiFloat = 12.0 * (log(freq / a4) / log(2)) + a4Midi;
      final midi = midiFloat.round().clamp(24, 96);
      final freqForMidi = a4 * pow(2.0, (midi - a4Midi) / 12.0);
      final octave = (midi ~/ 12) - 1;
      final noteName = noteNames[midi % 12];
      return Note(noteName, octave, freqForMidi);
    }
  }

  double _calculateCents(double detected, double target) {
    return (1200.0 * log(detected / target) / log(2)).clamp(-50.0, 50.0);
  }

  void setMode(TunerMode mode) {
    _state = _state.copyWith(mode: mode, clearFrequency: true, clearCents: true, clearDetectedNote: true);
    notifyListeners();
  }

  void setTargetNote(Note note) {
    _state = _state.copyWith(targetNote: note);
    notifyListeners();
  }

  void selectString(int index) {
    if (index >= 0 && index < _guitarStrings.length) {
      setTargetNote(_guitarStrings[index]);
    }
  }

  Future<void> setA4Reference(double hz) async {
    final clamped = hz.clamp(kA4Min, kA4Max);
    _state = _state.copyWith(a4Reference: clamped, clearFrequency: true, clearCents: true, clearDetectedNote: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_a4PrefKey, clamped);
    _throttledNotify();
  }

  void playReferenceTone(Note note) {
    _state = _state.copyWith(isPlayingReference: true, targetNote: note);
    _audioService.playNote(note, volume: _state.volume);
    notifyListeners();
  }

  void stopReferenceTone() {
    _audioService.stopAll();
    _state = _state.copyWith(isPlayingReference: false);
    notifyListeners();
  }

  @override
  void dispose() {
    _displayClearTimer?.cancel();
    _pitchSubscription?.cancel();
    _pitchDetector.dispose();
    super.dispose();
  }
}