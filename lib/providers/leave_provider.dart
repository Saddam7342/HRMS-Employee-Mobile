import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../models/leave_model.dart';

class LeaveProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<LeaveRequest> _myLeaves = [];
  List<LeaveBalance> _balances = [];
  bool _isLoading = false;
  String? _error;

  List<LeaveRequest> get myLeaves => _myLeaves;
  List<LeaveBalance> get balances => _balances;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMyLeaves() async {
    try {
      final res = await _api.get(ApiConstants.myLeaves);
      final data = ApiService.extractData(res);
      if (data is List) {
        _myLeaves = data.map((e) => LeaveRequest.fromJson(e)).toList();
      }
    } catch (_) {
      _myLeaves = [];
    }
    notifyListeners();
  }

  Future<void> fetchBalances({int? year}) async {
    try {
      final res = await _api.get(ApiConstants.leaveBalances,
          queryParameters: year != null ? {'year': year} : null);
      final data = ApiService.extractData(res);
      if (data is List) {
        _balances = data.map((e) => LeaveBalance.fromJson(e)).toList();
      }
    } catch (_) {
      _balances = [];
    }
    notifyListeners();
  }

  Future<String?> applyLeave({
    required String leaveTypeId,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.post(ApiConstants.applyLeave, data: {
        'leaveTypeId': leaveTypeId,
        'startDate': _toApiDateOnly(startDate),
        'endDate': _toApiDateOnly(endDate),
        'reason': reason,
      });
      await fetchMyLeaves();
      await fetchBalances();
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

  /// Calendar date as yyyy-MM-dd for the API (avoids timezone shifting the day).
  static String _toApiDateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<String?> cancelLeave(String id) async {
    try {
      await _api.put(ApiConstants.cancelLeave(id));
      await fetchMyLeaves();
      return null;
    } on DioException catch (e) {
      return ApiService.extractError(e);
    }
  }
}
