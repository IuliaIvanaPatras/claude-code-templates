# State Management Reference — Riverpod 3.x

## Provider Types with @riverpod Annotation

All providers should be created with the `@riverpod` annotation and code generation. Never use hand-written `Provider()`, `StateProvider()`, etc.

### Simple Provider (Computed / Sync)

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

// Auto-dispose, synchronous
@riverpod
String greeting(Ref ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user != null ? 'Hello, ${user.name}!' : 'Hello, Guest!';
}
```

### Future Provider (Async Computed)

```dart
@riverpod
Future<List<Product>> featuredProducts(Ref ref) async {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getFeatured();
}
```

### Stream Provider

```dart
@riverpod
Stream<int> unreadCount(Ref ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.watchUnreadCount();
}
```

### Notifier (Sync Mutable State)

```dart
@riverpod
class Counter extends _$Counter {
  @override
  int build() => 0;

  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
}
```

### AsyncNotifier (Async Mutable State)

```dart
@riverpod
class CartItems extends _$CartItems {
  @override
  Future<List<CartItem>> build() async {
    final repo = ref.watch(cartRepositoryProvider);
    return repo.getItems();
  }

  Future<void> add(String productId, {int quantity = 1}) async {
    final repo = ref.read(cartRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repo.addItem(productId, quantity: quantity);
      return repo.getItems();
    });
  }

  Future<void> remove(String itemId) async {
    final repo = ref.read(cartRepositoryProvider);
    // Optimistic removal
    final previous = state;
    state = AsyncData(
      state.requireValue.where((item) => item.id != itemId).toList(),
    );
    try {
      await repo.removeItem(itemId);
    } catch (e, st) {
      state = previous;
      state = AsyncError(e, st);
    }
  }
}
```

### Keep-Alive Provider

```dart
// Persists across the app lifetime (not auto-disposed)
@Riverpod(keepAlive: true)
Future<AppConfig> appConfig(Ref ref) async {
  final response = await ref.watch(apiClientProvider).get('/config');
  return AppConfig.fromJson(response.data);
}
```

## Family Providers (Parameterized)

```dart
// Simple parameter
@riverpod
Future<Product> productById(Ref ref, String id) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getById(id);
}

// Multiple parameters: use a record
@riverpod
Future<PaginatedResponse<Product>> productSearch(
  Ref ref,
  ({String query, int page, String? category}) params,
) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.search(
    query: params.query,
    page: params.page,
    category: params.category,
  );
}

// Usage in widget
final product = ref.watch(productByIdProvider('abc-123'));
final results = ref.watch(productSearchProvider((query: 'shoes', page: 1, category: null)));
```

## ref.watch / ref.read / ref.listen

### ref.watch — Reactive Subscription (in build)

```dart
class ProductPage extends ConsumerWidget {
  const ProductPage({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuilds when product data changes
    final productAsync = ref.watch(productByIdProvider(productId));

    return productAsync.when(
      data: (product) => ProductView(product: product),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorView(
        message: (error as AppException).userMessage,
        onRetry: () => ref.invalidate(productByIdProvider(productId)),
      ),
    );
  }
}
```

### ref.read — One-Time Read (in callbacks)

```dart
ElevatedButton(
  onPressed: () {
    // One-time read inside a callback — never use ref.watch here
    ref.read(cartItemsProvider.notifier).add(productId);
  },
  child: const Text('Add to Cart'),
)
```

### ref.listen — Side Effects on State Changes

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  ref.listen(authStateProvider, (previous, next) {
    if (next.valueOrNull?.isAuthenticated == false) {
      context.go('/auth/login');
    }
  });

  ref.listen(cartItemsProvider, (previous, next) {
    next.whenOrNull(
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((error as AppException).userMessage)),
        );
      },
    );
  });

  // ... rest of build
}
```

## Selecting (select)

Minimize rebuilds by subscribing to only a specific piece of state:

```dart
// Only rebuilds when the item count changes, not when items themselves change
final itemCount = ref.watch(
  cartItemsProvider.select((state) => state.valueOrNull?.length ?? 0),
);

// Only rebuilds when user's name changes
final userName = ref.watch(
  currentUserProvider.select((state) => state.valueOrNull?.name),
);
```

## Combining Providers

```dart
@riverpod
Future<DashboardData> dashboard(Ref ref) async {
  // All three load in parallel
  final results = await Future.wait([
    ref.watch(recentOrdersProvider.future),
    ref.watch(accountBalanceProvider.future),
    ref.watch(notificationCountProvider.future),
  ]);

  return DashboardData(
    recentOrders: results[0] as List<Order>,
    balance: results[1] as double,
    notificationCount: results[2] as int,
  );
}
```

## Provider Scoping / Overrides

```dart
// Override for a subtree (e.g., per-item scope in a list)
@riverpod
Todo currentTodo(Ref ref) => throw UnimplementedError();

// In the parent widget
ListView.builder(
  itemCount: todos.length,
  itemBuilder: (context, index) => ProviderScope(
    overrides: [currentTodoProvider.overrideWithValue(todos[index])],
    child: const TodoTile(),
  ),
)

// TodoTile reads without needing the index
class TodoTile extends ConsumerWidget {
  const TodoTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todo = ref.watch(currentTodoProvider);
    return ListTile(title: Text(todo.title));
  }
}
```

## Error Handling with AsyncValue

```dart
// Pattern: exhaustive switch on AsyncValue
@override
Widget build(BuildContext context, WidgetRef ref) {
  final ordersAsync = ref.watch(ordersProvider);

  return switch (ordersAsync) {
    AsyncData(:final value) => OrderList(orders: value),
    AsyncError(:final error) => ErrorView(
      message: (error as AppException).userMessage,
      onRetry: () => ref.invalidate(ordersProvider),
    ),
    _ => const Center(child: CircularProgressIndicator()),
  };
}

// Pattern: when() with named parameters
ordersAsync.when(
  data: (orders) => OrderList(orders: orders),
  loading: () => const ShimmerList(),
  error: (error, stack) => ErrorView(message: '$error'),
  // Skip loading on refresh (show stale data with loading indicator)
  skipLoadingOnRefresh: true,
);
```

## Testing Providers

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockProductRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockProductRepository();
    container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);
  });

  test('featuredProducts returns list from repository', () async {
    final products = [Product(id: '1', name: 'Shoe', price: 99.99)];
    when(() => mockRepo.getFeatured()).thenAnswer((_) async => products);

    final result = await container.read(featuredProductsProvider.future);

    expect(result, equals(products));
    verify(() => mockRepo.getFeatured()).called(1);
  });

  test('cartItems notifier adds item and refreshes', () async {
    when(() => mockRepo.getItems()).thenAnswer((_) async => []);
    when(() => mockRepo.addItem('p1', quantity: 1)).thenAnswer((_) async {});
    when(() => mockRepo.getItems()).thenAnswer((_) async => [
      CartItem(id: 'c1', productId: 'p1', quantity: 1),
    ]);

    // Wait for initial build
    await container.read(cartItemsProvider.future);

    // Trigger add
    await container.read(cartItemsProvider.notifier).add('p1');

    final items = await container.read(cartItemsProvider.future);
    expect(items, hasLength(1));
    expect(items.first.productId, 'p1');
  });
}
```

## AutoDispose and KeepAlive

By default, `@riverpod` providers are **auto-disposed** when no longer listened to. Use `@Riverpod(keepAlive: true)` for providers that should persist (auth tokens, app config, singletons).

Manual keep-alive with a timer (useful for caching):

```dart
@riverpod
Future<UserProfile> userProfile(Ref ref) async {
  // Keep the data alive for 5 minutes after last listener
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(timer.cancel);

  final repo = ref.watch(userRepositoryProvider);
  return repo.getProfile();
}
```

## Invalidation and Refresh

```dart
// Invalidate: marks as stale, rebuilds lazily on next read
ref.invalidate(productsProvider);

// Refresh: invalidates AND immediately rebuilds, returns new value
final fresh = await ref.refresh(productsProvider.future);

// Invalidate a family member
ref.invalidate(productByIdProvider('abc-123'));
```

## Migration from Provider / Bloc

| Old Pattern | Riverpod 3 Equivalent |
|---|---|
| `ChangeNotifierProvider` | `@riverpod class Foo extends _$Foo` (Notifier) |
| `StateNotifierProvider` | `@riverpod class Foo extends _$Foo` (Notifier) |
| `FutureProvider` | `@riverpod Future<T> foo(Ref ref)` |
| `StreamProvider` | `@riverpod Stream<T> foo(Ref ref)` |
| `Provider` | `@riverpod T foo(Ref ref)` |
| `StateProvider` | `@riverpod class Foo extends _$Foo { int build() => 0; }` |
| `Bloc/Cubit` | `@riverpod class Foo extends _$Foo` (AsyncNotifier for async) |
| `context.read<T>()` | `ref.read(fooProvider)` |
| `context.watch<T>()` | `ref.watch(fooProvider)` |
| `BlocListener` | `ref.listen(fooProvider, ...)` |
| `MultiBlocProvider` | `ProviderScope` at app root (automatic) |
