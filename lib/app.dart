import 'package:flutter/material.dart';
import 'notifiers/metronome_notifier.dart';
import 'notifiers/tuner_notifier.dart';
import 'services/metronome_audio_handler.dart';
import 'services/pitch_detector.dart';
import 'services/tuner_audio_service.dart';
import 'ui/screens/metronome_screen.dart';
import 'ui/screens/tuner_screen.dart';

class MetronomeApp extends StatefulWidget {
  final MetronomeAudioHandler audioHandler;

  const MetronomeApp({super.key, required this.audioHandler});

  @override
  State<MetronomeApp> createState() => _MetronomeAppState();
}

class _MetronomeAppState extends State<MetronomeApp> {
  late final MetronomeNotifier _metronomeNotifier;
  late final TunerNotifier _tunerNotifier;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _metronomeNotifier = MetronomeNotifier(widget.audioHandler);
    _tunerNotifier = TunerNotifier(PitchDetector(), TunerAudioService());
    _tunerNotifier.state; // trigger init
  }

  @override
  void dispose() {
    _metronomeNotifier.dispose();
    _tunerNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '节拍器',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            MetronomeScreen(notifier: _metronomeNotifier),
            TunerScreen(notifier: _tunerNotifier),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.speed),
              selectedIcon: Icon(Icons.speed),
              label: '节拍器',
            ),
            NavigationDestination(
              icon: Icon(Icons.music_note),
              selectedIcon: Icon(Icons.music_note),
              label: '调音器',
            ),
          ],
        ),
      ),
    );
  }
}