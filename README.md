# metronome

A Flutter metronome and tuner app.

## Features

### Metronome
- BPM control (40-240)
- Tap tempo
- Time signatures (2/4, 3/4, 4/4, 5/4, 6/8, 7/8)
- Subdivisions (quarter, eighth, triplet, sixteenth)
- Multiple sound options (click, woodblock, beep)
- Preset save/load
- Practice mode with warm-up phases

### Tuner
- Real-time pitch detection
- Reference tone generation (A4 = 440Hz adjustable)
- String-based quick tuning

## Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run the app
flutter test             # Run all tests
flutter analyze          # Lint/static analysis
flutter format lib/      # Format code
flutter build apk        # Build Android APK
flutter build ios        # Build iOS app
```

## Architecture

- `lib/main.dart` — entry point with audio service initialization
- `lib/app.dart` — root widget with MaterialApp
- `lib/models/` — data models (enums, state, preset, note)
- `lib/notifiers/` — state management (metronome, tuner)
- `lib/services/` — audio handling, preset storage, audio pool
- `lib/ui/screens/` — main screens (metronome, tuner)
- `lib/ui/widgets/` — reusable UI components
- `lib/core/` — constants and music theory values

State management uses `ChangeNotifier` pattern.
Audio uses `audio_service` package for background playback.