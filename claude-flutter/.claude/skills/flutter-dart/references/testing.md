# Testing Reference

## Unit Tests (Pure Dart)

Unit tests cover models, repositories, providers, and utility functions without any Flutter framework dependency.

### Model Serialization Tests

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User model', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'u-1',
        'name': 'Alice',
        'email': 'alice@example.com',
        'avatar_url': 'https://example.com/avatar.png',
        'created_at': '2025-01-15T10:30:00Z',
        'role': 'admin',
      };

      final user = User.fromJson(json);

      expect(user.id, 'u-1');
      expect(user.name, 'Alice');
      expect(user.email, 'alice@example.com');
      expect(user.avatarUrl, 'https://example.com/avatar.png');
      expect(user.role, UserRole.admin);
      expect(user.createdAt, DateTime.utc(2025, 1, 15, 10, 30));
    });

    test('toJson produces correct map', () {
      final user = User(
        id: 'u-1',
        name: 'Alice',
        email: 'alice@example.com',
        createdAt: DateTime.utc(2025, 1, 15, 10, 30),
        role: UserRole.admin,
      );

      final json = user.toJson();

      expect(json['id'], 'u-1');
      expect(json['avatar_url'], isNull);
      expect(json['role'], 'admin');
    });

    test('fromJson round-trip preserves data', () {
      final original = User(
        id: 'u-2',
        name: 'Bob',
        email: 'bob@example.com',
        createdAt: DateTime.utc(2025, 3, 1),
      );

      final roundTripped = User.fromJson(original.toJson());

      expect(roundTripped, equals(original));
    });

    test('copyWith creates modified copy', () {
      final user = User(
        id: 'u-1',
        name: 'Alice',
        email: 'alice@example.com',
        createdAt: DateTime.utc(2025, 1, 15),
      );

      final updated = user.copyWith(name: 'Alice Smith');

      expect(updated.name, 'Alice Smith');
      expect(updated.id, 'u-1'); // unchanged
      expect(updated.email, 'alice@example.com'); // unchanged
    });
  });
}
```

### Repository Tests with Mocked Dio

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ProductRepositoryImpl repository;

  setUp(() {
    mockDio = MockDio();
    repository = ProductRepositoryImpl(dio: mockDio);
  });

  group('getProductById', () {
    test('returns product on success', () async {
      final responseData = {
        'id': 'p-1',
        'name': 'Widget',
        'description': 'A fine widget',
        'price': 29.99,
        'image_urls': ['https://example.com/img.png'],
        'created_at': '2025-06-01T00:00:00Z',
        'category': {'id': 'c-1', 'name': 'Gadgets'},
        'available': true,
      };

      when(() => mockDio.get<Map<String, dynamic>>('/products/p-1'))
          .thenAnswer((_) async => Response(
                data: responseData,
                statusCode: 200,
                requestOptions: RequestOptions(path: '/products/p-1'),
              ));

      final product = await repository.getProductById('p-1');

      expect(product.id, 'p-1');
      expect(product.name, 'Widget');
      expect(product.price, 29.99);
      verify(() => mockDio.get<Map<String, dynamic>>('/products/p-1')).called(1);
    });

    test('throws AppException.notFound on 404', () async {
      when(() => mockDio.get<Map<String, dynamic>>('/products/missing'))
          .thenThrow(DioException(
        type: DioExceptionType.badResponse,
        response: Response(
          statusCode: 404,
          requestOptions: RequestOptions(path: '/products/missing'),
        ),
        requestOptions: RequestOptions(path: '/products/missing'),
      ));

      expect(
        () => repository.getProductById('missing'),
        throwsA(isA<AppException>()),
      );
    });

    test('throws AppException.timeout on connection timeout', () async {
      when(() => mockDio.get<Map<String, dynamic>>('/products/p-1'))
          .thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: '/products/p-1'),
      ));

      expect(
        () => repository.getProductById('p-1'),
        throwsA(
          isA<AppException>().having(
            (e) => e.userMessage,
            'userMessage',
            contains('timed out'),
          ),
        ),
      );
    });
  });
}
```

## Widget Tests

### Basic Widget Test

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Helper to pump any widget with required ancestors
extension WidgetTesterX on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(body: widget),
        ),
      ),
    );
  }
}

void main() {
  group('UserProfileCard', () {
    testWidgets('displays name and email', (tester) async {
      await tester.pumpApp(
        const UserProfileCard(
          name: 'Alice',
          email: 'alice@example.com',
        ),
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('alice@example.com'), findsOneWidget);
    });

    testWidgets('shows avatar initial when no URL', (tester) async {
      await tester.pumpApp(
        const UserProfileCard(name: 'Bob', email: 'bob@example.com'),
      );

      expect(find.text('B'), findsOneWidget); // First letter of name
    });

    testWidgets('fires onTap callback', (tester) async {
      var tapped = false;
      await tester.pumpApp(
        UserProfileCard(
          name: 'Alice',
          email: 'alice@example.com',
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(UserProfileCard));
      expect(tapped, isTrue);
    });
  });
}
```

### Testing with Riverpod Overrides

```dart
class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockProductRepository mockRepo;

  setUp(() {
    mockRepo = MockProductRepository();
  });

  testWidgets('ProductPage shows products on success', (tester) async {
    final products = [
      Product(id: '1', name: 'Shoe', description: 'Nice', price: 99.99,
          createdAt: DateTime.now(), category: ProductCategory.footwear),
      Product(id: '2', name: 'Hat', description: 'Cool', price: 29.99,
          createdAt: DateTime.now(), category: ProductCategory.accessories),
    ];
    when(() => mockRepo.getProducts()).thenAnswer((_) async =>
        PaginatedResponse(data: products, total: 2, page: 1, perPage: 20, totalPages: 1));

    await tester.pumpApp(
      const ProductPage(),
      overrides: [
        productRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    // Wait for async provider to load
    await tester.pumpAndSettle();

    expect(find.text('Shoe'), findsOneWidget);
    expect(find.text('Hat'), findsOneWidget);
  });

  testWidgets('ProductPage shows error view on failure', (tester) async {
    when(() => mockRepo.getProducts())
        .thenThrow(const AppException.serverError());

    await tester.pumpApp(
      const ProductPage(),
      overrides: [
        productRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Server error. Please try again later.'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget); // Retry button
  });

  testWidgets('ProductPage shows loading indicator initially', (tester) async {
    when(() => mockRepo.getProducts())
        .thenAnswer((_) => Future.delayed(const Duration(seconds: 5), () =>
            PaginatedResponse(data: [], total: 0, page: 1, perPage: 20, totalPages: 0)));

    await tester.pumpApp(
      const ProductPage(),
      overrides: [
        productRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );

    // Do NOT pumpAndSettle — we want to catch the loading state
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

### Testing Navigation with GoRouter

```dart
void main() {
  testWidgets('tapping product navigates to detail page', (tester) async {
    final mockRepo = MockProductRepository();
    when(() => mockRepo.getProducts()).thenAnswer((_) async =>
        PaginatedResponse(data: [testProduct], total: 1, page: 1, perPage: 20, totalPages: 1));
    when(() => mockRepo.getProductById('p-1')).thenAnswer((_) async => testProduct);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const ProductPage(),
          routes: [
            GoRoute(
              path: 'detail/:id',
              builder: (_, state) => ProductDetailPage(id: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [productRepositoryProvider.overrideWithValue(mockRepo)],
        child: MaterialApp.router(routerConfig: router, theme: AppTheme.light()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(testProduct.name));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailPage), findsOneWidget);
  });
}
```

## Integration Tests

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end login flow', () {
    testWidgets('user can log in and see home page', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      // Should land on login page
      expect(find.byType(LoginPage), findsOneWidget);

      // Enter credentials
      await tester.enterText(
        find.byKey(const ValueKey('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('password_field')),
        'password123',
      );

      // Tap login
      await tester.tap(find.byKey(const ValueKey('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should navigate to home
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Welcome'), findsOneWidget);
    });
  });
}
```

Run integration tests:
```bash
flutter test integration_test/app_test.dart
# On a specific device
flutter test integration_test --device-id <device_id>
```

## Golden Tests

Golden tests compare widget screenshots pixel-by-pixel against reference images:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfileCard golden', () {
    testWidgets('matches light theme snapshot', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: UserProfileCard(
                  name: 'Alice Johnson',
                  email: 'alice@example.com',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(UserProfileCard),
        matchesGoldenFile('goldens/user_profile_card_light.png'),
      );
    });

    testWidgets('matches dark theme snapshot', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: UserProfileCard(
                  name: 'Alice Johnson',
                  email: 'alice@example.com',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(UserProfileCard),
        matchesGoldenFile('goldens/user_profile_card_dark.png'),
      );
    });
  });
}
```

Update golden files:
```bash
flutter test --update-goldens
```

CI tip: Golden tests can produce different results across platforms. Pin the platform in CI:
```yaml
# .github/workflows/test.yml
jobs:
  test:
    runs-on: ubuntu-latest  # Always same OS for golden consistency
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.5'
      - run: flutter test --update-goldens  # Only on dedicated golden-update branch
```

## Mocking with Mocktail

```dart
import 'package:mocktail/mocktail.dart';

// Create mock classes
class MockUserRepository extends Mock implements UserRepository {}
class MockGoRouter extends Mock implements GoRouter {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

// Register fallback values for non-nullable parameters
setUpAll(() {
  registerFallbackValue(const CreateProductRequest(
    name: '',
    description: '',
    price: 0,
    categoryId: '',
  ));
  registerFallbackValue(Uri.parse('https://example.com'));
});

// Stubbing
when(() => mockRepo.getProductById(any())).thenAnswer((_) async => testProduct);
when(() => mockRepo.createProduct(any())).thenAnswer((_) async => testProduct);
when(() => mockRepo.deleteProduct(any())).thenAnswer((_) async {});

// Verification
verify(() => mockRepo.getProductById('p-1')).called(1);
verifyNever(() => mockRepo.deleteProduct(any()));
```

## Riverpod Test Utilities

```dart
// Create a test container with overrides
ProviderContainer createTestContainer({
  List<Override> overrides = const [],
}) {
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  return container;
}

// Test async providers
test('products provider loads data', () async {
  final mockRepo = MockProductRepository();
  when(() => mockRepo.getProducts()).thenAnswer((_) async =>
      PaginatedResponse(data: testProducts, total: 2, page: 1, perPage: 20, totalPages: 1));

  final container = createTestContainer(overrides: [
    productRepositoryProvider.overrideWithValue(mockRepo),
  ]);

  // Listen to track state transitions
  final states = <AsyncValue<List<Product>>>[];
  container.listen(productListProvider, (_, next) => states.add(next), fireImmediately: true);

  // Wait for the async operation
  await container.read(productListProvider.future);

  expect(states, [
    isA<AsyncLoading<List<Product>>>(),
    isA<AsyncData<List<Product>>>().having((d) => d.value.length, 'length', 2),
  ]);
});
```

## Test Data Builders

```dart
// test/helpers/builders.dart
class UserBuilder {
  String _id = 'u-default';
  String _name = 'Test User';
  String _email = 'test@example.com';
  String? _avatarUrl;
  DateTime _createdAt = DateTime.utc(2025, 1, 1);
  UserRole _role = UserRole.member;

  UserBuilder withId(String id) { _id = id; return this; }
  UserBuilder withName(String name) { _name = name; return this; }
  UserBuilder withEmail(String email) { _email = email; return this; }
  UserBuilder withAvatar(String url) { _avatarUrl = url; return this; }
  UserBuilder withRole(UserRole role) { _role = role; return this; }
  UserBuilder createdAt(DateTime dt) { _createdAt = dt; return this; }

  User build() => User(
    id: _id,
    name: _name,
    email: _email,
    avatarUrl: _avatarUrl,
    createdAt: _createdAt,
    role: _role,
  );
}

// Usage
final admin = UserBuilder().withRole(UserRole.admin).withName('Admin').build();
final users = List.generate(10, (i) => UserBuilder().withId('u-$i').withName('User $i').build());
```

## CI Pipeline Setup

```yaml
# .github/workflows/flutter_ci.yml
name: Flutter CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.5'
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter analyze --fatal-infos

  test:
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.5'
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter test --coverage
      - name: Check coverage threshold
        run: |
          COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep 'lines' | sed 's/.*: //' | sed 's/%.*//')
          echo "Coverage: $COVERAGE%"
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "Coverage below 80% threshold"
            exit 1
          fi

  build:
    runs-on: ubuntu-latest
    needs: test
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.5'
      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter build apk --release --dart-define-from-file=env/.env.staging
      - uses: actions/upload-artifact@v4
        with:
          name: apk-release
          path: build/app/outputs/flutter-apk/app-release.apk
```
