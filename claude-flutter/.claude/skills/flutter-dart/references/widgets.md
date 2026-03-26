# Widget Composition Reference

## StatelessWidget vs StatefulWidget Decision

Choose **StatelessWidget** when:
- The widget depends only on its constructor parameters and inherited data (`Theme`, `MediaQuery`).
- All state comes from Riverpod providers (use `ConsumerWidget`).

Choose **StatefulWidget** when:
- You need `AnimationController`, `TextEditingController`, `FocusNode`, `ScrollController`, or `TabController`.
- You need `initState` / `dispose` lifecycle hooks.
- You need `TickerProviderStateMixin` for animations.

For Riverpod consumers that also need local mutable state, use `ConsumerStatefulWidget`:

```dart
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer(duration: const Duration(milliseconds: 400));

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider(_searchController.text));
    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) => _debouncer.run(() => setState(() {})),
          decoration: const InputDecoration(
            hintText: 'Search...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        Expanded(
          child: results.when(
            data: (items) => ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) => ListTile(title: Text(items[index].name)),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}
```

## Const Constructors

Always declare `const` constructors and use `const` when instantiating widgets with compile-time-known arguments. This enables Flutter to skip rebuilds for unchanged subtrees.

```dart
// GOOD: const constructor
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.flutter_dash, size: size);
  }
}

// GOOD: const instantiation
const AppLogo(size: 64)

// BAD: non-const when it could be const
AppLogo(size: 64) // Lint warning from very_good_analysis
```

## Keys

Use `Key` when Flutter needs to distinguish sibling widgets of the same type:

```dart
// Required: items in a list that can reorder, add, or remove
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => TodoTile(
    key: ValueKey(items[index].id), // Stable unique key
    todo: items[index],
  ),
)

// Required: switching between widgets of the same type
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  child: isLoading
      ? const CircularProgressIndicator(key: ValueKey('loading'))
      : const Icon(Icons.check, key: ValueKey('done')),
)

// GlobalKey: when you need to access State from outside
final formKey = GlobalKey<FormState>();
Form(key: formKey, child: ...)
formKey.currentState?.validate();
```

## Layout Widgets

### Column / Row

```dart
// Use MainAxisSize.min when the column should shrink-wrap its children
Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('Title', style: theme.textTheme.headlineMedium),
    const SizedBox(height: 8),
    Text('Subtitle', style: theme.textTheme.bodyMedium),
  ],
)

// Use Expanded/Flexible inside Row to distribute space
Row(
  children: [
    Expanded(flex: 2, child: TextField()),
    const SizedBox(width: 12),
    Expanded(flex: 1, child: DropdownButton(...)),
  ],
)
```

### Stack and Positioned

```dart
Stack(
  children: [
    // Base layer: fills stack
    Positioned.fill(
      child: Image.network(url, fit: BoxFit.cover),
    ),
    // Overlay: gradient scrim
    Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 120,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black54],
          ),
        ),
      ),
    ),
    // Overlay: text content
    Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Text(title, style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
    ),
  ],
)
```

### CustomScrollView with Slivers

```dart
CustomScrollView(
  slivers: [
    SliverAppBar.large(
      title: const Text('Products'),
      floating: true,
      pinned: true,
    ),
    // Horizontal carousel inside scroll view
    SliverToBoxAdapter(
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) => CategoryCard(category: categories[index]),
        ),
      ),
    ),
    const SliverToBoxAdapter(child: SizedBox(height: 16)),
    // Grid of products
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) => ProductCard(product: products[index]),
      ),
    ),
    // Infinite scroll loading indicator
    SliverToBoxAdapter(
      child: hasMore
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          : const SizedBox.shrink(),
    ),
  ],
)
```

## Responsive Layouts

### LayoutBuilder

```dart
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return _WideLayout(child: child);
        } else if (constraints.maxWidth >= 600) {
          return _MediumLayout(child: child);
        }
        return _NarrowLayout(child: child);
      },
    );
  }
}
```

### MediaQuery (prefer sizeOf for performance)

```dart
// GOOD: Only subscribes to size changes, not all MediaQuery changes
final screenWidth = MediaQuery.sizeOf(context).width;
final padding = MediaQuery.paddingOf(context);

// BAD: Subscribes to ALL MediaQuery changes (keyboard, brightness, etc.)
final screenWidth = MediaQuery.of(context).size.width;
```

### Adaptive Widgets (Platform-Aware)

```dart
import 'dart:io' show Platform;

class AdaptiveSwitch extends StatelessWidget {
  const AdaptiveSwitch({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS || Platform.isMacOS) {
      return CupertinoSwitch(value: value, onChanged: onChanged);
    }
    return Switch(value: value, onChanged: onChanged);
  }
}
```

## CustomPainter

```dart
class WaveformPainter extends CustomPainter {
  WaveformPainter({required this.samples, required this.color, required this.progress});

  final List<double> samples;
  final Color color;
  final double progress; // 0.0 to 1.0

  @override
  void paint(Canvas canvas, Size size) {
    final activePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final inactivePaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / samples.length;
    final midY = size.height / 2;

    for (var i = 0; i < samples.length; i++) {
      final x = i * barWidth + barWidth / 2;
      final barHeight = samples[i] * size.height * 0.8;
      final paint = (i / samples.length) <= progress ? activePaint : inactivePaint;

      canvas.drawLine(
        Offset(x, midY - barHeight / 2),
        Offset(x, midY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.samples != samples;
  }
}

// Usage in a widget
class Waveform extends StatelessWidget {
  const Waveform({super.key, required this.samples, required this.progress});
  final List<double> samples;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WaveformPainter(
        samples: samples,
        color: Theme.of(context).colorScheme.primary,
        progress: progress,
      ),
      size: const Size(double.infinity, 64),
    );
  }
}
```

## Anti-Patterns to Avoid

### 1. Deep Nesting
```dart
// BAD: Deeply nested build method
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      child: Column(
        children: [
          Container(
            child: Row(
              children: [
                Container(child: Column(children: [/* ... */])),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// GOOD: Extract sub-widgets
@override
Widget build(BuildContext context) {
  return Scaffold(body: Column(children: [_buildHeader(), _buildContent()]));
}

Widget _buildHeader() => /* ... */;
Widget _buildContent() => /* ... */;

// BETTER: Extract as separate widget class for independent rebuilds
```

### 2. Unnecessary Container
```dart
// BAD: Container used only for padding
Container(padding: const EdgeInsets.all(16), child: Text('Hello'))

// GOOD: Use Padding directly
Padding(padding: const EdgeInsets.all(16), child: Text('Hello'))
```

### 3. BuildContext Across Async Gap
```dart
// BAD: Using context after await
Future<void> _submit() async {
  await ref.read(authProvider.notifier).login(email, password);
  Navigator.of(context).pushReplacementNamed('/home'); // context may be stale
}

// GOOD: Check mounted or use GoRouter via ref
Future<void> _submit() async {
  await ref.read(authProvider.notifier).login(email, password);
  if (!mounted) return;
  context.go('/home');
}
```

### 4. Stateful Logic in Widgets
```dart
// BAD: Business logic mixed into widget
class OrderPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Don't compute derived state inline
    final orders = ref.watch(ordersProvider).value ?? [];
    final total = orders.fold(0.0, (sum, o) => sum + o.price); // Move to provider
    // ...
  }
}

// GOOD: Computed value in a provider
@riverpod
double orderTotal(Ref ref) {
  final orders = ref.watch(ordersProvider).valueOrNull ?? [];
  return orders.fold(0.0, (sum, o) => sum + o.price);
}
```
