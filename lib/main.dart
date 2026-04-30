import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'services/metronome_audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final audioHandler = await AudioService.init<MetronomeAudioHandler>(
    builder: () => MetronomeAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.metronome.app.audio',
      androidNotificationChannelName: '节拍器',
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidShowNotificationBadge: true,
      androidStopForegroundOnPause: false,
    ),
  );

  await audioHandler.initAudio();

  runApp(MetronomeApp(audioHandler: audioHandler));
}
