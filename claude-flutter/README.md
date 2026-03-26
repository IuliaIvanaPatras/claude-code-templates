# Claude Code Template for Flutter Applications

This template provides a structured starting point for production-grade Flutter applications, optimized for Claude AI's code generation capabilities. It includes specialized agents, best practices skills, path-specific rules, automated hooks, and security controls to streamline development.

Clone this repository and use it to generate the app you want with Claude Code.

## Tech Stack

- **Framework**: Flutter 3.41 (Impeller rendering, 6 platform targets)
- **Language**: Dart 3.11 (sound null safety, pattern matching, sealed classes, records)
- **State**: Riverpod 3.x + riverpod_generator (code-gen providers)
- **Navigation**: GoRouter 17.x (declarative, deep linking, web)
- **Networking**: Dio 5.x (interceptors, cancellation, file upload)
- **Serialization**: Freezed 3.x + json_serializable (immutable models, unions)
- **Local DB**: Drift 2.x (SQL, compile-time safe, migrations)
- **Linting**: very_good_analysis 10.x (86% of all lint rules)
- **Testing**: flutter_test + mocktail + integration_test + golden tests
- **Theming**: Material 3 + dynamic_color (ColorScheme.fromSeed)
- **Error Tracking**: sentry_flutter 9.x
- **CI/CD**: GitHub Actions + Fastlane
- **Deployment**: Play Store / App Store / Firebase Hosting / Cloudflare Pages

## Project Structure

```shell
.
├── .claude/
│   ├── agents/                        # 7 specialized AI agents
│   │   ├── code-reviewer.md
│   │   ├── devops-engineer.md
│   │   ├── flutter-engineer.md
│   │   ├── performance-engineer.md
│   │   ├── security-engineer.md
│   │   ├── testing-engineer.md
│   │   └── ui-ux-engineer.md
│   ├── hooks/                         # Automated lifecycle hooks
│   │   ├── auto-analyze.sh            # Auto-analyze with dart analyze after file changes
│   │   ├── block-dangerous.sh         # Block destructive Bash commands
│   │   ├── session-context.sh         # Inject Flutter/Dart version, project context
│   │   └── stop-verification.sh       # Verify dart analyze passes before stopping
│   ├── rules/                         # Path-specific rules
│   │   ├── security.md                # Rules for auth, network, secure storage
│   │   ├── state-management.md        # Rules for providers, notifiers
│   │   ├── testing.md                 # Rules for test/**
│   │   ├── theming.md                 # Rules for theme, Material 3
│   │   └── widgets.md                 # Rules for widgets, pages, screens
│   ├── settings.json                  # Shared settings: permissions, hooks
│   ├── settings.local.json            # Local overrides (gitignored)
│   └── skills/                        # 5 reusable skills
│       ├── README.md
│       ├── accessibility-patterns/
│       │   └── SKILL.md
│       ├── code-quality/
│       │   └── SKILL.md
│       ├── design-patterns/
│       │   └── SKILL.md
│       ├── flutter-dart/
│       │   ├── SKILL.md
│       │   └── references/
│       │       ├── data-layer.md
│       │       ├── state-management.md
│       │       ├── testing.md
│       │       ├── theming.md
│       │       └── widgets.md
│       └── performance-patterns/
│           └── SKILL.md
├── .claude-plugin/
│   └── plugin.json                    # Plugin metadata
├── CLAUDE.md                          # Development guidelines
└── README.md
```

## Agents

| Agent | Model | Mode | Isolation | Expertise |
|-------|-------|------|-----------|-----------|
| **flutter-engineer** | sonnet | default | worktree | Flutter 3.41, Dart 3.11, Riverpod, GoRouter, Dio, Freezed |
| **code-reviewer** | opus | plan (read-only) | — | Type safety, widget patterns, Riverpod, a11y, performance |
| **ui-ux-engineer** | sonnet | default | worktree | Material 3, responsive layouts, animations, dark mode |
| **security-engineer** | opus | plan (read-only) | — | Secure storage, SSL pinning, obfuscation, OWASP Mobile |
| **performance-engineer** | sonnet | plan (read-only) | — | Impeller, widget rebuilds, DevTools, app size, frame rate |
| **testing-engineer** | opus | default | worktree | flutter_test, mocktail, golden tests, integration tests |
| **devops-engineer** | sonnet | default | worktree | GitHub Actions, Fastlane, app signing, Play/App Store |

**Advanced features**: All agents include `maxTurns` limits, preloaded `skills`, persistent `memory`, scoped `hooks`, and `isolation: worktree` for code-writing agents (isolated git worktree to prevent conflicts).

## Skills

| Skill | Argument Hint | Description |
|-------|---------------|-------------|
| **flutter-dart** | — | Flutter 3.41, Dart 3.11, Riverpod, GoRouter, Dio, Freezed, Material 3 |
| **code-quality** | `[file-or-directory]` | Dart/Flutter code review, clean code, type safety, accessibility |
| **design-patterns** | `[pattern-name]` | Composition, Repository, MVVM, Strategy, Sealed unions |
| **performance-patterns** | `[screen-or-widget]` | Widget rebuilds, Impeller, app size, startup, DevTools |
| **accessibility-patterns** | `[widget-or-screen]` | Semantics, TalkBack, VoiceOver, contrast, touch targets |

## Hooks (Automated)

| Hook | Event | Action |
|------|-------|--------|
| **auto-analyze** | `PostToolUse` (Write/Edit) | Runs `dart format` + `dart analyze` on changed Dart files |
| **block-dangerous** | `PreToolUse` (Bash) | Blocks `rm -rf`, force-push, pub publish, keystore ops |
| **session-context** | `SessionStart` | Injects Flutter/Dart version, project info, device count, config warnings |
| **stop-verification** | `Stop` / `SubagentStop` | Verifies Dart analysis passes before Claude stops working |

## Rules (Path-Specific)

| Rule | Applies To | Key Constraints |
|------|-----------|-----------------|
| **widgets** | `widgets/**`, `pages/**`, `presentation/**` | Composition, const, Semantics, 48x48 touch targets |
| **state-management** | `providers/**`, `*_provider.dart` | `@riverpod` annotation, watch/read/listen rules, scoping |
| **testing** | `test/**`, `integration_test/**` | mocktail, pumpWidget with MaterialApp, golden tests |
| **theming** | `theme/**`, `app.dart` | Material 3, ColorScheme.fromSeed, dark mode, WCAG contrast |
| **security** | `security/**`, `auth/**`, `network/**` | flutter_secure_storage, envied, SSL pinning, obfuscation |

## Getting Started

```bash
# Clone and setup
git clone <this-repo> my-app
cd my-app

# Initialize Flutter project (agent will generate pubspec.yaml)
# Or create with: flutter create --org com.example my_app

# Get dependencies
flutter pub get

# Run code generation
dart run build_runner build --delete-conflicting-outputs

# Development
flutter run

# Testing
flutter test
flutter test --coverage

# Analysis
flutter analyze
dart format .

# Build
flutter build apk --release
flutter build ios --release
flutter build web --release
```
