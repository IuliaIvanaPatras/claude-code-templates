---
name: code-quality
description: "Dart/Flutter code review — clean code, widget patterns, type safety, accessibility, performance. Use when user says \"review code\", \"refactor\", \"check this PR\", or before merging changes."
argument-hint: "[file-or-directory]"
---

# Code Quality Review Skill

Systematic Flutter/Dart code review combining clean code principles, widget patterns, Dart type safety, Riverpod conventions, accessibility, and performance best practices.

## When to Use
- "review this code" / "code review" / "check this PR"
- "refactor" / "clean this code" / "improve readability"
- "review widget" / "check patterns"
- Before merging PR or releasing a Flutter feature

## Review Strategy

1. **Quick scan** - Understand intent, identify scope (feature, widget, provider)
2. **Checklist pass** - Apply relevant categories below
3. **Summary** - List findings by severity (Critical > Important > Smell > Good)

---

## Clean Code in Dart

### DRY - Don't Repeat Yourself (Use Extensions)

**Violation:**
```dart
// ❌ Duplicated formatting logic across widgets
class OrderSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final formatted = '\$${(price / 100).toStringAsFixed(2)}';
    return Text(formatted);
  }
}

class CartItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final formatted = '\$${(price / 100).toStringAsFixed(2)}';
    return Text(formatted);
  }
}
```

**Fix:**
```dart
// ✅ Shared extension on int (cents to dollars)
extension CurrencyFormatting on int {
  String toCurrency({String symbol = '\$'}) {
    return '$symbol${(this / 100).toStringAsFixed(2)}';
  }
}

// Usage — clean and consistent
Text(order.totalCents.toCurrency());
Text(item.priceCents.toCurrency(symbol: '€'));
```

### KISS - Keep It Simple

**Violation:**
```dart
// ❌ Over-engineered generic factory for a single use case
class WidgetFactory<T extends Widget> {
  final T Function(BuildContext, Map<String, dynamic>) _builder;
  const WidgetFactory(this._builder);
  T build(BuildContext context, Map<String, dynamic> params) =>
      _builder(context, params);
}
```

**Fix:**
```dart
// ✅ Simple widget, extract later if pattern repeats
class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, super.key});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Card(child: Text(product.name));
  }
}
```

### YAGNI - You Aren't Gonna Need It

**Violation:**
```dart
// ❌ Abstract base class for one implementation
abstract class BaseRepository<T> {
  Future<List<T>> getAll();
  Future<T?> getById(String id);
  Future<void> create(T item);
  Future<void> update(T item);
  Future<void> delete(String id);
  Future<List<T>> search(String query); // Never used
  Future<void> batchUpdate(List<T> items); // Never used
}
```

**Fix:**
```dart
// ✅ Only methods you actually need today
abstract class UserRepository {
  Future<List<User>> getAll();
  Future<User?> getById(String id);
  Future<void> create(User user);
}
```

---

## Dart Type Safety

### Null Safety — Avoid the Bang Operator

```dart
// ❌ Null assertion — crashes at runtime
final user = ref.read(userProvider).value!;
final name = jsonMap['name']! as String;

// ✅ Pattern matching with null check
if (ref.read(userProvider).value case final user?) {
  showProfile(user);
}

// ✅ Safe access with fallback
final name = jsonMap['name'] as String? ?? 'Unknown';
```

### Pattern Matching (Dart 3.11)

```dart
// ❌ Cascading if-else with type checks
Widget buildState(AsyncValue<User> state) {
  if (state is AsyncLoading) return const CircularProgressIndicator();
  if (state is AsyncError) return Text('Error: ${state.error}');
  if (state is AsyncData) return UserProfile(user: state.value);
  return const SizedBox.shrink();
}

// ✅ Switch expression with pattern matching
Widget buildState(AsyncValue<User> state) => switch (state) {
  AsyncLoading()            => const CircularProgressIndicator(),
  AsyncError(:final error)  => ErrorDisplay(error: error),
  AsyncData(:final value)   => UserProfile(user: value),
};
```

### Sealed Classes for Exhaustive States

```dart
// ✅ Sealed class — compiler enforces all cases handled
sealed class PaymentResult {
  const PaymentResult();
}

final class PaymentSuccess extends PaymentResult {
  const PaymentSuccess({required this.transactionId});
  final String transactionId;
}

final class PaymentFailure extends PaymentResult {
  const PaymentFailure({required this.reason});
  final String reason;
}

final class PaymentCancelled extends PaymentResult {
  const PaymentCancelled();
}

// Exhaustive switch — compile error if case missing
String describeResult(PaymentResult result) => switch (result) {
  PaymentSuccess(:final transactionId) => 'Paid: $transactionId',
  PaymentFailure(:final reason)        => 'Failed: $reason',
  PaymentCancelled()                   => 'Cancelled by user',
};
```

### Avoid `dynamic`

```dart
// ❌ Dynamic defeats the type system
dynamic fetchData() async {
  final response = await dio.get('/users');
  return response.data; // dynamic — no compile-time checks
}

// ✅ Typed with Freezed model
Future<List<User>> fetchUsers() async {
  final response = await dio.get<List<dynamic>>('/users');
  return response.data!
      .cast<Map<String, dynamic>>()
      .map(User.fromJson)
      .toList();
}
```

**Flags:**
- `dynamic` type anywhere in business logic
- `!` null assertion without preceding null check or justification
- `as` cast without `is` guard
- Non-exhaustive switch on sealed class or enum
- Missing return type on public functions

---

## Flutter Widget Patterns

### Composition Over Inheritance

```dart
// ❌ Inheriting from StatelessWidget subclass
class BaseCard extends StatelessWidget { /* shared layout */ }
class ProductCard extends BaseCard { /* override build */ } // Fragile

// ✅ Composition with slot pattern
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.header,
    this.footer,
    this.onTap,
    super.key,
  });

  final Widget child;
  final Widget? header;
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (header != null) header!,
            Padding(padding: const EdgeInsets.all(16), child: child),
            if (footer != null) footer!,
          ],
        ),
      ),
    );
  }
}
```

### Const Constructors

```dart
// ❌ Missing const — rebuilds every frame
return Padding(
  padding: EdgeInsets.all(16), // not const
  child: Text('Hello'),       // not const
);

// ✅ Const everything possible
return const Padding(
  padding: EdgeInsets.all(16),
  child: Text('Hello'),
);
```

### Keys — When to Use

```dart
// ❌ Missing key in dynamic list — state corruption
ListView.builder(
  itemBuilder: (context, index) => UserTile(user: users[index]),
);

// ✅ ValueKey for items that can reorder
ListView.builder(
  itemBuilder: (context, index) => UserTile(
    key: ValueKey(users[index].id),
    user: users[index],
  ),
);

// ✅ UniqueKey to force widget recreation
AnimatedSwitcher(
  child: Text(counter.toString(), key: ValueKey(counter)),
);
```

### Proper setState Scope

```dart
// ❌ Entire widget rebuilds for one field
class _ProfileScreenState extends State<ProfileScreen> {
  String name = '';
  String bio = '';
  String avatarUrl = '';
  bool isEditing = false;
  // ... 10 more fields — setState rebuilds everything
}

// ✅ Extract stateful parts into focused child widgets
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ProfileHeader(),     // Separate stateful widget
        const ProfileBioEditor(),  // Only rebuilds when bio changes
        const ProfileAvatar(),     // Only rebuilds when avatar changes
      ],
    );
  }
}
```

---

## Riverpod Patterns

### watch vs read

```dart
// ❌ Using read inside build — won't rebuild on changes
@override
Widget build(BuildContext context, WidgetRef ref) {
  final user = ref.read(userProvider); // Misses updates!
  return Text(user.name);
}

// ✅ watch inside build — rebuilds when state changes
@override
Widget build(BuildContext context, WidgetRef ref) {
  final user = ref.watch(userProvider);
  return Text(user.name);
}

// ✅ read inside callbacks — one-time action
ElevatedButton(
  onPressed: () => ref.read(cartProvider.notifier).addItem(product),
  child: const Text('Add to Cart'),
)
```

### Provider Scoping with select

```dart
// ❌ Widget rebuilds on ANY user field change
final user = ref.watch(userProvider);
return Text(user.name); // Rebuilds when email, avatar, etc. change

// ✅ select — only rebuild when name changes
final name = ref.watch(userProvider.select((u) => u.name));
return Text(name);
```

### AsyncNotifier Pattern

```dart
// ✅ Clean ViewModel as AsyncNotifier
@riverpod
class ProductList extends _$ProductList {
  @override
  Future<List<Product>> build() async {
    final repository = ref.watch(productRepositoryProvider);
    return repository.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(productRepositoryProvider).getAll(),
    );
  }

  Future<void> delete(String id) async {
    await ref.read(productRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}
```

---

## Accessibility Checks

```dart
// ❌ Icon button without semantic label
IconButton(
  onPressed: () => Navigator.pop(context),
  icon: const Icon(Icons.arrow_back),
);

// ✅ Semantic label for screen readers
IconButton(
  onPressed: () => Navigator.pop(context),
  tooltip: 'Go back',
  icon: Semantics(
    label: 'Go back',
    child: const Icon(Icons.arrow_back),
  ),
);

// ❌ Image without semantics
Image.network(user.avatarUrl);

// ✅ Image with semantic label
Image.network(
  user.avatarUrl,
  semanticLabel: '${user.name} profile photo',
);

// ❌ Low contrast text
Text('Subtitle', style: TextStyle(color: Colors.grey[300])); // Fails 4.5:1

// ✅ Use theme colors that meet contrast ratio
Text('Subtitle', style: Theme.of(context).textTheme.bodyMedium);
```

---

## Performance Checks

```dart
// ❌ Creating new objects in build — defeats diffing
@override
Widget build(BuildContext context) {
  return Container(
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
    // New BoxDecoration every build
  );
}

// ✅ Const or static decoration
static const _decoration = BoxDecoration(
  borderRadius: BorderRadius.all(Radius.circular(8)),
);

@override
Widget build(BuildContext context) {
  return Container(decoration: _decoration);
}

// ❌ Column of 1000 items — all built at once
Column(children: items.map((i) => ItemTile(item: i)).toList())

// ✅ ListView.builder — only visible items built
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemTile(
    key: ValueKey(items[index].id),
    item: items[index],
  ),
)

// ❌ Expensive computation in build
@override
Widget build(BuildContext context) {
  final sorted = List.of(items)..sort((a, b) => a.name.compareTo(b.name));
  return ListView(children: sorted.map(ItemTile.new).toList());
}

// ✅ RepaintBoundary for isolated repaints
RepaintBoundary(
  child: CustomPaint(painter: ChartPainter(data)),
)
```

---

## Review Output Format

```markdown
## Code Review: [Feature/Widget Name]

### Critical Issues
- **Type Safety** (user_service.dart:42) — `dynamic` return type on public method. Use `Future<User>`.
- **Accessibility** (settings_screen.dart:88) — IconButton missing `tooltip`. Add semantic label.

### Important Improvements
- **Riverpod** (home_screen.dart:15) — `ref.read` inside `build()`. Change to `ref.watch`.
- **Performance** (product_list.dart:30) — `Column` with 500 children. Use `ListView.builder`.
- **Null Safety** (api_client.dart:67) — Bang operator `!` without null guard. Use pattern matching.

### Code Smells
- **DRY** — Currency formatting duplicated in 3 files. Extract to extension.
- **YAGNI** — `BaseRepository<T>` has 4 unused methods. Remove until needed.

### Good Practices Observed
- Const constructors used throughout
- Freezed models for all DTOs
- Provider scoping with select()
- Semantic labels on interactive widgets
```

---

## Quick Reference Flags

| Category | Red Flags |
|----------|-----------|
| **Type Safety** | `dynamic`, `!` without guard, `as` without `is`, non-exhaustive switch |
| **Widgets** | Missing `const`, inheritance over composition, no keys in lists |
| **Riverpod** | `ref.read` in `build()`, missing `select()`, manual `Provider()` |
| **Accessibility** | Missing `Semantics`/`tooltip`, touch target < 48px, color-only errors |
| **Performance** | `Column` for large lists, new objects in `build()`, missing `RepaintBoundary` |
| **Null Safety** | Unguarded `!`, missing null checks on JSON, `late` without justification |
| **State** | `setState` rebuilding entire tree, business logic in widgets |

## Severity Levels

- **Critical** - Crash risk, accessibility barrier, security issue > Must fix before merge
- **Important** - Performance, type safety, correctness > Should fix
- **Code Smell** - Style, complexity, minor issues > Nice to have
- **Good** - Positive feedback to reinforce good practices
