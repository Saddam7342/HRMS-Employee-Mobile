import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _setupInterceptors();
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    contentType: 'application/json',
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
  ));

  Completer<bool>? _refreshCompleter;

  Future<bool> _refreshTokensLocked() async {
    final waitOn = _refreshCompleter;
    if (waitOn != null) {
      return waitOn.future;
    }
    final completer = Completer<bool>();
    _refreshCompleter = completer;
    try {
      final access = await _storage.read(key: StorageKeys.token);
      final refresh = await _storage.read(key: StorageKeys.refreshToken);
      if (access == null ||
          access.isEmpty ||
          refresh == null ||
          refresh.isEmpty) {
        completer.complete(false);
        return false;
      }
      final res = await _dio.post(
        ApiConstants.refresh,
        data: {'accessToken': access, 'refreshToken': refresh},
        options: Options(extra: {'skipAuthHeader': true}),
      );
      final data = extractData(res);
      if (data is! Map) {
        completer.complete(false);
        return false;
      }
      final accessNew = data['accessToken'] as String?;
      final refreshNew = data['refreshToken'] as String?;
      if (accessNew == null || accessNew.isEmpty) {
        completer.complete(false);
        return false;
      }
      await _storage.write(key: StorageKeys.token, value: accessNew);
      if (refreshNew != null && refreshNew.isNotEmpty) {
        await _storage.write(key: StorageKeys.refreshToken, value: refreshNew);
      }
      completer.complete(true);
      return true;
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['skipAuthHeader'] == true) {
            options.headers.remove('Authorization');
            debugPrint('--> ${options.method} ${options.uri} (no auth header)');
            return handler.next(options);
          }
          final token = await _storage.read(key: StorageKeys.token);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          debugPrint('--> ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('<-- ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (DioException e, ErrorInterceptorHandler handler) async {
          debugPrint(
              '<-- ERROR ${e.response?.statusCode} ${e.requestOptions.uri}');
          final path = e.requestOptions.path;
          if (e.response?.statusCode != 401 ||
              path.contains(ApiConstants.refresh) ||
              path.contains(ApiConstants.login) ||
              e.requestOptions.extra['skipRefresh'] == true) {
            return handler.next(e);
          }
          final refreshed = await _refreshTokensLocked();
          if (!refreshed) {
            return handler.next(e);
          }
          try {
            final req = e.requestOptions;
            final token = await _storage.read(key: StorageKeys.token);
            if (token != null && token.isNotEmpty) {
              req.headers['Authorization'] = 'Bearer $token';
            }
            final clone = await _dio.fetch(req);
            return handler.resolve(clone);
          } catch (e2) {
            return handler.next(e2 is DioException ? e2 : e);
          }
        },
      ),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get(path, queryParameters: queryParameters, options: options);
  }

  Future<Response> post(String path, {dynamic data, Options? options}) async {
    return _dio.post(path, data: data, options: options);
  }

  Future<Response> put(String path, {dynamic data, Options? options}) async {
    return _dio.put(path, data: data, options: options);
  }

  Future<Response> delete(String path, {Options? options}) async {
    return _dio.delete(path, options: options);
  }

  static dynamic extractData(Response response) {
    return response.data['data'];
  }

  static String extractMessage(Response response) {
    return response.data['message'] ?? 'Success';
  }

  static String extractError(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message'];
        if (msg != null) return msg.toString();
        final errs = data['errors'];
        if (errs is List && errs.isNotEmpty) return errs.join('; ');
        if (errs is String) return errs;
        return 'Request failed';
      }
    } catch (_) {}
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. Please check your internet.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }
    return e.message ?? 'An unexpected error occurred';
  }
}
