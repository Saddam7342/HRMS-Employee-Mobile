import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../core/app_prefs.dart';
import '../models/user_model.dart';
import '../models/employee_model.dart';
import '../services/biometric_auth_service.dart';

enum AuthStartupRoute {
  /// Session restored; go to main shell.
  main,

  /// Show password login.
  login,

  /// Tokens exist; require Face ID / fingerprint before restoring session.
  biometricUnlock,
}

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
  bool _biometricLoginEnabled = false;

  UserModel? get user => _user;
  EmployeeProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get biometricLoginEnabled => _biometricLoginEnabled;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> loadBiometricPreference() async {
    final p = await SharedPreferences.getInstance();
    _biometricLoginEnabled = p.getBool(AppPrefs.biometricLoginEnabled) ?? false;
    notifyListeners();
  }

  Future<void> setBiometricLoginEnabled(bool enabled) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(AppPrefs.biometricLoginEnabled, enabled);
    _biometricLoginEnabled = enabled;
    notifyListeners();
  }

  /// Cached user for unlock screen (no API yet).
  Future<void> hydrateCachedUserForUnlock() async {
    try {
      final cached = await _storage.read(key: StorageKeys.userData);
      if (cached != null) {
        _user = UserModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (_) {}
  }

  /// After splash: where to route before showing a password form.
  Future<AuthStartupRoute> resolveStartupRoute() async {
    await loadBiometricPreference();
    final access = await _storage.read(key: StorageKeys.token);
    final refresh = await _storage.read(key: StorageKeys.refreshToken);
    if (access == null || access.isEmpty) {
      _isInitializing = false;
      notifyListeners();
      return AuthStartupRoute.login;
    }
    if (_biometricLoginEnabled &&
        refresh != null &&
        refresh.isNotEmpty) {
      _isInitializing = false;
      notifyListeners();
      return AuthStartupRoute.biometricUnlock;
    }
    await silentRestoreSession();
    return isAuthenticated ? AuthStartupRoute.main : AuthStartupRoute.login;
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final res = await _api.post(
        ApiConstants.login,
        data: {
          'emailOrUsername': email.trim(),
          'password': password,
        },
        options: Options(extra: {'skipRefresh': true}),
      );
      final data = ApiService.extractData(res);
      final tokenData = data['token'];
      String? accessToken;
      String? refreshToken;

      if (tokenData is Map) {
        accessToken = tokenData['accessToken'] as String?;
        refreshToken = tokenData['refreshToken'] as String?;
      } else {
        accessToken = data['accessToken'] ?? data['token'] as String?;
        refreshToken = data['refreshToken'] as String?;
      }

      if (accessToken == null) {
        _error = 'Invalid response from server: Missing access token';
        _setLoading(false);
        return false;
      }
      await _storage.write(key: StorageKeys.token, value: accessToken);
      if (refreshToken != null) {
        await _storage.write(key: StorageKeys.refreshToken, value: refreshToken);
      }
      final profileOk = await _fetchCurrentUser();
      if (!profileOk) {
        _error = 'Could not load your profile.';
        _setLoading(false);
        await logout(silent: true);
        return false;
      }
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

  Future<bool> _fetchCurrentUser() async {
    try {
      final res = await _api.get(ApiConstants.profile);
      final data = ApiService.extractData(res);
      _user = UserModel.fromJson(data is Map<String, dynamic> ? data : {});
      await _storage.write(
          key: StorageKeys.userData, value: jsonEncode(_user!.toJson()));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _fetchEmployeeProfile() async {
    try {
      final res = await _api.get(ApiConstants.employeeMe);
      final data = ApiService.extractData(res);
      _profile = EmployeeProfile.fromJson(
          data is Map<String, dynamic> ? data : {});
    } catch (_) {}
  }

  /// Restore profile using stored tokens (used after splash and after biometric).
  Future<void> silentRestoreSession() async {
    _isInitializing = true;
    notifyListeners();
    try {
      final token = await _storage.read(key: StorageKeys.token);
      if (token == null || token.isEmpty) {
        return;
      }
      final cached = await _storage.read(key: StorageKeys.userData);
      if (cached != null) {
        _user = UserModel.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      }
      final profileOk = await _fetchCurrentUser();
      if (!profileOk) {
        await logout(silent: true);
        return;
      }
      await _fetchEmployeeProfile();
    } catch (_) {
      await logout(silent: true);
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Legacy entry used by other screens; same as [silentRestoreSession].
  Future<void> tryAutoLogin() => silentRestoreSession();

  /// Run device biometric/Face ID, then restore session from stored tokens.
  Future<bool> restoreSessionWithBiometric() async {
    _error = null;
    final ok = await BiometricAuthService.instance.authenticate(
      localizedReason: 'Sign in to HRMS Employee',
    );
    if (!ok) {
      _error = 'Biometric authentication was cancelled or failed.';
      notifyListeners();
      return false;
    }
    await silentRestoreSession();
    return isAuthenticated;
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
        final rt = await _storage.read(key: StorageKeys.refreshToken);
        if (rt != null && rt.isNotEmpty) {
          await _api.post(
            ApiConstants.logout,
            data: {'refreshToken': rt},
          );
        }
      } catch (_) {}
    }
    await _storage.deleteAll();
    final p = await SharedPreferences.getInstance();
    await p.remove(AppPrefs.biometricLoginEnabled);
    _biometricLoginEnabled = false;
    _user = null;
    _profile = null;
    _error = null;
    notifyListeners();
  }
}
