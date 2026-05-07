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
    // Initialize with default target note (E2)
    final initialStrings = guitarStrings(_state.a4Reference);
    if (initialStrings.isNotEmpty) {
      _state = _state.copyWith(targetNote: initialStrings[0]);
    }
    
    _pitchDetector.pitchStream.listen(_onPitchDetected);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final a4 = prefs.getDouble(_a4PrefKey) ?? 440.0;
    
    Note? newTarget;
    if (_state.targetNote != null) {
      final strings = guitarStrings(a4);
      for (final s in strings) {
        if (s.name == _state.targetNote!.name && s.octave == _state.targetNote!.octave) {
          newTarget = s;
          break;
        }
      }
    }

    _state = _state.copyWith(
      a4Reference: a4,
      targetNote: newTarget,
    );
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
    _resetDisplayClearTimer();

    Note note;
    double cents;

    if (_state.mode == TunerMode.guitar && _state.targetNote != null) {
      // Locking mode: only detect the target note
      final target = _state.targetNote!;
      
      // Calculate cents relative to the target note
      cents = _calculateCents(result.frequency, target.frequency);
      
      // Filter: if detected frequency is too far from target (e.g. > 150 cents), ignore it
      // This helps "filter out other tones" as requested.
      if (cents.abs() > 150) {
        if (_state.detectedNote != null) {
          _state = _state.copyWith(clearFrequency: true, clearCents: true, clearDetectedNote: true);
          _throttledNotify();
        }
        return;
      }
      
      note = target;
    } else {
      // Automatic mode: find nearest note
      note = _findNearestNote(result.frequency);
      cents = _calculateCents(result.frequency, note.frequency);
    }

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

  void setTargetNote(Note? note) {
    if (note == null) {
      _state = _state.copyWith(clearTargetNote: true);
    } else {
      _state = _state.copyWith(targetNote: note);
    }
    notifyListeners();
  }

  void selectString(int index) {
    final strings = _guitarStrings;
    if (index >= 0 && index < strings.length) {
      final selected = strings[index];
      // Toggle logic: if same note is selected, deselect it
      if (_state.targetNote != null &&
          _state.targetNote!.name == selected.name &&
          _state.targetNote!.octave == selected.octave) {
        setTargetNote(null);
      } else {
        setTargetNote(selected);
      }
    }
  }

  Future<void> setA4Reference(double hz) async {
    final clamped = hz.clamp(kA4Min, kA4Max);
    
    Note? newTarget;
    if (_state.targetNote != null) {
      final strings = guitarStrings(clamped);
      for (final s in strings) {
        if (s.name == _state.targetNote!.name && s.octave == _state.targetNote!.octave) {
          newTarget = s;
          break;
        }
      }
    }

    _state = _state.copyWith(
      a4Reference: clamped,
      targetNote: newTarget,
      clearFrequency: true,
      clearCents: true,
      clearDetectedNote: true,
    );
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