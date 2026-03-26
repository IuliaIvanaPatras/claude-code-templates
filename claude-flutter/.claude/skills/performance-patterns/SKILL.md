---
name: performance-patterns
description: "Flutter performance — widget rebuilds, Impeller, app size, startup time, frame rate, DevTools. Use when user mentions performance, slow UI, jank, large APK, startup time, or \"optimize\"."
argument-hint: "[screen-or-widget]"
---

# Performance Patterns Skill

Best practices for Flutter performance with Impeller rendering, Riverpod 3.x, and DevTools profiling.

## When to Use
- User mentions "slow screen" / "jank" / "frame drops" / "optimize"
- Large APK/IPA size or slow startup
- Widget rebuild overhead or animation stuttering
- Questions about profiling, DevTools, or performance budgets

---

## Quick Reference: Common Problems

| Problem | Symptom | Solution |
|---------|---------|----------|
| Excessive rebuilds | Slow UI, high CPU in profile | `const`, `select()`, split widgets |
| Jank during scroll | Dropped frames, stuttering | `ListView.builder`, `itemExtent`, `RepaintBoundary` |
| Large images | Memory pressure, OOM crashes | `cached_network_image`, resize, `precacheImage` |
| Large APK size | >30 MB download, slow install | `--split-per-abi`, deferred imports, tree shaking |
| Slow startup | 3+ seconds cold start | Lazy init, deferred loading, reduce main() work |
| Animation jank | <60 FPS during transitions | Impeller, `RepaintBoundary`, simplify painters |
| Heavy computation | Frozen UI during processing | `Isolate.run()`, `compute()` |
| Memory leaks | Growing memory, eventual crash | Dispose controllers, cancel subscriptions |

---

## Widget Rebuild Optimization

### Const Constructors

```dart
// ❌ Rebuilds every frame — new instance each time
@override
Widget build(BuildContext context) {
  return Padding(
    padding: EdgeInsets.all(16),  // new EdgeInsets each build
    child: Column(
      children: [
        Text('Title'),            // new Text each build
        Divider(),                // new Divider each build
        _buildContent(),
      ],
    ),
  );
}

// ✅ Const — skipped by framework diffing
@override
Widget build(BuildContext context) {
  return const Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Title'),
        Divider(),
      ],
    ),
  );
}
```

### Split Widgets to Minimize Rebuild Scope

```dart
// ❌ Entire screen rebuilds when counter changes
class CounterScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),  // Rebuilds!
      body: Center(child: Text('$count')),
      floatingActionButton: FloatingActionButton(     // Rebuilds!
        onPressed: () => ref.read(counterProvider.notifier).increment(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ✅ Only the Text widget rebuilds
class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: const Center(child: _CounterDisplay()),
      floatingActionButton: const _IncrementButton(),
    );
  }
}

class _CounterDisplay extends ConsumerWidget {
  const _CounterDisplay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('$count', style: Theme.of(context).textTheme.headlineLarge);
  }
}

class _IncrementButton extends ConsumerWidget {
  const _IncrementButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => ref.read(counterProvider.notifier).increment(),
      child: const Icon(Icons.add),
    );
  }
}
```

### Riverpod select() — Surgical Rebuilds

```dart
// ❌ Rebuilds on ANY user field change
final user = ref.watch(userProvider);
return Text(user.name);

// ✅ Only rebuilds when name changes
final name = ref.watch(userProvider.select((u) => u.name));
return Text(name);

// ✅ Multiple fields — returns record
final (:name, :avatarUrl) = ref.watch(
  userProvider.select((u) => (name: u.name, avatarUrl: u.avatarUrl)),
);
return Row(
  children: [
    CircleAvatar(backgroundImage: NetworkImage(avatarUrl)),
    Text(name),
  ],
);
```

### shouldRebuild with ConsumerStatefulWidget

```dart
/// Custom shouldRebuild logic for list items
class ProductTile extends ConsumerStatefulWidget {
  const ProductTile({required this.productId, super.key});
  final String productId;

  @override
  ConsumerState<ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends ConsumerState<ProductTile> {
  @override
  Widget build(BuildContext context) {
    // Only watch specific fields to minimize rebuilds
    final name = ref.watch(
      productProvider(widget.productId).select((p) => p.valueOrNull?.name),
    );
    final price = ref.watch(
      productProvider(widget.productId).select((p) => p.valueOrNull?.price),
    );

    return ListTile(
      title: Text(name ?? ''),
      trailing: Text('\$${price?.toStringAsFixed(2) ?? ''}'),
    );
  }
}
```

---

## List Optimization

### ListView.builder (Lazy Construction)

```dart
// ❌ All 10,000 items built at once
ListView(
  children: items.map((item) => ItemTile(item: item)).toList(),
)

// ✅ Only visible items built — O(visible) not O(n)
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemTile(
    key: ValueKey(items[index].id),
    item: items[index],
  ),
)
```

### itemExtent for Fixed-Height Items

```dart
// ❌ Framework must measure each child to compute scroll offset
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => SizedBox(
    height: 72,
    child: ItemTile(item: items[index]),
  ),
)

// ✅ itemExtent — framework skips measurement, O(1) scroll calculation
ListView.builder(
  itemCount: items.length,
  itemExtent: 72, // Fixed height — much faster scrolling
  itemBuilder: (context, index) => ItemTile(item: items[index]),
)
```

### SliverList for Mixed Content

```dart
// ✅ CustomScrollView with mixed slivers — efficient for complex layouts
CustomScrollView(
  slivers: [
    const SliverAppBar(
      title: Text('Products'),
      floating: true,
    ),
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SearchBar(onChanged: onSearchChanged),
      ),
    ),
    SliverList.builder(
      itemCount: products.length,
      itemBuilder: (context, index) => ProductTile(
        key: ValueKey(products[index].id),
        product: products[index],
      ),
    ),
    const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('End of list')),
      ),
    ),
  ],
)
```

---

## Image Optimization

### Cached Network Images

```dart
// ❌ Raw Image.network — no caching, no placeholder
Image.network(product.imageUrl)

// ✅ cached_network_image — disk cache, placeholder, error widget
CachedNetworkImage(
  imageUrl: product.imageUrl,
  width: 200,
  height: 200,
  fit: BoxFit.cover,
  placeholder: (context, url) => const Shimmer(width: 200, height: 200),
  errorWidget: (context, url, error) => const Icon(Icons.broken_image),
  memCacheWidth: 400,  // Resize in memory (2x for high DPI)
  memCacheHeight: 400,
)
```

### Precache Critical Images

```dart
// ✅ Precache images that will be needed immediately
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  precacheImage(
    const AssetImage('assets/images/hero.webp'),
    context,
  );
}

// ✅ In initState with provider
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    for (final url in criticalImageUrls) {
      precacheImage(CachedNetworkImageProvider(url), context);
    }
  });
}
```

### Resize at Load Time

```dart
// ❌ Loading 4000x3000 image for a 200x200 thumbnail
Image.asset('assets/photo.png')

// ✅ Decode at target size — saves memory
Image.asset(
  'assets/photo.png',
  cacheWidth: 400,   // 2x for high DPI devices
  cacheHeight: 400,
)
```

---

## App Size Reduction

### Split Per ABI

```bash
# ❌ Single fat APK with all architectures (~40 MB)
flutter build apk --release

# ✅ Split per ABI — ~15 MB per architecture
flutter build apk --release --split-per-abi

# Output:
# app-arm64-v8a-release.apk   (~15 MB) — modern devices
# app-armeabi-v7a-release.apk (~13 MB) — older devices
# app-x86_64-release.apk      (~16 MB) — emulators only

# ✅ App Bundle — Google Play serves correct ABI automatically
flutter build appbundle --release
```

### Deferred Imports (Lazy Feature Loading)

```dart
// ✅ Deferred import — code loaded only when feature accessed
import 'package:myapp/features/admin/admin_screen.dart' deferred as admin;

GoRoute(
  path: '/admin',
  builder: (context, state) => FutureBuilder(
    future: admin.loadLibrary(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      return admin.AdminScreen();
    },
  ),
)
```

### Tree Shaking Icons

```yaml
# pubspec.yaml — only include used icons
flutter:
  uses-material-design: true
  # Flutter tree-shakes unused icons in release builds automatically
  # But avoid importing entire icon packs unnecessarily
```

```dart
// ❌ Importing an entire icon package
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // +1 MB

// ✅ Use Material icons (tree-shaken) or individual SVGs
Icon(Icons.favorite)
// or
SvgPicture.asset('assets/icons/custom_icon.svg', width: 24, height: 24)
```

---

## Startup Optimization

### Lazy Initialization

```dart
// ❌ Initialize everything in main() — slow cold start
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();         // 200ms
  await Hive.initFlutter();               // 100ms
  await dotenv.load();                    // 50ms
  await SentryFlutter.init((options) {}); // 150ms
  // ... 500ms before first frame

  runApp(const MyApp());
}

// ✅ Defer non-critical init — fast first frame
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only critical-path initialization
  await Firebase.initializeApp();

  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );
}

// Non-critical init via Riverpod — happens after first frame
@Riverpod(keepAlive: true)
Future<void> appInit(Ref ref) async {
  await Future.wait([
    SentryFlutter.init((options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
    }),
    ref.read(localDatabaseProvider.future),
    ref.read(analyticsProvider.future),
  ]);
}
```

### Reduce Main Isolate Work

```dart
// ✅ Heavy JSON parsing on a background isolate
@riverpod
Future<List<Product>> productCatalog(Ref ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get<String>('/api/v1/products/catalog');

  // Parse large JSON on background isolate
  return Isolate.run(() {
    final list = jsonDecode(response.data!) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  });
}
```

---

## Animation Performance

### Impeller (Default in Flutter 3.41)

```dart
// Impeller is enabled by default on iOS and Android
// Verify in DevTools > Performance > Rendering engine: Impeller

// ✅ Tips for Impeller-optimized animations:
// 1. Avoid saveLayer() — expensive on GPU
// 2. Use simple clip shapes (RRect over Path)
// 3. Prefer opacity widgets over color alpha
```

### TickerProvider for Smooth Animations

```dart
class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this, // TickerProvider — syncs with refresh rate
    );
    _scaleAnimation = Tween(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Always dispose — prevents memory leak
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
```

### Lottie — Rasterize for Performance

```dart
// ❌ Lottie with complex shapes — GPU overhead
Lottie.asset('assets/animations/complex.json')

// ✅ Set renderCache for repeated animations
Lottie.asset(
  'assets/animations/loading.json',
  renderCache: RenderCache.raster, // Cache as raster image
  width: 120,
  height: 120,
  frameRate: FrameRate.max,
)
```

---

## Isolates for CPU-Intensive Work

```dart
// ❌ Heavy computation on main isolate — UI freezes
void processData() {
  final result = expensiveComputation(largeDataSet); // 500ms blocking
  setState(() => _result = result);
}

// ✅ Isolate.run — one-shot background computation
Future<void> processData() async {
  final result = await Isolate.run(() {
    return expensiveComputation(largeDataSet);
  });
  setState(() => _result = result);
}

// ✅ Long-running isolate with ports for streaming results
Future<void> processStream() async {
  final receivePort = ReceivePort();

  await Isolate.spawn((SendPort sendPort) {
    for (var i = 0; i < 1000; i++) {
      final chunk = processChunk(i);
      sendPort.send(chunk);
    }
    sendPort.send(null); // Signal completion
  }, receivePort.sendPort);

  await for (final chunk in receivePort) {
    if (chunk == null) break;
    setState(() => _chunks.add(chunk as ProcessedChunk));
  }
}
```

---

## DevTools Profiling

### Performance Overlay

```dart
// Enable in debug builds
MaterialApp(
  showPerformanceOverlay: true, // Shows GPU + UI thread bars
)

// Or toggle via DevTools > Performance > Performance Overlay
```

### Widget Rebuild Tracking

```dart
// In DevTools > Flutter Inspector > Track widget rebuilds
// Shows rebuild counts per widget — find excessive rebuilders

// Programmatic tracking in debug mode
@override
Widget build(BuildContext context) {
  debugPrint('ProductList build #${++_buildCount}');
  // If _buildCount grows rapidly, this widget rebuilds too often
}
```

### Profile Mode Build

```bash
# Always profile in profile mode — debug mode is misleading
flutter run --profile

# Record a timeline for analysis
flutter run --profile --trace-startup --trace-to-file=trace.json
```

---

## Performance Budget in CI

```yaml
# .github/workflows/performance.yml
name: Performance Budget
on: pull_request

jobs:
  apk-size:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.5'

      - name: Build release APK
        run: flutter build apk --release --split-per-abi

      - name: Check APK size budget
        run: |
          SIZE=$(stat -f%z build/app/outputs/flutter-apk/app-arm64-v8a-release.apk 2>/dev/null || stat -c%s build/app/outputs/flutter-apk/app-arm64-v8a-release.apk)
          MAX_SIZE=$((20 * 1024 * 1024))  # 20 MB budget
          if [ "$SIZE" -gt "$MAX_SIZE" ]; then
            echo "APK size ${SIZE} exceeds budget ${MAX_SIZE}"
            exit 1
          fi
          echo "APK size: ${SIZE} bytes (budget: ${MAX_SIZE} bytes)"

  startup-time:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.5'

      - name: Measure startup time
        run: |
          flutter build apk --profile
          flutter run --profile --trace-startup \
            --trace-to-file=startup_trace.json
          # Parse trace for timeToFirstFrame metric
```

---

## Quick Checklist

| Category | Check |
|----------|-------|
| **Rebuilds** | `const` constructors, `select()` for Riverpod, split widgets |
| **Lists** | `ListView.builder`, `itemExtent` for fixed height, `ValueKey` |
| **Images** | `CachedNetworkImage`, `cacheWidth`/`cacheHeight`, precache critical |
| **App Size** | `--split-per-abi`, deferred imports, tree-shaken icons |
| **Startup** | Lazy init via providers, minimal `main()`, deferred features |
| **Animation** | Impeller verified, `dispose()` controllers, `RepaintBoundary` |
| **CPU** | `Isolate.run()` for >16ms work, streaming for large datasets |
| **Profiling** | Profile mode (not debug), DevTools timeline, rebuild tracking |
| **CI** | APK size budget, startup time check, frame rate smoke test |
