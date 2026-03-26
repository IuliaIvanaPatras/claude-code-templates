---
paths:
  - "lib/**/providers/**/*.dart"
  - "lib/**/notifiers/**/*.dart"
  - "lib/**/controllers/**/*.dart"
  - "lib/**/*_provider.dart"
  - "lib/**/*_notifier.dart"
---

# State Management Rules

- Use `@riverpod` annotation for all providers — no manual `Provider()`, `StateProvider()`, etc.
- Use `AsyncNotifier` for async state with CRUD operations — not raw `FutureProvider` with manual refresh
- `ref.watch()` in `build()` methods only — use `ref.listen()` for side effects (navigation, snackbars)
- `ref.read()` in callbacks and event handlers only — never in `build()`
- Scope providers to the narrowest possible subtree — avoid global state for local UI state
- Return `AsyncValue<T>` from async providers — handle `loading`, `data`, `error` states exhaustively
- Keep providers pure and testable — inject dependencies via `ref.watch(otherProvider)`
- Use `keepAlive: true` only for providers that must survive across navigation (auth, settings)
- Providers must not directly import Flutter widgets — keep business logic platform-independent
