import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final token = data['token'];
        
        await _storage.write(key: StorageKeys.token, value: token);
        
        // Fetch user profile
        return await fetchProfile();
      } else {
        _error = response.data['message'] ?? 'Login failed';
        return false;
      }
    } catch (e) {
      _error = 'An error occurred during login';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> fetchProfile() async {
    try {
      final response = await _apiService.get(ApiConstants.profile);
      if (response.statusCode == 200) {
        _user = UserModel.fromJson(response.data['data']);
        await _storage.write(key: StorageKeys.userData, value: jsonEncode(_user!.toJson()));
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> tryAutoLogin() async {
    final token = await _storage.read(key: StorageKeys.token);
    if (token == null) return;

    final userData = await _storage.read(key: StorageKeys.userData);
    if (userData != null) {
      _user = UserModel.fromJson(jsonDecode(userData));
      notifyListeners();
      // Optionally refresh profile in background
      fetchProfile().then((_) => notifyListeners());
    } else {
      await fetchProfile();
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: StorageKeys.token);
    await _storage.delete(key: StorageKeys.userData);
    _user = null;
    notifyListeners();
  }
}
