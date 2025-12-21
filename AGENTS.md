# Repository Guidelines
## Always make a plan before doing a change and the user should accepet on it .
- Always make a plan before doing a change and the user should accepet on it

## Project Structure & Module Organization
- `lib/main.dart` is the app entrypoint; feature code lives in `lib/src/` (`config/`, `models/`, `screens/`, `services/`, `state/`, `utils/`, `widgets/`).
- State is managed with Provider and ChangeNotifier in `lib/src/state`, and API access goes through `lib/src/services`.
- `assets/` holds fonts and images; assets are declared in `pubspec.yaml` (for example: `assets/fonts/`, `lib/ama ordersystem logo.png`).
- Tests live in `test/` and follow the `*_test.dart` pattern.
- Platform targets are in `android/`, `ios/`, `web/`, `macos/`, `windows/`, and `linux/`.
- `AMA-Order-System/` contains related backend/frontend resources and setup/security docs.

## Build, Test, and Development Commands
- `flutter pub get` fetch dependencies.
- `flutter run` launch the app on a connected device or simulator.
- `flutter run -d chrome` run the web build in Chrome.
- `flutter test` run all tests in `test/`.
- `flutter analyze` run static analysis with project lints.
- `dart format .` auto-format Dart code.
- `flutter build apk` (or `flutter build ios` / `flutter build web`) create release builds.

## Coding Style & Naming Conventions
- Indentation is 2 spaces; keep lines short and let `dart format .` handle layout.
- Linting follows `analysis_options.yaml` via `flutter_lints`.
- Naming: files use `lower_snake_case.dart`, types use `UpperCamelCase`, and members use `lowerCamelCase`.

## Testing Guidelines
- Tests use `flutter_test`; prefer `testWidgets` for UI behavior.
- Name tests `*_test.dart` and keep them in `test/` (example: `test/order_form_focus_test.dart`).
- No explicit coverage target; add tests for new screens, state changes, and API flows.

## Commit & Pull Request Guidelines
- Recent commits are short, lowercase phrases (for example: "fix fonts"); keep messages concise and descriptive.
- PRs should include a clear summary, testing notes, and screenshots for UI changes; link related issues when applicable.

## Security & Configuration Tips
- Review `AMA-Order-System/SECURITY_README.md` and `AMA-Order-System/INTERNET_SETUP.md` before deploying or exposing services.
- Avoid committing secrets; use platform-specific config files for environment setup.
