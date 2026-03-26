---
name: design-patterns
description: "Flutter design patterns — Composition, Repository, MVVM, Strategy, Observer, Singleton, Factory. Use when user asks \"implement pattern\", \"use composition\", or when designing reusable features."
argument-hint: "[pattern-name]"
---

# Flutter Design Patterns Skill

Quick reference for common design patterns in Flutter with Dart 3.11, Riverpod 3.x, and Clean Architecture.

## When to Use
- User asks to implement a specific pattern
- Designing reusable or extensible features
- Refactoring rigid, duplicated, or untestable code

## Quick Reference: When to Use What

| Problem | Pattern | Use When |
|---------|---------|----------|
| Flexible UI with variations | **Widget Composition** | Building reusable component APIs |
| Data layer abstraction | **Repository** | API calls, local DB, caching strategy |
| Screen business logic | **MVVM (AsyncNotifier)** | Feature screens with async data |
| Swappable algorithms | **Strategy** | Payment processing, sorting, auth methods |
| Reactive data streams | **Observer (Streams)** | Real-time updates, WebSocket, SSE |
| Exhaustive state handling | **Sealed Class Union** | Loading/success/error, navigation events |
| Expensive shared resource | **Singleton (Riverpod)** | Dio client, SharedPreferences, analytics |
| Platform-specific widgets | **Factory** | iOS vs Android adaptive UI |

---

## Widget Composition

### Slot Pattern

**Problem:** Build flexible widgets that accept custom content in specific positions.

```dart
/// Reusable list tile with configurable slots
class AppListTile extends StatelessWidget {
  const AppListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    super.key,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 16)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    subtitle!,
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 16), trailing!],
          ],
        ),
      ),
    );
  }
}

// Usage — composable, flexible
AppListTile(
  leading: const CircleAvatar(child: Icon(Icons.person)),
  title: Text(user.name, style: Theme.of(context).textTheme.titleMedium),
  subtitle: Text(user.email),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => context.push('/users/${user.id}'),
)
```

### Builder Pattern

**Problem:** Parent widget provides data, child controls rendering.

```dart
/// Generic async content builder with loading/error/data states
class AsyncContentBuilder<T> extends StatelessWidget {
  const AsyncContentBuilder({
    required this.value,
    required this.builder,
    this.loading,
    this.error,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Widget? loading;
  final Widget Function(Object error, StackTrace stack)? error;

  @override
  Widget build(BuildContext context) => switch (value) {
    AsyncLoading()           => loading ?? const Center(
                                  child: CircularProgressIndicator(),
                                ),
    AsyncError(:final error,
               :final stackTrace) => this.error?.call(error, stackTrace) ??
                                     Center(child: Text('Error: $error')),
    AsyncData(:final value)  => builder(value),
  };
}

// Usage — consistent loading/error pattern across all screens
@override
Widget build(BuildContext context, WidgetRef ref) {
  final products = ref.watch(productListProvider);

  return AsyncContentBuilder(
    value: products,
    loading: const ProductListSkeleton(),
    builder: (data) => ProductGrid(products: data),
    error: (e, _) => RetryButton(onRetry: () => ref.invalidate(productListProvider)),
  );
}
```

---

## Repository Pattern

**Problem:** Abstract data source details from business logic.

### Abstraction

```dart
/// Domain-level contract — no implementation details
abstract class UserRepository {
  Future<List<User>> getAll();
  Future<User> getById(String id);
  Future<User> create(CreateUserRequest request);
  Future<void> delete(String id);
}
```

### Implementation

```dart
/// Concrete implementation with Dio + caching
class RemoteUserRepository implements UserRepository {
  RemoteUserRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;

  @override
  Future<List<User>> getAll() async {
    final response = await _dio.get<List<dynamic>>('/api/v1/users');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(User.fromJson)
        .toList();
  }

  @override
  Future<User> getById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/users/$id');
    return User.fromJson(response.data!);
  }

  @override
  Future<User> create(CreateUserRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/users',
      data: request.toJson(),
    );
    return User.fromJson(response.data!);
  }

  @override
  Future<void> delete(String id) async {
    await _dio.delete<void>('/api/v1/users/$id');
  }
}
```

### Dependency Injection via Riverpod

```dart
/// Provider for the repository — swap implementation in tests
@riverpod
UserRepository userRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  return RemoteUserRepository(dio: dio);
}

// In tests — override with mock
final container = ProviderContainer(
  overrides: [
    userRepositoryProvider.overrideWithValue(MockUserRepository()),
  ],
);
```

---

## MVVM with Riverpod (ViewModel as AsyncNotifier)

**Problem:** Separate screen logic from UI while keeping state reactive.

### ViewModel

```dart
@riverpod
class ProductListViewModel extends _$ProductListViewModel {
  @override
  Future<List<Product>> build() async {
    return _fetchProducts();
  }

  Future<List<Product>> _fetchProducts() {
    final repository = ref.read(productRepositoryProvider);
    return repository.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchProducts);
  }

  Future<void> deleteProduct(String id) async {
    final repository = ref.read(productRepositoryProvider);
    await repository.delete(id);
    ref.invalidateSelf();
    await future; // Wait for rebuild to complete
  }

  Future<void> toggleFavorite(String id) async {
    final repository = ref.read(productRepositoryProvider);
    await repository.toggleFavorite(id);

    // Optimistic update
    state = state.whenData(
      (products) => [
        for (final p in products)
          if (p.id == id) p.copyWith(isFavorite: !p.isFavorite) else p,
      ],
    );
  }
}
```

### View (Screen)

```dart
class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productListViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: switch (state) {
        AsyncLoading()          => const ProductListSkeleton(),
        AsyncError(:final error) => _ErrorView(
                                      error: error,
                                      onRetry: () => ref
                                          .read(productListViewModelProvider.notifier)
                                          .refresh(),
                                    ),
        AsyncData(:final value)  => RefreshIndicator(
                                      onRefresh: () => ref
                                          .read(productListViewModelProvider.notifier)
                                          .refresh(),
                                      child: ListView.builder(
                                        itemCount: value.length,
                                        itemBuilder: (context, index) => ProductTile(
                                          key: ValueKey(value[index].id),
                                          product: value[index],
                                          onDelete: () => ref
                                              .read(productListViewModelProvider.notifier)
                                              .deleteProduct(value[index].id),
                                        ),
                                      ),
                                    ),
      },
    );
  }
}
```

---

## Strategy Pattern

**Problem:** Swap algorithms at runtime without changing calling code.

```dart
/// Strategy interface
abstract class PaymentStrategy {
  Future<PaymentResult> pay(PaymentRequest request);
  String get displayName;
  IconData get icon;
}

/// Concrete strategies
class CreditCardPayment implements PaymentStrategy {
  CreditCardPayment({required Dio dio}) : _dio = dio;
  final Dio _dio;

  @override
  String get displayName => 'Credit Card';

  @override
  IconData get icon => Icons.credit_card;

  @override
  Future<PaymentResult> pay(PaymentRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/payments/card',
      data: request.toJson(),
    );
    return PaymentResult.fromJson(response.data!);
  }
}

class GooglePayPayment implements PaymentStrategy {
  @override
  String get displayName => 'Google Pay';

  @override
  IconData get icon => Icons.account_balance_wallet;

  @override
  Future<PaymentResult> pay(PaymentRequest request) async {
    // Google Pay SDK integration
    final result = await GooglePayClient.requestPayment(
      price: request.amount.toString(),
      currencyCode: request.currency,
    );
    return PaymentResult(transactionId: result.token, status: 'success');
  }
}

/// Context — uses strategy without knowing which one
@riverpod
class CheckoutViewModel extends _$CheckoutViewModel {
  @override
  CheckoutState build() => const CheckoutState();

  void selectPaymentMethod(PaymentStrategy strategy) {
    state = state.copyWith(selectedPayment: strategy);
  }

  Future<void> processPayment(PaymentRequest request) async {
    final strategy = state.selectedPayment;
    if (strategy == null) return;

    state = state.copyWith(isProcessing: true);
    try {
      final result = await strategy.pay(request);
      state = state.copyWith(result: result, isProcessing: false);
    } on DioException catch (e) {
      state = state.copyWith(error: e.message, isProcessing: false);
    }
  }
}
```

---

## Observer with Streams

**Problem:** React to real-time data changes (WebSocket, SSE, Firestore).

```dart
/// Repository exposes a Stream
abstract class ChatRepository {
  Stream<List<Message>> watchMessages(String roomId);
  Future<void> sendMessage(String roomId, String content);
}

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({required FirebaseFirestore db}) : _db = db;
  final FirebaseFirestore _db;

  @override
  Stream<List<Message>> watchMessages(String roomId) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Message.fromJson(d.data())).toList());
  }

  @override
  Future<void> sendMessage(String roomId, String content) async {
    await _db.collection('rooms').doc(roomId).collection('messages').add({
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

/// Riverpod StreamProvider — automatic lifecycle management
@riverpod
Stream<List<Message>> chatMessages(Ref ref, String roomId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchMessages(roomId);
}

// Widget — just watch the stream
final messages = ref.watch(chatMessagesProvider(roomId));
return switch (messages) {
  AsyncData(:final value) => MessageList(messages: value),
  AsyncError(:final error) => Text('Error: $error'),
  _                        => const CircularProgressIndicator(),
};
```

---

## Sealed Class Unions for State

**Problem:** Type-safe, exhaustive state representation.

```dart
/// Freezed union type — compiler enforces all cases
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated({required User user}) = Authenticated;
  const factory AuthState.unauthenticated({String? message}) = Unauthenticated;
}

/// ViewModel using the sealed state
@riverpod
class AuthViewModel extends _$AuthViewModel {
  @override
  AuthState build() => const AuthState.initial();

  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    try {
      final user = await ref.read(authRepositoryProvider).login(email, password);
      state = AuthState.authenticated(user: user);
    } on AuthException catch (e) {
      state = AuthState.unauthenticated(message: e.message);
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthState.unauthenticated();
  }
}

/// Widget — exhaustive pattern matching, no missed states
@override
Widget build(BuildContext context, WidgetRef ref) {
  final authState = ref.watch(authViewModelProvider);

  return switch (authState) {
    AuthInitial()                   => const SplashScreen(),
    AuthLoading()                   => const LoadingOverlay(),
    Authenticated(:final user)      => HomeScreen(user: user),
    Unauthenticated(:final message) => LoginScreen(errorMessage: message),
  };
}
```

---

## Factory Pattern for Platform-Specific Widgets

**Problem:** Create different widgets based on platform without `if` chains.

```dart
/// Abstract dialog interface
abstract class PlatformDialog {
  factory PlatformDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    if (Platform.isIOS || Platform.isMacOS) {
      return CupertinoAlertDialogWrapper(
        title: title,
        content: content,
        onConfirm: onConfirm,
      );
    }
    return MaterialAlertDialogWrapper(
      title: title,
      content: content,
      onConfirm: onConfirm,
    );
  }

  Widget build(BuildContext context);
}

class MaterialAlertDialogWrapper implements PlatformDialog {
  const MaterialAlertDialogWrapper({
    required this.title,
    required this.content,
    required this.onConfirm,
  });

  final String title;
  final String content;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class CupertinoAlertDialogWrapper implements PlatformDialog {
  const CupertinoAlertDialogWrapper({
    required this.title,
    required this.content,
    required this.onConfirm,
  });

  final String title;
  final String content;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
```

---

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Better Approach |
|--------------|---------|-----------------|
| God widget (500+ lines) | Untestable, hard to read | Extract sub-widgets, use composition |
| Inheritance for UI reuse | Fragile, deep hierarchies | Composition with slots / builder |
| Business logic in `build()` | Untestable, side effects | MVVM — AsyncNotifier as ViewModel |
| `dynamic` types | No compile-time safety | Freezed models, typed responses |
| Manual `Provider()` | Verbose, error-prone | `@riverpod` annotation + codegen |
| `setState` for shared state | Prop drilling, rebuilds | Riverpod provider with `select()` |
| Singletons via static fields | Hard to test, tight coupling | Riverpod provider (DI built-in) |
| `initState` + async call | No cancellation, leaks | Riverpod `FutureProvider` / `AsyncNotifier` |
| Barrel files (re-exports) | Slower analysis, larger builds | Direct imports per file |

## Pattern Selection Guide

| Situation | Pattern |
|-----------|---------|
| Flexible widget layout | Composition (slots + builder) |
| Data layer abstraction | Repository + Riverpod DI |
| Screen with async data | MVVM (AsyncNotifier) |
| Swappable behavior at runtime | Strategy |
| Real-time data updates | Observer (Stream + StreamProvider) |
| Exhaustive state handling | Sealed Class Union (Freezed) |
| Platform-adaptive UI | Factory |
| Shared expensive resource | Singleton via `@Riverpod(keepAlive: true)` |
