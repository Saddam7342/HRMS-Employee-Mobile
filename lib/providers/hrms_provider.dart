import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../models/attendance_model.dart';
import '../models/leave_model.dart';

class HRMSProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  AttendanceModel? _todayAttendance;
  List<LeaveBalanceModel> _balances = [];
  List<LeaveRequestModel> _myLeaves = [];
  bool _isLoading = false;

  AttendanceModel? get todayAttendance => _todayAttendance;
  List<LeaveBalanceModel> get balances => _balances;
  List<LeaveRequestModel> get myLeaves => _myLeaves;
  bool get isLoading => _isLoading;

  Future<void> fetchTodayAttendance() async {
    try {
      final response = await _apiService.get(ApiConstants.todayAttendance);
      if (response.statusCode == 200) {
        _todayAttendance = AttendanceModel.fromJson(response.data['data']);
      } else {
        _todayAttendance = null;
      }
    } catch (e) {
      _todayAttendance = null;
    }
    notifyListeners();
  }

  Future<bool> checkIn({String? notes}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post(ApiConstants.checkIn, data: {'notes': notes});
      if (response.statusCode == 200) {
        await fetchTodayAttendance();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkOut({String? notes}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post(ApiConstants.checkOut, data: {'notes': notes});
      if (response.statusCode == 200) {
        await fetchTodayAttendance();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLeaveBalances() async {
    try {
      final response = await _apiService.get(ApiConstants.leaveBalances);
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        _balances = data.map((e) => LeaveBalanceModel.fromJson(e)).toList();
      }
    } catch (e) {
      // Handle error
    }
    notifyListeners();
  }

  Future<void> fetchMyLeaves() async {
    try {
      final response = await _apiService.get(ApiConstants.myLeaves);
      if (response.statusCode == 200) {
        final List data = response.data['data'];
        _myLeaves = data.map((e) => LeaveRequestModel.fromJson(e)).toList();
      }
    } catch (e) {
      // Handle error
    }
    notifyListeners();
  }

  Future<bool> applyLeave({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    String? reason,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post(ApiConstants.applyLeave, data: {
        'leaveType': leaveType,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'reason': reason,
      });
      if (response.statusCode == 200) {
        await fetchMyLeaves();
        await fetchLeaveBalances();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
