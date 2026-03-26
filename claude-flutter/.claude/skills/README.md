# Skills

Skills are reusable prompts that teach Claude specific patterns for Flutter development with Dart 3.11, Riverpod 3.x, GoRouter 17.x, and Material 3.

## Available Skills

| Skill | Argument Hint | Description |
|-------|---------------|-------------|
| [flutter-dart](flutter-dart/) | — | Flutter 3.41 + Dart 3.11 — widgets, Riverpod, GoRouter, Freezed, theming |
| [code-quality](code-quality/) | `[file-or-directory]` | Dart/Flutter code review — clean code, type safety, widget patterns |
| [design-patterns](design-patterns/) | `[pattern-name]` | Flutter patterns — Composition, Repository, MVVM, Strategy, Factory |
| [performance-patterns](performance-patterns/) | `[screen-or-widget]` | Widget rebuilds, Impeller, app size, startup, frame rate, DevTools |
| [accessibility-patterns](accessibility-patterns/) | `[widget-or-screen]` | Semantics, TalkBack, VoiceOver, contrast, touch targets, screen readers |

## Reference Files (flutter-dart)

| Reference | Topic |
|-----------|-------|
| [architecture.md](flutter-dart/references/architecture.md) | Feature-first Clean Architecture, MVVM, folder structure, dependency rules |
| [state-management.md](flutter-dart/references/state-management.md) | Riverpod 3.x providers, AsyncNotifier, code-gen, scoping, testing |
| [navigation.md](flutter-dart/references/navigation.md) | GoRouter 17.x, deep linking, guards, shell routes, web support |
| [networking.md](flutter-dart/references/networking.md) | Dio 5.x, interceptors, Freezed models, error handling, retry |
| [testing.md](flutter-dart/references/testing.md) | flutter_test, mocktail, golden tests, integration_test, CI |

## Tech Stack

| Technology | Version |
|-----------|---------|
| Flutter | 3.41 |
| Dart | 3.11 |
| Riverpod | 3.x |
| GoRouter | 17.x |
| Dio | 5.x |
| Freezed | 3.x |
| Drift | 2.x |
| Material | 3 (M3) |
| very_good_analysis | 10.x |
| flutter_test | built-in |
| mocktail | latest |
| integration_test | built-in |
| Sentry | 9.x |
| Fastlane | latest |
