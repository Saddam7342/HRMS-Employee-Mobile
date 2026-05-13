import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../core/leave_api_dates.dart';
import '../models/leave_model.dart';

class LeaveProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<LeaveRequest> _myLeaves = [];
  List<LeaveBalance> _balances = [];
  List<LeaveTypeOption> _leaveTypes = [];
  bool _isLoading = false;
  String? _error;

  List<LeaveRequest> get myLeaves => _myLeaves;
  List<LeaveBalance> get balances => _balances;
  List<LeaveTypeOption> get leaveTypes => _leaveTypes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Leave types that still have remaining balance (for applying leave).
  List<LeaveTypeOption> get typesWithAvailableBalance {
    return _leaveTypes
        .where((t) => (remainingForType(t.id) ?? 0) > 0)
        .toList();
  }

  double? remainingForType(String leaveTypeId) {
    for (final b in _balances) {
      if (b.leaveTypeId == leaveTypeId) return b.remaining;
    }
    return null;
  }

  Future<void> fetchMyLeaves() async {
    try {
      final res = await _api.get(ApiConstants.myLeaves);
      final data = ApiService.extractData(res);
      if (data is List) {
        _myLeaves = data
            .map((e) => LeaveRequest.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {
      _myLeaves = [];
    }
    notifyListeners();
  }

  Future<void> fetchBalances({int? year}) async {
    try {
      final res = await _api.get(
        ApiConstants.leaveBalances,
        queryParameters: year != null ? {'year': year} : null,
      );
      final data = ApiService.extractData(res);
      if (data is List) {
        _balances = data
            .map((e) => LeaveBalance.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {
      _balances = [];
    }
    notifyListeners();
  }

  Future<void> fetchLeaveTypes() async {
    try {
      final res = await _api.get(ApiConstants.leaveTypes);
      final data = ApiService.extractData(res);
      if (data is List) {
        _leaveTypes = data
            .map((e) =>
                LeaveTypeOption.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {
      _leaveTypes = [];
    }
    notifyListeners();
  }

  /// Loads history, balances, and eligible leave types together.
  Future<void> reloadAllLeaveData({int? year}) async {
    await Future.wait([
      fetchMyLeaves(),
      fetchBalances(year: year),
      fetchLeaveTypes(),
    ]);
  }

  /// Validates range and posts leave application. Returns `null` on success.
  Future<String?> applyLeave({
    required String leaveTypeId,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    if (end.isBefore(start)) {
      return 'End date must be on or after start date.';
    }
    final remaining = remainingForType(leaveTypeId);
    if (remaining != null && remaining <= 0) {
      return 'No balance remaining for this leave type.';
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.post(ApiConstants.applyLeave, data: {
        'leaveTypeId': leaveTypeId,
        'startDate': toLeaveApiDateOnly(start),
        'endDate': toLeaveApiDateOnly(end),
        'reason': reason,
      });
      await reloadAllLeaveData();
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

  Future<String?> cancelLeave(String id) async {
    try {
      await _api.put(ApiConstants.cancelLeave(id));
      await reloadAllLeaveData();
      return null;
    } on DioException catch (e) {
      return ApiService.extractError(e);
    }
  }
}
