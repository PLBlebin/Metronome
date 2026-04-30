# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run the app
flutter test             # Run all tests
flutter test test/widget_test.dart  # Run a single test file
flutter analyze          # Lint/static analysis
flutter format lib/      # Format code
flutter build apk        # Build Android APK
flutter build ios        # Build iOS app
```

## Architecture

This is a minimal Flutter starter app. The entire app lives in `lib/main.dart`:

- `MyApp` — root widget, sets up `MaterialApp` with a deep-purple seed `ColorScheme`
- `MyHomePage` — single `StatefulWidget` screen with a counter
- `_MyHomePageState` — holds counter state via `setState()`

State management is plain `setState()` with no external packages. There is no routing beyond a static `home:` in `MaterialApp`.

Linting uses `flutter_lints` via `analysis_options.yaml` (includes `package:flutter_lints/flutter.yaml` ruleset).
