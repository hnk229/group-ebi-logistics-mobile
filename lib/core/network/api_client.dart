import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../storage/secure_storage.dart';

/// Dio configuré pour l'API Laravel (base URL + Sanctum Bearer + intercepteur 401).
/// Le token Bearer est injecté automatiquement depuis SecureStorage.
class ApiClient {
  ApiClient(this._dio, this._storage);

  final Dio _dio;
  final SecureStorage _storage;

  Dio get raw => _dio;

  /// GET avec query params optionnels.
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) {
    return _dio.get<T>(path, queryParameters: query);
  }

  Future<Response<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? query}) {
    return _dio.post<T>(path, data: data, queryParameters: query);
  }

  Future<Response<T>> patch<T>(String path, {dynamic data}) {
    return _dio.patch<T>(path, data: data);
  }

  Future<Response<T>> put<T>(String path, {dynamic data}) {
    return _dio.put<T>(path, data: data);
  }

  Future<Response<T>> delete<T>(String path, {dynamic data}) {
    return _dio.delete<T>(path, data: data);
  }

  /// Met à jour le token Bearer dans les headers + persistance sécurisée.
  Future<void> setToken(String? token) async {
    if (token == null) {
      _dio.options.headers.remove('Authorization');
      await _storage.delete(Env.storageAuthToken);
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      await _storage.write(Env.storageAuthToken, token);
    }
  }

  /// Restaure le token depuis le storage au démarrage.
  Future<String?> restoreToken() async {
    final token = await _storage.read(Env.storageAuthToken);
    if (token != null && token.isNotEmpty) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
    return token;
  }
}

/// Provider Dio brut (override possible pour tests).
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: Env.apiBaseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    validateStatus: (s) => s != null && s < 500,
  ));

  if (Env.isDev) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true, responseBody: true,
      logPrint: (o) {}, // remplacé par un dev tool propre plus tard
    ));
  }

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(secureStorageProvider);
  final client = ApiClient(dio, storage);

  // Intercepteur 401 : on purge le token (router redirigera vers login).
  dio.interceptors.add(InterceptorsWrapper(
    onError: (e, handler) async {
      if (e.response?.statusCode == 401) {
        await client.setToken(null);
      }
      handler.next(e);
    },
  ));

  return client;
});

/// Helper : extrait un message d'erreur lisible depuis une DioException.
String extractErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) return data['message'] as String;
    if (data is Map && data['error'] is String) return data['error'] as String;
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Délai dépassé. Vérifiez votre connexion internet.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Pas de connexion internet.';
    }
    return error.message ?? 'Erreur réseau';
  }
  return error.toString();
}
