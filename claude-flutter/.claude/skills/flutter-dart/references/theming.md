# Theming Reference — Material 3

## ColorScheme.fromSeed

Material 3 generates a full palette from a single seed color using the HCT color space:

```dart
// Light scheme
final lightScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF6750A4), // Brand purple
  brightness: Brightness.light,
);

// Dark scheme (same seed, dark variant)
final darkScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF6750A4),
  brightness: Brightness.dark,
);

// Override specific roles after generation
final customLight = ColorScheme.fromSeed(
  seedColor: const Color(0xFF6750A4),
  brightness: Brightness.light,
).copyWith(
  error: const Color(0xFFBA1A1A),
  tertiary: const Color(0xFF7D5260),
);
```

### Key ColorScheme Roles

| Role | Usage |
|---|---|
| `primary` | FABs, prominent buttons, active states |
| `onPrimary` | Text/icons on primary surfaces |
| `primaryContainer` | Less prominent fills (chips, toggles) |
| `secondary` | Less prominent components |
| `surface` | Page/card backgrounds |
| `surfaceContainerLow/High` | Elevated surface variants |
| `error` | Error states, destructive actions |
| `onSurface` | Body text, icons |
| `onSurfaceVariant` | Secondary text, placeholder text |
| `outline` | Borders, dividers |
| `outlineVariant` | Subtle borders |

## Complete ThemeData Configuration

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const _seedColor = Color(0xFF6750A4);

  static ThemeData light() => _buildTheme(Brightness.light);
  static ThemeData dark() => _buildTheme(Brightness.dark);

  static ThemeData fromDynamic({
    required ColorScheme? dynamicLight,
    required ColorScheme? dynamicDark,
    required Brightness brightness,
  }) {
    final scheme = brightness == Brightness.light
        ? (dynamicLight ?? ColorScheme.fromSeed(seedColor: _seedColor))
        : (dynamicDark ?? ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark));
    return _buildThemeFromScheme(scheme);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );
    return _buildThemeFromScheme(scheme);
  }

  static ThemeData _buildThemeFromScheme(ColorScheme scheme) {
    final textTheme = _buildTextTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,

      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Filled Button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),

      // Bottom Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(color: scheme.onSurface),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.secondaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: textTheme.labelLarge,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: textTheme.headlineSmall?.copyWith(color: scheme.onSurface),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Divider
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),

      // Extensions
      extensions: [
        AppSpacing.standard,
        AppDurations.standard,
      ],
    );
  }

  static TextTheme _buildTextTheme(ColorScheme scheme) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(color: scheme.onSurface),
      displayMedium: base.displayMedium?.copyWith(color: scheme.onSurface),
      displaySmall: base.displaySmall?.copyWith(color: scheme.onSurface),
      headlineLarge: base.headlineLarge?.copyWith(color: scheme.onSurface),
      headlineMedium: base.headlineMedium?.copyWith(color: scheme.onSurface),
      headlineSmall: base.headlineSmall?.copyWith(color: scheme.onSurface),
      titleLarge: base.titleLarge?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w500),
      titleSmall: base.titleSmall?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w500),
      bodyLarge: base.bodyLarge?.copyWith(color: scheme.onSurface),
      bodyMedium: base.bodyMedium?.copyWith(color: scheme.onSurface),
      bodySmall: base.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      labelLarge: base.labelLarge?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
      labelSmall: base.labelSmall?.copyWith(color: scheme.onSurfaceVariant, letterSpacing: 0.5),
    );
  }
}
```

## Dark Mode Toggle with Riverpod

```dart
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_mode_provider.g.dart';

@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    _loadFromPrefs();
    return ThemeMode.system;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      state = ThemeMode.values.firstWhere(
        (mode) => mode.name == value,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  void toggleDarkMode() {
    setThemeMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

// Usage in settings page
class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeNotifierProvider);
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.auto_mode), label: Text('System')),
        ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Light')),
        ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Dark')),
      ],
      selected: {mode},
      onSelectionChanged: (selected) {
        ref.read(themeModeNotifierProvider.notifier).setThemeMode(selected.first);
      },
    );
  }
}
```

## DynamicColorBuilder Integration

```dart
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeNotifierProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp.router(
          theme: AppTheme.fromDynamic(
            dynamicLight: lightDynamic,
            dynamicDark: null,
            brightness: Brightness.light,
          ),
          darkTheme: AppTheme.fromDynamic(
            dynamicLight: null,
            dynamicDark: darkDynamic,
            brightness: Brightness.dark,
          ),
          themeMode: themeMode,
          routerConfig: router,
        );
      },
    );
  }
}
```

## Custom ThemeExtension

Use `ThemeExtension` for app-specific design tokens that do not map to standard Material roles:

```dart
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  static const standard = AppSpacing(xs: 4, sm: 8, md: 16, lg: 24, xl: 32);

  @override
  AppSpacing copyWith({double? xs, double? sm, double? md, double? lg, double? xl}) {
    return AppSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
    );
  }

  @override
  AppSpacing lerp(covariant AppSpacing? other, double t) {
    if (other == null) return this;
    return AppSpacing(
      xs: lerpDouble(xs, other.xs, t)!,
      sm: lerpDouble(sm, other.sm, t)!,
      md: lerpDouble(md, other.md, t)!,
      lg: lerpDouble(lg, other.lg, t)!,
      xl: lerpDouble(xl, other.xl, t)!,
    );
  }
}

class AppDurations extends ThemeExtension<AppDurations> {
  const AppDurations({required this.short, required this.medium, required this.long});

  final Duration short;
  final Duration medium;
  final Duration long;

  static const standard = AppDurations(
    short: Duration(milliseconds: 150),
    medium: Duration(milliseconds: 300),
    long: Duration(milliseconds: 500),
  );

  @override
  AppDurations copyWith({Duration? short, Duration? medium, Duration? long}) {
    return AppDurations(
      short: short ?? this.short,
      medium: medium ?? this.medium,
      long: long ?? this.long,
    );
  }

  @override
  AppDurations lerp(covariant AppDurations? other, double t) => other ?? this;
}

// Convenient access extension
extension ThemeExtensionX on ThemeData {
  AppSpacing get spacing => extension<AppSpacing>()!;
  AppDurations get durations => extension<AppDurations>()!;
}

// Usage
Padding(
  padding: EdgeInsets.all(Theme.of(context).spacing.md),
  child: AnimatedContainer(
    duration: Theme.of(context).durations.medium,
    // ...
  ),
)
```

## Responsive Font Scaling

```dart
// Scale typography for larger screens / accessibility settings
class ResponsiveTextTheme {
  static TextTheme scale(TextTheme base, BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final scaleFactor = mediaQuery.textScaler;
    final screenWidth = mediaQuery.size.width;

    // Slightly reduce text size on very small screens
    final widthFactor = screenWidth < 360 ? 0.9 : 1.0;

    return base.apply(
      fontSizeFactor: widthFactor,
    );
  }
}
```

## Accessibility — Contrast Ratios

Material 3 ensures WCAG AA contrast by default. To verify custom colors:

```dart
// Check contrast ratio programmatically
double contrastRatio(Color foreground, Color background) {
  final fgLuminance = foreground.computeLuminance();
  final bgLuminance = background.computeLuminance();
  final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
  final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

// Usage: WCAG AA requires >= 4.5:1 for normal text, >= 3:1 for large text
assert(contrastRatio(scheme.onPrimary, scheme.primary) >= 4.5);
```

Rules:
- Always use `colorScheme.onX` for text/icons on `colorScheme.X` surfaces.
- Never hardcode colors; always pull from `Theme.of(context).colorScheme`.
- Test with `MediaQuery.boldTextOf(context)` and large font scaling (2x).
- Use `Semantics` widgets and meaningful `tooltip` values for screen readers.
