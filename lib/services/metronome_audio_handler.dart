import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/metronome_state.dart';
import 'audio_pool.dart';
import 'metronome_engine.dart';

class MetronomeAudioHandler extends BaseAudioHandler {
  late final AudioPool _audioPool;
  late final MetronomeEngine _engine;

  Stream<ScheduledBeat> get beatStream =>
      _engine.beatStream ?? const Stream.empty();

  MetronomeState get engineState => _engine.state;

  MetronomeAudioHandler() {
    _audioPool = AudioPool();
    _engine = MetronomeEngine(_audioPool);
  }

  Future<void> initAudio() async {
    await _audioPool.init();
  }

  @override
  Future<void> play() async {
    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.pause, MediaControl.stop],
      playing: true,
      processingState: AudioProcessingState.ready,
    ));
    await WakelockPlus.enable();
  }

  @override
  Future<void> pause() async {
    await _engine.stop();
    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.play],
      playing: false,
      processingState: AudioProcessingState.ready,
    ));
    await WakelockPlus.disable();
  }

  @override
  Future<void> stop() async {
    await _engine.stop();
    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.play],
      playing: false,
      processingState: AudioProcessingState.idle,
    ));
    await WakelockPlus.disable();
  }

  Future<void> startMetronome(MetronomeState state) async {
    await _engine.start(state);
    playbackState.add(playbackState.value.copyWith(
      controls: [MediaControl.pause, MediaControl.stop],
      playing: true,
      processingState: AudioProcessingState.ready,
    ));
    await WakelockPlus.enable();
  }

  Future<void> stopMetronome() async {
    await stop();
  }

  void updateConfig(MetronomeState state) {
    _engine.updateConfig(state);
  }

  Future<void> disposeAudio() async {
    await _engine.stop();
    await _audioPool.dispose();
  }
}
