---
paths:
  - "lib/**/theme/**/*.dart"
  - "lib/**/core/theme/**/*.dart"
  - "lib/**/app.dart"
---

# Theming Rules

- Use Material 3 (`useMaterial3: true`) — never Material 2 for new projects
- Generate color scheme via `ColorScheme.fromSeed(seedColor: ...)` — never hardcode individual colors
- Define separate `ThemeData` for light and dark — toggle via `ThemeMode` (system + manual)
- Use `Theme.of(context).colorScheme` to access colors — never hardcode `Colors.blue`
- Use `Theme.of(context).textTheme` for typography — never inline `TextStyle(fontSize: ...)`
- Responsive font sizes via `MediaQuery.textScaler` — never override system text scaling
- Use `DynamicColorBuilder` for wallpaper-based theming on Android 12+ (dynamic_color package)
- Define custom `ThemeExtension<T>` for app-specific tokens (spacing, custom colors, shadows)
- Color contrast must meet WCAG 2.1 AA: 4.5:1 for text, 3:1 for UI elements
- All animations must respect `MediaQuery.disableAnimations` or `AccessibilityFeatures.reduceMotion`
