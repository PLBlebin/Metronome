import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:record/record.dart';

class PitchResult {
  final double frequency;
  final double confidence;
  final double rms;

  const PitchResult({
    required this.frequency,
    required this.confidence,
    required this.rms,
  });
}

class PitchDetector {
  final AudioRecorder _recorder = AudioRecorder();

  static const double kThreshold = 0.15;
  static const int kSampleRate = 44100;
  static const int kBufferSize = 2048;
  static const double kMinFreq = 60.0;
  static const double kMaxFreq = 1500.0;

  StreamController<PitchResult>? _pitchController;
  StreamSubscription<Uint8List>? _audioSubscription;

  Stream<PitchResult> get pitchStream {
    _pitchController ??= StreamController<PitchResult>.broadcast();
    return _pitchController!.stream;
  }

  Future<bool> requestPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> start() async {
    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: kSampleRate,
      numChannels: 1,
    ));

    _audioSubscription = stream.listen(_processAudioBuffer, onError: (e) {
      _pitchController?.addError(e);
    });
  }

  Future<void> stop() async {
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    await _recorder.stop();
  }

  void _processAudioBuffer(Uint8List buffer) {
    final samples = _pcm16ToDouble(buffer);
    if (samples.isEmpty) return;

    final rms = _calculateRms(samples);
    if (rms < 0.01) {
      _pitchController?.add(PitchResult(frequency: 0, confidence: 0, rms: rms));
      return;
    }

    final result = _yinPitchDetection(samples);
    _pitchController?.add(PitchResult(
      frequency: result.frequency,
      confidence: result.confidence,
      rms: rms,
    ));
  }

  _YinResult _yinPitchDetection(List<double> samples) {
    final halfBuffer = kBufferSize ~/ 2;
    final yinBuffer = List<double>.filled(halfBuffer, 0.0);

    // Step 1: Difference function
    for (int tau = 0; tau < halfBuffer; tau++) {
      double sum = 0.0;
      for (int i = 0; i < halfBuffer; i++) {
        final delta = samples[i] - samples[i + tau];
        sum += delta * delta;
      }
      yinBuffer[tau] = sum;
    }

    // Step 2: Cumulative mean normalized difference
    yinBuffer[0] = 1.0;
    double runningSum = 0.0;
    for (int tau = 1; tau < halfBuffer; tau++) {
      runningSum += yinBuffer[tau];
      yinBuffer[tau] = yinBuffer[tau] * tau / runningSum;
    }

    // Step 3: Find first trough below threshold
    int tauEstimate = -1;
    for (int tau = 2; tau < halfBuffer; tau++) {
      if (yinBuffer[tau] < kThreshold) {
        while (tau + 1 < halfBuffer && yinBuffer[tau + 1] < yinBuffer[tau]) {
          tau++;
        }
        tauEstimate = tau;
        break;
      }
    }

    // Step 4: Fallback to minimum
    if (tauEstimate == -1) {
      double minVal = yinBuffer[2];
      for (int tau = 3; tau < halfBuffer; tau++) {
        if (yinBuffer[tau] < minVal) {
          minVal = yinBuffer[tau];
          tauEstimate = tau;
        }
      }
    }

    // Step 5: Parabolic interpolation
    double frequency = 0.0;
    double confidence = 0.0;
    if (tauEstimate > 0 && tauEstimate < halfBuffer - 1) {
      final s0 = yinBuffer[tauEstimate - 1];
      final s1 = yinBuffer[tauEstimate];
      final s2 = yinBuffer[tauEstimate + 1];
      final adjustment = (s2 - s0) / (2.0 * (2.0 * s1 - s2 - s0));
      final betterTau = tauEstimate + adjustment;
      frequency = kSampleRate / betterTau;
      confidence = 1.0 - yinBuffer[tauEstimate];
    }

    if (frequency < kMinFreq || frequency > kMaxFreq) {
      frequency = 0.0;
      confidence = 0.0;
    }

    return _YinResult(frequency: frequency, confidence: confidence);
  }

  List<double> _pcm16ToDouble(Uint8List buffer) {
    final samples = <double>[];
    for (int i = 0; i + 1 < buffer.length; i += 2) {
      int pcm = buffer[i] | (buffer[i + 1] << 8);
      if (pcm >= 32768) pcm -= 65536;
      samples.add(pcm / 32768.0);
    }
    return samples;
  }

  double _calculateRms(List<double> samples) {
    double sum = 0.0;
    for (final s in samples) { sum += s * s; }
    return sqrt(sum / samples.length);
  }

  Future<void> dispose() async {
    await stop();
    await _pitchController?.close();
    _pitchController = null;
    _recorder.dispose();
  }
}

class _YinResult {
  final double frequency;
  final double confidence;
  const _YinResult({required this.frequency, required this.confidence});
}