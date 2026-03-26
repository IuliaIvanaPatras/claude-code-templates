---
paths:
  - "lib/**/widgets/**/*.dart"
  - "lib/**/pages/**/*.dart"
  - "lib/**/screens/**/*.dart"
  - "lib/**/presentation/**/*.dart"
---

# Widget Rules

- Prefer `StatelessWidget` by default — use `StatefulWidget` only when managing local animation controllers or `TextEditingController`
- Use `const` constructors on every widget and child that allows it — prevents unnecessary rebuilds
- All images must have `semanticLabel` — or `excludeFromSemantics: true` for decorative images
- All interactive widgets must have `Semantics` with `label`, `hint`, or `button` role
- Use `Key` parameters on list items and conditionally rendered widgets — never on static layouts
- Prefer composition (small widgets) over monolithic `build()` methods — split at ~50 lines
- Use `RepaintBoundary` around expensive subtrees (animations, canvases, complex lists)
- Touch targets must be at least 48x48 logical pixels (Material guideline)
- No `dynamic` types in widget parameters — strongly type all props
- Extract widget parameters into dedicated classes when a widget has 5+ parameters
