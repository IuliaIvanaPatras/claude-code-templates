---
name: flutter-dart
description: >
  Activated when building Flutter apps, creating widgets, implementing state management,
  setting up navigation, configuring themes, writing tests, or asking "how do I set up X"
  in a Flutter/Dart context. Covers UI, Riverpod, GoRouter, Dio, Freezed, Drift,
  Material 3 theming, testing, and Clean Architecture patterns.
---

# Flutter & Dart Development Skill

## Core Workflow

Follow these 6 steps when implementing any Flutter feature:

### Step 1 — Understand the Feature Boundary
- Identify which **feature module** this belongs to (e.g., `auth`, `home`, `profile`).
- Determine layers needed: **data** (models, data sources, repositories), **domain** (entities, use cases), **presentation** (pages, widgets, view models).
- Check if shared infrastructure already exists under `lib/core/`.

### Step 2 — Define the Data Model
- Create Freezed model classes in `lib/features/<feature>/data/models/`.
- Add `fromJson`/`toJson` via `json_serializable`.
- Define Drift table schemas if local persistence is needed.
- Write unit tests for serialization round-trips.

### Step 3 — Implement the Data Layer
- Create the remote data source using Dio in `lib/features/<feature>/data/data_sources/`.
- Create the repository implementation in `lib/features/<feature>/data/repositories/`.
- Handle errors with typed failure classes, never throw raw exceptions.
- Write unit tests with mocked Dio responses.

### Step 4 — Build the State Management
- Create Riverpod providers using `@riverpod` annotation in `lib/features/<feature>/presentation/providers/`.
- Use `AsyncNotifier` for stateful logic, plain `@riverpod` for computed values.
- Keep providers focused: one provider per concern.
- Write provider unit tests using `ProviderContainer`.

### Step 5 — Compose the UI
- Build pages in `lib/features/<feature>/presentation/pages/`.
- Extract reusable widgets into `lib/features/<feature>/presentation/widgets/`.
- Use `ConsumerWidget` / `ConsumerStatefulWidget` to read providers.
- Apply Material 3 theming via `Theme.of(context)`.
- Write widget tests for every page.

### Step 6 — Wire Navigation & Error Handling
- Add routes to the GoRouter configuration.
- Wrap async operations with proper error handling.
- Confirm Sentry breadcrumbs and error reporting are in place.
- Run `dart fix --apply` and `dart analyze` before committing.

---

## Quick Start Templates

### StatelessWidget Template

```dart
import 'package:flutter/material.dart';

class UserProfileCard extends StatelessWidget {
  const UserProfileCard({
    super.key,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.onTap,
  });

  final String name;
  final String email;
  final String? avatarUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? Text(name[0].toUpperCase(),
                        style: theme.textTheme.titleMedium)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
```

### StatefulWidget with Animation

```dart
import 'package:flutter/material.dart';

class AnimatedLikeButton extends StatefulWidget {
  const AnimatedLikeButton({
    super.key,
    required this.isLiked,
    required this.onToggle,
  });

  final bool isLiked;
  final ValueChanged<bool> onToggle;

  @override
  State<AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0);
    widget.onToggle(!widget.isLiked);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        onPressed: _handleTap,
        icon: Icon(
          widget.isLiked ? Icons.favorite : Icons.favorite_border,
          color: widget.isLiked ? colorScheme.error : colorScheme.onSurface,
        ),
      ),
    );
  }
}
```

### Riverpod Provider (@riverpod Annotation)

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_providers.g.dart';

// Simple computed provider (auto-dispose by default)
@riverpod
Future<User> currentUser(Ref ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getCurrentUser();
}

// Family provider with parameter
@riverpod
Future<User> userById(Ref ref, String userId) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getUserById(userId);
}

// Keep-alive provider (not auto-disposed)
@Riverpod(keepAlive: true)
Future<AuthState> authState(Ref ref) async {
  final storage = ref.watch(secureStorageProvider);
  final token = await storage.read(key: 'access_token');
  if (token == null) return const AuthState.unauthenticated();
  return AuthState.authenticated(token: token);
}
```

### AsyncNotifier with CRUD

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'todo_notifier.g.dart';

@riverpod
class TodoList extends _$TodoList {
  @override
  Future<List<Todo>> build() async {
    final repository = ref.watch(todoRepositoryProvider);
    return repository.fetchAll();
  }

  Future<void> addTodo(CreateTodoRequest request) async {
    final repository = ref.read(todoRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.create(request);
      return repository.fetchAll();
    });
  }

  Future<void> updateTodo(String id, UpdateTodoRequest request) async {
    final repository = ref.read(todoRepositoryProvider);
    // Optimistic update
    final previousState = state;
    state = AsyncData([
      for (final todo in state.requireValue)
        if (todo.id == id) todo.copyWith(title: request.title) else todo,
    ]);
    try {
      await repository.update(id, request);
    } catch (e, st) {
      state = previousState; // Rollback on failure
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteTodo(String id) async {
    final repository = ref.read(todoRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.delete(id);
      return repository.fetchAll();
    });
  }
}
```

### GoRouter Configuration with Deep Linking

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateProvider);
  final navigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/home',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull?.isAuthenticated ?? false;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isAuthenticated && !isAuthRoute) return '/auth/login';
      if (isAuthenticated && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      // Auth routes (no shell)
      GoRoute(
        path: '/auth/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),

      // Main app shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShellPage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomePage(),
              routes: [
                GoRoute(
                  path: 'detail/:id',
                  name: 'detail',
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return DetailPage(id: id);
                  },
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ]),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        ErrorPage(error: state.error.toString()),
  );
}
```

### Dio API Client with Interceptors

```dart
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_client.g.dart';

@Riverpod(keepAlive: true)
Dio apiClient(Ref ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ref.watch(envProvider).apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ));

  dio.interceptors.addAll([
    AuthInterceptor(ref),
    LogInterceptor(requestBody: true, responseBody: true),
    RetryInterceptor(dio: dio, retries: 3),
  ]);

  return dio;
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._ref);
  final Ref _ref;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        final retryResponse = await _retry(err.requestOptions);
        return handler.resolve(retryResponse);
      }
      _ref.read(authStateProvider.notifier).logout();
    }
    handler.next(err);
  }

  Future<bool> _attemptTokenRefresh() async {
    // Token refresh logic
    return false;
  }

  Future<Response<dynamic>> _retry(RequestOptions options) async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.read(key: 'access_token');
    options.headers['Authorization'] = 'Bearer $token';
    return Dio().fetch(options);
  }
}
```

### Freezed Model with JSON Serialization

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @Default(UserRole.member) UserRole role,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

enum UserRole {
  @JsonValue('admin')
  admin,
  @JsonValue('member')
  member,
  @JsonValue('guest')
  guest,
}

// Paginated response wrapper
@freezed
abstract class PaginatedResponse<T> with _$PaginatedResponse<T> {
  const factory PaginatedResponse({
    required List<T> data,
    required int total,
    required int page,
    @JsonKey(name: 'per_page') required int perPage,
    @JsonKey(name: 'total_pages') required int totalPages,
  }) = _PaginatedResponse<T>;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$PaginatedResponseFromJson(json, fromJsonT);
}
```

### Repository Pattern Implementation

```dart
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_repository.g.dart';

@riverpod
UserRepository userRepository(Ref ref) {
  return UserRepository(dio: ref.watch(apiClientProvider));
}

class UserRepository {
  const UserRepository({required Dio dio}) : _dio = dio;
  final Dio _dio;

  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/me');
      return User.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<PaginatedResponse<User>> getUsers({int page = 1, int perPage = 20}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      return PaginatedResponse.fromJson(
        response.data!,
        (json) => User.fromJson(json! as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<User> updateUser(String id, UpdateUserRequest request) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/users/$id',
        data: request.toJson(),
      );
      return User.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  AppException _mapDioError(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout =>
        const AppException.timeout(),
      DioExceptionType.badResponse => _mapStatusCode(e.response!.statusCode!),
      DioExceptionType.connectionError => const AppException.noConnection(),
      _ => AppException.unexpected(message: e.message ?? 'Unknown error'),
    };
  }

  AppException _mapStatusCode(int statusCode) {
    return switch (statusCode) {
      400 => const AppException.badRequest(),
      401 => const AppException.unauthorized(),
      403 => const AppException.forbidden(),
      404 => const AppException.notFound(),
      422 => const AppException.validationError(),
      >= 500 => const AppException.serverError(),
      _ => AppException.unexpected(message: 'HTTP $statusCode'),
    };
  }
}
```

### App Entry Point with Riverpod + GoRouter + Material 3

```dart
import 'dart:async';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await SentryFlutter.init(
        (options) {
          options.dsn = const String.fromEnvironment('SENTRY_DSN');
          options.tracesSampleRate = 0.2;
          options.environment = const String.fromEnvironment('ENV', defaultValue: 'dev');
        },
      );

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        Sentry.captureException(details.exception, stackTrace: details.stack);
      };

      runApp(const ProviderScope(child: MyApp()));
    },
    (error, stackTrace) {
      Sentry.captureException(error, stackTrace: stackTrace);
    },
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final lightScheme = lightDynamic ?? ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        );
        final darkScheme = darkDynamic ?? ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        );

        return MaterialApp.router(
          title: 'My App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: lightScheme,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkScheme,
            useMaterial3: true,
          ),
          themeMode: ref.watch(themeModeProvider),
          routerConfig: router,
        );
      },
    );
  }
}
```

### Error Handling Pattern

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_exception.freezed.dart';

@freezed
sealed class AppException with _$AppException implements Exception {
  const factory AppException.timeout() = _Timeout;
  const factory AppException.noConnection() = _NoConnection;
  const factory AppException.unauthorized() = _Unauthorized;
  const factory AppException.forbidden() = _Forbidden;
  const factory AppException.notFound() = _NotFound;
  const factory AppException.badRequest() = _BadRequest;
  const factory AppException.validationError({String? message}) = _ValidationError;
  const factory AppException.serverError() = _ServerError;
  const factory AppException.unexpected({String? message}) = _Unexpected;
}

extension AppExceptionX on AppException {
  String get userMessage => switch (this) {
    _Timeout() => 'Request timed out. Please try again.',
    _NoConnection() => 'No internet connection.',
    _Unauthorized() => 'Session expired. Please log in again.',
    _Forbidden() => 'You do not have permission.',
    _NotFound() => 'Resource not found.',
    _BadRequest() => 'Invalid request.',
    _ValidationError(:final message) => message ?? 'Validation failed.',
    _ServerError() => 'Server error. Please try again later.',
    _Unexpected(:final message) => message ?? 'An unexpected error occurred.',
  };
}
```

---

## Reference Guides

| Topic | File | When to Consult |
|---|---|---|
| Widget Composition | `references/widgets.md` | Building UI components, layout, responsive design, CustomPainter |
| State Management | `references/state-management.md` | Riverpod providers, AsyncNotifier, provider testing, state patterns |
| Data Layer | `references/data-layer.md` | Dio, Freezed models, repositories, caching, offline-first, Drift |
| Theming | `references/theming.md` | Material 3, ColorScheme, dark mode, ThemeExtension, typography |
| Testing | `references/testing.md` | Unit, widget, integration, golden tests, mocking, CI pipeline |

---

## Constraints

### MUST DO
- Use `@riverpod` annotation for all new providers (never hand-written `Provider()`).
- Declare widgets `const` whenever possible; use `const` constructors for all stateless widgets.
- Place every feature under `lib/features/<name>/` following the layer structure: `data/`, `domain/`, `presentation/`.
- Use `Freezed` for all data models and sealed union types.
- Handle all `DioException` cases explicitly in repositories; never let raw exceptions propagate.
- Use `AsyncValue` pattern (`when` / `switch`) in UI to handle loading/error/data states.
- Apply `very_good_analysis` lint rules; zero warnings before committing.
- Run `dart run build_runner build --delete-conflicting-outputs` after model changes.
- Use `GoRouter` for all navigation; never call `Navigator.push` directly.
- Write at minimum one widget test per page and one unit test per provider/repository.
- Use `Theme.of(context).colorScheme` and `Theme.of(context).textTheme` for all colors/fonts.
- Add `Key` parameters to widgets rendered in lists for efficient diffing.
- Dispose `AnimationController`, `TextEditingController`, `ScrollController` in `dispose()`.
- Use `ref.invalidate()` or `ref.refresh()` to trigger provider rebuilds; avoid manual state resets.

### MUST NOT DO
- Do NOT use `setState` for app-level or shared state; it is only for local ephemeral UI state (animations, form focus).
- Do NOT use `BuildContext` across async gaps; use `ref.read()` or check `mounted`.
- Do NOT store secrets in Dart code; use `envied` with `.env` files in `.gitignore`.
- Do NOT use `MediaQuery.of(context).size` directly; prefer `LayoutBuilder` or `MediaQuery.sizeOf(context)`.
- Do NOT nest more than 3 levels of widgets in a single `build()` method; extract sub-widgets.
- Do NOT use `dynamic` types; always specify concrete types.
- Do NOT use `late` unless the field is guaranteed initialized before first access.
- Do NOT call `ref.watch` inside callbacks, `onPressed`, or async functions; use `ref.read`.
- Do NOT import from another feature's `data/` or `presentation/` layer; share via `domain/` or `core/`.
- Do NOT use `print()`; use `dart:developer` `log()` or a logging package.

---

## Architecture Patterns

### Project Structure

```
lib/
├── app/
│   ├── app.dart                 # MyApp widget
│   └── router/
│       └── app_router.dart      # GoRouter config
├── core/
│   ├── constants/               # App-wide constants
│   ├── extensions/              # Dart/Flutter extensions
│   ├── network/
│   │   ├── api_client.dart      # Dio setup + interceptors
│   │   └── interceptors/
│   ├── storage/
│   │   ├── drift_database.dart  # Drift AppDatabase
│   │   └── secure_storage.dart  # flutter_secure_storage provider
│   ├── theme/
│   │   ├── app_theme.dart       # ThemeData factory
│   │   └── theme_extensions.dart
│   ├── utils/                   # Formatters, validators, helpers
│   └── error/
│       └── app_exception.dart   # Sealed exception hierarchy
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── data_sources/
│   │   │   │   └── auth_remote_data_source.dart
│   │   │   ├── models/
│   │   │   │   ├── login_request.dart
│   │   │   │   └── auth_token.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       └── auth_state.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── login_page.dart
│   │       ├── providers/
│   │       │   └── auth_provider.dart
│   │       └── widgets/
│   │           └── login_form.dart
│   └── home/
│       ├── data/ ...
│       ├── domain/ ...
│       └── presentation/ ...
├── l10n/                        # Localization ARB files
└── main.dart                    # Entry point
test/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── auth_repository_test.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── login_page_test.dart
│   │       └── providers/
│   │           └── auth_provider_test.dart
│   └── home/ ...
├── helpers/                     # Shared test utilities
│   ├── pump_app.dart
│   └── mocks.dart
└── goldens/                     # Golden reference images
integration_test/
└── app_test.dart
```

### Data Flow

```
UI (ConsumerWidget)
  │  ref.watch(provider)
  ▼
Provider (@riverpod AsyncNotifier)
  │  calls repository method
  ▼
Repository (concrete class)
  │  try/catch DioException → AppException
  ▼
Data Source (Dio / Drift)
  │  HTTP request or SQL query
  ▼
Remote API / Local DB
```

State always flows **down** from providers to widgets via `ref.watch()`.
Events flow **up** from widgets to providers via `ref.read(provider.notifier).method()`.

---

## Knowledge Base

- **Code generation**: After changing any `@freezed`, `@riverpod`, `@JsonSerializable`, or Drift model, run:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
  Or use watch mode during development:
  ```bash
  dart run build_runner watch --delete-conflicting-outputs
  ```

- **Environment variables**: Use `envied` package. Define a `.env` file (in `.gitignore`) and annotate a class:
  ```dart
  @Envied(path: '.env')
  abstract class Env {
    @EnviedField(varName: 'API_BASE_URL')
    static const String apiBaseUrl = _Env.apiBaseUrl;
    @EnviedField(varName: 'SENTRY_DSN', obfuscate: true)
    static const String sentryDsn = _Env.sentryDsn;
  }
  ```

- **Deep linking**: Configure `android/app/src/main/AndroidManifest.xml` with intent filters and `ios/Runner/Info.plist` with associated domains. GoRouter handles the rest.

- **Platform channels**: For platform-specific code, use `MethodChannel` or `pigeon` package. Keep channel logic in `core/platform/`.

- **Localization**: Use `flutter_localizations` + ARB files. Generate with `flutter gen-l10n`. Access via `AppLocalizations.of(context)!.someKey`.

- **Performance**: Use `const` widgets, `RepaintBoundary`, `AutomaticKeepAliveClientMixin`, and `ListView.builder` for long lists. Profile with DevTools.

- **CI commands**:
  ```bash
  flutter analyze
  flutter test --coverage
  flutter test --update-goldens   # Update golden files
  flutter build apk --release
  flutter build ipa --release
  ```
