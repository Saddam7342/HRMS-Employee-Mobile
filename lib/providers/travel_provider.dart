import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../models/travel_model.dart';

class TravelProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<TravelRequest> _myRequests = [];
  bool _isLoading = false;
  String? _error;

  List<TravelRequest> get myRequests => _myRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMyRequests() async {
    try {
      final res = await _api.get(ApiConstants.myTravel);
      final data = ApiService.extractData(res);
      if (data is List) {
        _myRequests = data.map((e) => TravelRequest.fromJson(e)).toList();
      }
    } catch (_) {
      _myRequests = [];
    }
    notifyListeners();
  }

  Future<String?> submitRequest({
    required String destination,
    required String purpose,
    required DateTime fromDate,
    required DateTime toDate,
    double? estimatedBudget,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.post(ApiConstants.createTravel, data: {
        'destination': destination,
        'purpose': purpose,
        'fromDate': fromDate.toUtc().toIso8601String(),
        'toDate': toDate.toUtc().toIso8601String(),
        'estimatedBudget': estimatedBudget,
      });
      await fetchMyRequests();
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

  Future<String?> cancelRequest(String id) async {
    try {
      await _api.put(ApiConstants.cancelTravel(id));
      await fetchMyRequests();
      return null;
    } on DioException catch (e) {
      return ApiService.extractError(e);
    }
  }
}
