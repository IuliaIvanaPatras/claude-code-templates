# Data Layer Reference

## Dio Configuration with Interceptors

### Base API Client Setup

```dart
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_client.g.dart';

@Riverpod(keepAlive: true)
Dio apiClient(Ref ref) {
  final env = ref.watch(envProvider);

  final dio = Dio(BaseOptions(
    baseUrl: env.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-App-Version': env.appVersion,
    },
    validateStatus: (status) => status != null && status < 500,
  ));

  dio.interceptors.addAll([
    AuthInterceptor(ref),
    RetryInterceptor(dio: dio),
    if (!env.isProduction) LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => log(obj.toString(), name: 'HTTP'),
    ),
  ]);

  return dio;
}
```

### Auth Interceptor with Token Refresh

```dart
class AuthInterceptor extends QueuedInterceptor {
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
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final storage = _ref.read(secureStorageProvider);
    final refreshToken = await storage.read(key: 'refresh_token');
    if (refreshToken == null) {
      _ref.read(authStateProvider.notifier).logout();
      return handler.next(err);
    }

    try {
      // Use a fresh Dio instance to avoid interceptor loop
      final refreshDio = Dio(BaseOptions(
        baseUrl: _ref.read(envProvider).apiBaseUrl,
      ));
      final response = await refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final newAccess = response.data!['access_token'] as String;
      final newRefresh = response.data!['refresh_token'] as String;
      await storage.write(key: 'access_token', value: newAccess);
      await storage.write(key: 'refresh_token', value: newRefresh);

      // Retry the original request with the new token
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      final retryResponse = await _ref.read(apiClientProvider).fetch(err.requestOptions);
      return handler.resolve(retryResponse);
    } on DioException {
      _ref.read(authStateProvider.notifier).logout();
      return handler.next(err);
    }
  }
}
```

### Retry Interceptor

```dart
class RetryInterceptor extends Interceptor {
  RetryInterceptor({required this.dio, this.maxRetries = 3});
  final Dio dio;
  final int maxRetries;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isRetryable = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;

    if (!isRetryable) return handler.next(err);

    final attempt = (err.requestOptions.extra['retry_count'] as int?) ?? 0;
    if (attempt >= maxRetries) return handler.next(err);

    final delay = Duration(milliseconds: 200 * (1 << attempt)); // Exponential backoff
    await Future<void>.delayed(delay);

    err.requestOptions.extra['retry_count'] = attempt + 1;
    try {
      final response = await dio.fetch(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
```

## Repository Pattern

```dart
abstract interface class ProductRepository {
  Future<PaginatedResponse<Product>> getProducts({int page = 1, int perPage = 20});
  Future<Product> getProductById(String id);
  Future<Product> createProduct(CreateProductRequest request);
  Future<Product> updateProduct(String id, UpdateProductRequest request);
  Future<void> deleteProduct(String id);
}

class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl({required Dio dio}) : _dio = dio;
  final Dio _dio;

  @override
  Future<PaginatedResponse<Product>> getProducts({int page = 1, int perPage = 20}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/products',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      return PaginatedResponse.fromJson(
        response.data!,
        (json) => Product.fromJson(json! as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<Product> getProductById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/products/$id');
      return Product.fromJson(response.data!);
    } on DioException catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<Product> createProduct(CreateProductRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/products',
        data: request.toJson(),
      );
      return Product.fromJson(response.data!);
    } on DioException catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<Product> updateProduct(String id, UpdateProductRequest request) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/products/$id',
        data: request.toJson(),
      );
      return Product.fromJson(response.data!);
    } on DioException catch (e) {
      throw e.toAppException();
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await _dio.delete<void>('/products/$id');
    } on DioException catch (e) {
      throw e.toAppException();
    }
  }
}

// DioException extension for clean error mapping
extension DioExceptionX on DioException {
  AppException toAppException() {
    return switch (type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const AppException.timeout(),
      DioExceptionType.connectionError => const AppException.noConnection(),
      DioExceptionType.badResponse => _mapBadResponse(),
      DioExceptionType.cancel => const AppException.unexpected(message: 'Request cancelled'),
      _ => AppException.unexpected(message: message ?? 'Unknown error'),
    };
  }

  AppException _mapBadResponse() {
    final statusCode = response?.statusCode ?? 0;
    final body = response?.data;
    final serverMessage = body is Map ? body['message'] as String? : null;

    return switch (statusCode) {
      400 => AppException.badRequest(message: serverMessage),
      401 => const AppException.unauthorized(),
      403 => const AppException.forbidden(),
      404 => const AppException.notFound(),
      422 => AppException.validationError(message: serverMessage),
      >= 500 => const AppException.serverError(),
      _ => AppException.unexpected(message: 'HTTP $statusCode'),
    };
  }
}
```

## Freezed Models with fromJson / toJson

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
abstract class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required String description,
    required double price,
    @JsonKey(name: 'image_urls') @Default([]) List<String> imageUrls,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    required ProductCategory category,
    @Default(true) bool available,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}

@freezed
abstract class CreateProductRequest with _$CreateProductRequest {
  const factory CreateProductRequest({
    required String name,
    required String description,
    required double price,
    @JsonKey(name: 'category_id') required String categoryId,
    @JsonKey(name: 'image_urls') @Default([]) List<String> imageUrls,
  }) = _CreateProductRequest;

  factory CreateProductRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateProductRequestFromJson(json);
}

@freezed
abstract class UpdateProductRequest with _$UpdateProductRequest {
  const factory UpdateProductRequest({
    String? name,
    String? description,
    double? price,
    @JsonKey(name: 'category_id') String? categoryId,
    bool? available,
  }) = _UpdateProductRequest;

  factory UpdateProductRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateProductRequestFromJson(json);
}
```

## Pagination Pattern

```dart
@riverpod
class ProductList extends _$ProductList {
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  Future<List<Product>> build() async {
    _currentPage = 1;
    _hasMore = true;
    final response = await ref.watch(productRepositoryProvider).getProducts(page: 1);
    _hasMore = response.page < response.totalPages;
    return response.data;
  }

  bool get hasMore => _hasMore;

  Future<void> loadMore() async {
    if (!_hasMore || state is AsyncLoading) return;
    _currentPage++;
    final repo = ref.read(productRepositoryProvider);
    final current = state.valueOrNull ?? [];

    state = await AsyncValue.guard(() async {
      final response = await repo.getProducts(page: _currentPage);
      _hasMore = response.page < response.totalPages;
      return [...current, ...response.data];
    });
  }
}

// In widget: detect end of list
NotificationListener<ScrollNotification>(
  onNotification: (notification) {
    if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
      ref.read(productListProvider.notifier).loadMore();
    }
    return false;
  },
  child: ListView.builder(/* ... */),
)
```

## File Upload / Download

```dart
Future<String> uploadImage(File file) async {
  try {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
        contentType: DioMediaType('image', 'jpeg'),
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/uploads/images',
      data: formData,
      onSendProgress: (sent, total) {
        final progress = sent / total;
        log('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      },
    );
    return response.data!['url'] as String;
  } on DioException catch (e) {
    throw e.toAppException();
  }
}

Future<File> downloadFile(String url, String savePath) async {
  try {
    await _dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          final progress = received / total;
          log('Download: ${(progress * 100).toStringAsFixed(1)}%');
        }
      },
    );
    return File(savePath);
  } on DioException catch (e) {
    throw e.toAppException();
  }
}
```

## Offline-First with Drift

```dart
import 'package:drift/drift.dart';

part 'app_database.g.dart';

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text()();
  RealColumn get price => real()();
  TextColumn get imageUrls => text().map(const StringListConverter())();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Products])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  // Watch all products (reactive stream)
  Stream<List<Product>> watchProducts() =>
      select(products).watch().map(
        (rows) => rows.map((row) => row.toDomain()).toList(),
      );

  // Upsert from remote
  Future<void> upsertProducts(List<Product> items) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(
        products,
        items.map((p) => ProductsCompanion.insert(
          id: p.id,
          name: p.name,
          description: p.description,
          price: p.price,
          imageUrls: p.imageUrls,
          createdAt: p.createdAt,
          syncedAt: Value(DateTime.now()),
        )).toList(),
      );
    });
  }
}

// Offline-first repository
class OfflineFirstProductRepository implements ProductRepository {
  const OfflineFirstProductRepository({
    required AppDatabase db,
    required Dio dio,
  }) : _db = db, _dio = dio;

  final AppDatabase _db;
  final Dio _dio;

  @override
  Stream<List<Product>> watchProducts() {
    // Return local data immediately, sync in background
    _syncFromRemote();
    return _db.watchProducts();
  }

  Future<void> _syncFromRemote() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/products');
      final products = PaginatedResponse.fromJson(
        response.data!,
        (json) => Product.fromJson(json! as Map<String, dynamic>),
      );
      await _db.upsertProducts(products.data);
    } on DioException {
      // Silently fail — local data is still available
    }
  }
}
```

## Secure Storage for Tokens

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage.g.dart';

@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(Ref ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
}

// Token management helper
class TokenStorage {
  const TokenStorage(this._storage);
  final FlutterSecureStorage _storage;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<String?> get accessToken => _storage.read(key: _accessKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshKey);

  Future<void> saveTokens({required String access, required String refresh}) async {
    await Future.wait([
      _storage.write(key: _accessKey, value: access),
      _storage.write(key: _refreshKey, value: refresh),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
    ]);
  }
}
```
