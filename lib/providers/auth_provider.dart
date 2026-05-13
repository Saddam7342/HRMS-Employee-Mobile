import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../models/employee_model.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  UserModel? _user;
  EmployeeProfile? _profile;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _error;

  UserModel? get user => _user;
  EmployeeProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final res = await _api.post(ApiConstants.login, data: {
        'emailOrUsername': email.trim(),
        'password': password,
      });
      final data = ApiService.extractData(res);
      final token = data['token'] ?? data['accessToken'];
      if (token == null) {
        _error = 'Invalid response from server';
        _setLoading(false);
        return false;
      }
      await _storage.write(key: StorageKeys.token, value: token);
      if (data['refreshToken'] != null) {
        await _storage.write(key: StorageKeys.refreshToken, value: data['refreshToken']);
      }
      await _fetchCurrentUser();
      await _fetchEmployeeProfile();
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _error = ApiService.extractError(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Login failed. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<void> _fetchCurrentUser() async {
    try {
      final res = await _api.get(ApiConstants.profile);
      final data = ApiService.extractData(res);
      _user = UserModel.fromJson(data is Map<String, dynamic> ? data : {});
      await _storage.write(key: StorageKeys.userData, value: jsonEncode(_user!.toJson()));
    } catch (_) {}
  }

  Future<void> _fetchEmployeeProfile() async {
    try {
      final res = await _api.get(ApiConstants.employeeMe);
      final data = ApiService.extractData(res);
      _profile = EmployeeProfile.fromJson(data is Map<String, dynamic> ? data : {});
    } catch (_) {}
  }

  Future<void> tryAutoLogin() async {
    _isInitializing = true;
    notifyListeners();
    try {
      final token = await _storage.read(key: StorageKeys.token);
      if (token == null || token.isEmpty) {
        _isInitializing = false;
        notifyListeners();
        return;
      }
      // Try restoring from cache
      final cached = await _storage.read(key: StorageKeys.userData);
      if (cached != null) {
        _user = UserModel.fromJson(jsonDecode(cached));
      }
      // Refresh from server
      await _fetchCurrentUser();
      await _fetchEmployeeProfile();
    } catch (_) {
      await logout(silent: true);
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await _api.post(ApiConstants.changePassword, data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      _setLoading(false);
      return true;
    } on DioException catch (e) {
      _error = ApiService.extractError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<void> refreshProfile() async {
    await _fetchCurrentUser();
    await _fetchEmployeeProfile();
    notifyListeners();
  }

  Future<void> logout({bool silent = false}) async {
    if (!silent) {
      try {
        final token = await _storage.read(key: StorageKeys.token);
        if (token != null) {
          await _api.post(ApiConstants.logout, data: {'refreshToken': token});
        }
      } catch (_) {}
    }
    await _storage.deleteAll();
    _user = null;
    _profile = null;
    _error = null;
    notifyListeners();
  }
}
