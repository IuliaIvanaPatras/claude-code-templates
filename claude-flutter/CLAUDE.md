## Operational Guidelines

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Review lessons at session start for a project

### 3. Verification Before Done
- IMPORTANT: Never mark a task complete without proving it works
- Run `flutter analyze` and verify zero issues before claiming done
- Ask yourself: "Would a staff engineer approve this?"

### 4. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- Skip this for simple, obvious fixes. Don't overengineer

## Core Principles
- **Simplicity First**: Make every change as simple as possible. Impact minimal code
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards
- **Type Safety**: Leverage Dart's sound null safety — no `dynamic`, no `!` without justification

## Build Commands
- **Run**: `flutter run` (debug mode on connected device)
- **Build APK**: `flutter build apk --release`
- **Build iOS**: `flutter build ios --release`
- **Build Web**: `flutter build web --release`
- **Test**: `flutter test`
- **Test coverage**: `flutter test --coverage`
- **Analyze**: `flutter analyze`
- **Format**: `dart format .`
- **Code gen**: `dart run build_runner build --delete-conflicting-outputs`
- **Code gen watch**: `dart run build_runner watch --delete-conflicting-outputs`
- **Clean**: `flutter clean && flutter pub get`

## Tech Stack
- **Framework**: Flutter 3.41 (Impeller rendering, all 6 platforms)
- **Language**: Dart 3.11 (sound null safety, pattern matching, sealed classes, records)
- **State**: Riverpod 3.x + riverpod_generator (code-gen providers)
- **Navigation**: GoRouter 17.x (declarative, deep linking, web support)
- **Networking**: Dio 5.x (interceptors, cancellation, file upload)
- **Serialization**: Freezed 3.x + json_serializable (immutable models, unions)
- **Local DB**: Drift 2.x (SQL, compile-time safe, migrations)
- **Secure Storage**: flutter_secure_storage 10.x (AES-256, Keychain/Keystore)
- **Linting**: very_good_analysis 10.x (86% of all lint rules)
- **Testing**: flutter_test + mocktail + integration_test + golden tests
- **Theming**: Material 3 + dynamic_color (ColorScheme.fromSeed)
- **Error Tracking**: sentry_flutter 9.x
- **CI/CD**: GitHub Actions + Fastlane
- **DI**: Riverpod (built-in) or get_it + injectable

## Project Rules

- Always use the latest stable versions of dependencies
- Always write Dart — feature-first package structure
- Use `flutter pub get` after modifying `pubspec.yaml`
- Create test cases for all generated code — positive and negative scenarios
- Generate GitHub Actions CI in `.github/workflows/`
- Minimize code — prefer composition over inheritance
- Use semantic versioning — bump PATCH for each new version
- YOU MUST use feature-first folder structure (`features/auth/`, `features/home/`)
- IMPORTANT: Use Freezed for all data models — no hand-written `==`, `hashCode`, `copyWith`
- Riverpod providers via `@riverpod` annotation — no manual `Provider()` constructors
- All API responses validated with Freezed models — never access raw `Map<String, dynamic>`
- Generate `.env.example` documenting all required env vars
- Update README.md with each new version
- IMPORTANT: No `dynamic` types — no `!` null assertions without justification

## Accessibility (non-negotiable)
- All interactive widgets must have `Semantics` labels
- All images must have `semanticLabel` or `excludeFromSemantics: true`
- Touch targets minimum 48x48 logical pixels
- Color contrast must meet WCAG 2.1 AA (4.5:1 text, 3:1 UI)
- Test with TalkBack (Android) and VoiceOver (iOS) every sprint

## Path-specific rules
See `.claude/rules/` for detailed rules scoped to:
- `widgets.md` — widget composition, keys, stateless vs stateful
- `state-management.md` — Riverpod providers, Notifiers, scoping
- `testing.md` — flutter_test/mocktail conventions, golden tests
- `theming.md` — Material 3, ColorScheme, dark mode, responsive
- `security.md` — secure storage, SSL pinning, obfuscation

## Reference
- @README.md
- @pubspec.yaml
