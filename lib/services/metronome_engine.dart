import 'dart:async';
import 'dart:isolate';
import '../core/constants.dart';
import '../models/metronome_state.dart';
import 'audio_pool.dart';

// Messages sent TO the timing isolate
class _IsolateConfig {
  final SendPort replyPort;
  final int bpm;
  final int beatsPerMeasure;
  final int subdivisionFactor;

  const _IsolateConfig({
    required this.replyPort,
    required this.bpm,
    required this.beatsPerMeasure,
    required this.subdivisionFactor,
  });
}

class _IsolateUpdate {
  final int bpm;
  final int beatsPerMeasure;
  final int subdivisionFactor;

  const _IsolateUpdate({
    required this.bpm,
    required this.beatsPerMeasure,
    required this.subdivisionFactor,
  });
}

class _IsolateStop {}

// Messages sent FROM the timing isolate
class ScheduledBeat {
  final int delayUs; // microseconds from now
  final int beatIndex; // 0-based beat within the measure
  final int subdivStep; // 0-based subdivision step within a beat
  final bool isStrong; // true if first beat of measure
  final bool isBeat; // true if on the beat (subdivStep == 0)

  const ScheduledBeat({
    required this.delayUs,
    required this.beatIndex,
    required this.subdivStep,
    required this.isStrong,
    required this.isBeat,
  });
}

// Top-level function for isolate entry (must be static/top-level)
void _timingIsolateEntry(_IsolateConfig config) {
  var bpm = config.bpm;
  var beatsPerMeasure = config.beatsPerMeasure;
  var subdivisionFactor = config.subdivisionFactor;

  final receivePort = ReceivePort();
  config.replyPort.send(receivePort.sendPort);

  final sw = Stopwatch()..start();
  final int lookaheadUs = kLookaheadMs * 1000;

  double subdivIntervalUs() => 60000000.0 / bpm / subdivisionFactor;

  int totalSubdivisions = 0; // ever-increasing counter
  double nextBeatUs = 0.0; // absolute us from sw start for next event

  // Listen for config updates or stop
  receivePort.listen((msg) {
    if (msg is _IsolateUpdate) {
      // Recalculate next beat time to preserve phase
      final nowUs = sw.elapsedMicroseconds.toDouble();
      final oldInterval = subdivIntervalUs();
      bpm = msg.bpm;
      beatsPerMeasure = msg.beatsPerMeasure;
      subdivisionFactor = msg.subdivisionFactor;
      final newInterval = subdivIntervalUs();
      // Keep the next beat at the same relative offset
      if (nextBeatUs > nowUs) {
        nextBeatUs = nowUs + (nextBeatUs - nowUs) * (newInterval / oldInterval);
      } else {
        nextBeatUs = nowUs + newInterval;
      }
    } else if (msg is _IsolateStop) {
      receivePort.close();
    }
  });

  Timer.periodic(Duration(milliseconds: kSchedulerIntervalMs), (timer) {
    final nowUs = sw.elapsedMicroseconds.toDouble();
    final horizon = nowUs + lookaheadUs;

    while (nextBeatUs < horizon) {
      final delayUs = (nextBeatUs - nowUs).round();
      final subdiv = totalSubdivisions % subdivisionFactor;
      final beat = (totalSubdivisions ~/ subdivisionFactor) % beatsPerMeasure;
      config.replyPort.send(ScheduledBeat(
        delayUs: delayUs < 0 ? 0 : delayUs,
        beatIndex: beat,
        subdivStep: subdiv,
        isStrong: beat == 0 && subdiv == 0,
        isBeat: subdiv == 0,
      ));
      totalSubdivisions++;
      nextBeatUs += subdivIntervalUs();
    }
  });
}

class MetronomeEngine {
  final AudioPool audioPool;

  Isolate? _isolate;
  SendPort? _isolateSendPort;
  ReceivePort? _receivePort;
  StreamController<ScheduledBeat>? _beatController;
  int _barCount = 0;
  bool _muted = false;

  MetronomeState _state = const MetronomeState();

  MetronomeState get state => _state;

  // Stream of beat events for UI
  Stream<ScheduledBeat>? get beatStream => _beatController?.stream;

  MetronomeEngine(this.audioPool);

  Future<void> start(MetronomeState state) async {
    _state = state;
    _barCount = 0;
    _muted = false;
    await _launchIsolate();
  }

  Future<void> stop() async {
    _isolateSendPort?.send(_IsolateStop());
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _isolateSendPort = null;
    _receivePort?.close();
    _receivePort = null;
    await _beatController?.close();
    _beatController = null;
    _state = _state.copyWith(isRunning: false, currentBeat: 0, currentSubdivision: 0);
  }

  void updateConfig(MetronomeState state) {
    _state = state;
    // Reset mute if disabled
    if (!state.muteEnabled) _muted = false;
    if (_isolateSendPort != null) {
      _isolateSendPort!.send(_IsolateUpdate(
        bpm: state.bpm,
        beatsPerMeasure: state.beatsPerMeasure,
        subdivisionFactor: state.subdivision.factor,
      ));
    }
  }

  Future<void> _launchIsolate() async {
    _beatController = StreamController<ScheduledBeat>.broadcast();
    _receivePort = ReceivePort();

    final config = _IsolateConfig(
      replyPort: _receivePort!.sendPort,
      bpm: _state.bpm,
      beatsPerMeasure: _state.beatsPerMeasure,
      subdivisionFactor: _state.subdivision.factor,
    );

    _isolate = await Isolate.spawn(_timingIsolateEntry, config);

    bool gotSendPort = false;
    _receivePort!.listen((msg) {
      if (!gotSendPort) {
        _isolateSendPort = msg as SendPort;
        gotSendPort = true;
        return;
      }
      if (msg is ScheduledBeat) {
        _handleScheduledBeat(msg);
      }
    });
  }

  void _handleScheduledBeat(ScheduledBeat beat) {
    // Update bar count and practice modes
    if (beat.isStrong) {
      _barCount++;
      _applyPracticeModes();
    }

    // Update visible beat state
    _state = _state.copyWith(
      currentBeat: beat.beatIndex,
      currentSubdivision: beat.subdivStep,
    );

    // Emit for UI — delayed to match audio playback time
    final delay = Duration(microseconds: beat.delayUs);
    if (beat.delayUs > 0) {
      Future.delayed(delay, () => _beatController?.add(beat));
    } else {
      _beatController?.add(beat);
    }

    // Play audio
    if (!_muted) {
      final isMainBeat = beat.isBeat;
      final volume = isMainBeat
          ? _state.volume
          : _state.volume * kSubdivisionVolumeRatio;
      audioPool.playBeat(
        type: _state.soundType,
        isStrong: beat.isStrong,
        volume: volume,
        delay: delay,
      );
    }
  }

  void _applyPracticeModes() {
    final s = _state;

    // Mute mode: play muteEveryNBars bars, then mute muteDurationBars bars, repeat
    if (s.muteEnabled) {
      final cycle = s.muteEveryNBars + s.muteDurationBars;
      final posInCycle = ((_barCount - 1) % cycle) + 1; // 1-indexed
      _muted = posInCycle > s.muteEveryNBars;
    } else {
      _muted = false;
    }

    // Ramp mode: every muteEveryNBars bars, speed up
    if (s.rampEnabled && _barCount > 0 && _barCount % s.rampEveryNBars == 0) {
      final newBpm = (s.bpm + s.rampByBpm).clamp(kBpmMin, kBpmMax);
      if (newBpm != s.bpm) {
        _state = s.copyWith(bpm: newBpm);
        _isolateSendPort?.send(_IsolateUpdate(
          bpm: newBpm,
          beatsPerMeasure: s.beatsPerMeasure,
          subdivisionFactor: s.subdivision.factor,
        ));
      }
    }
  }
}
