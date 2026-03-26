---
paths:
  - "test/**/*.dart"
  - "integration_test/**/*.dart"
  - "test/**/golden/**/*.dart"
---

# Testing Rules

- Use `flutter_test` for unit and widget tests, `integration_test` for E2E, `mocktail` for mocking
- Widget tests must `pumpWidget` with `MaterialApp` wrapper — never test widgets without theme context
- Use `find.byType`, `find.text`, `find.byKey` — prefer semantic finders (`find.bySemanticsLabel`) for a11y
- Use `mocktail` (not `mockito`) — no code generation needed, cleaner API, null-safe by default
- Golden tests for visual regression — update baselines intentionally with `--update-goldens`
- Test Riverpod providers with `ProviderContainer` or `ProviderScope(overrides: [...])`
- Each test must be independent — use `setUp` / `tearDown`, no shared mutable state
- Assertions must be meaningful — test behavior and outcomes, not just `expect(widget, isNotNull)`
- Test both happy path AND error paths — verify error UI renders correctly for `AsyncValue.error`
- Use `pumpAndSettle()` for animations, `pump(duration)` for specific frame advances
