import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../models/attendance_model.dart';

class AttendanceProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  AttendanceRecord? _today;
  List<AttendanceRecord> _history = [];
  AttendanceSummary? _summary;
  bool _isLoading = false;
  String? _error;

  AttendanceRecord? get today => _today;
  List<AttendanceRecord> get history => _history;
  AttendanceSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchToday() async {
    try {
      final res = await _api.get(ApiConstants.todayAttendance);
      final data = ApiService.extractData(res);
      if (data != null) {
        _today = AttendanceRecord.fromJson(data);
      } else {
        _today = null;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        _today = null;
      }
    } catch (_) {
      _today = null;
    }
    notifyListeners();
  }

  Future<String?> checkIn({String? notes}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.post(ApiConstants.checkIn, data: {'notes': notes ?? ''});
      final data = ApiService.extractData(res);
      if (data != null) {
        _today = AttendanceRecord.fromJson(data);
      }
      await fetchToday();
      _isLoading = false;
      notifyListeners();
      return null;
    } on DioException catch (e) {
      _error = ApiService.extractError(e);
      _isLoading = false;
      notifyListeners();
      return _error;
    }
  }

  Future<String?> checkOut({String? notes}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.post(ApiConstants.checkOut, data: {'notes': notes ?? ''});
      await fetchToday();
      _isLoading = false;
      notifyListeners();
      return null;
    } on DioException catch (e) {
      _error = ApiService.extractError(e);
      _isLoading = false;
      notifyListeners();
      return _error;
    }
  }

  Future<void> fetchHistory({DateTime? start, DateTime? end}) async {
    try {
      final now = end ?? DateTime.now();
      final from = start ?? DateTime(now.year, now.month, 1);
      final res = await _api.get(ApiConstants.myAttendance, queryParameters: {
        'start': from.toIso8601String(),
        'end': now.toIso8601String(),
      });
      final data = ApiService.extractData(res);
      if (data is List) {
        _history = data.map((e) => AttendanceRecord.fromJson(e)).toList();
      }
    } catch (_) {
      _history = [];
    }
    notifyListeners();
  }

  Future<void> fetchSummary({DateTime? start, DateTime? end}) async {
    try {
      final now = end ?? DateTime.now();
      final from = start ?? DateTime(now.year, now.month, 1);
      final res = await _api.get(ApiConstants.attendanceSummary, queryParameters: {
        'start': from.toIso8601String(),
        'end': now.toIso8601String(),
      });
      final data = ApiService.extractData(res);
      if (data != null) {
        _summary = AttendanceSummary.fromJson(data);
      }
    } catch (_) {}
    notifyListeners();
  }
}
