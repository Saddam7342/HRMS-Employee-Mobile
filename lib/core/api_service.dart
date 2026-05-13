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

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: StorageKeys.token);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          // Log request
          debugPrint('--> ${options.method} ${options.uri}');
          debugPrint('Headers: ${options.headers}');
          debugPrint('Payload: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log response
          debugPrint('<-- ${response.statusCode} ${response.requestOptions.uri}');
          debugPrint('Response: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // Log error
          debugPrint('<-- ERROR ${e.response?.statusCode} ${e.requestOptions.uri}');
          debugPrint('Error: ${e.response?.data ?? e.message}');
          return handler.next(e);
        },
      ),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }

  // Utility: extract data from wrapped API response
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
        return data['message'] ?? data['errors']?.toString() ?? 'Request failed';
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
