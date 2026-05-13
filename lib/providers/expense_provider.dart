import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../models/expense_model.dart';

class ExpenseProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<ExpenseClaim> _myClaims = [];
  List<ExpenseCategory> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<ExpenseClaim> get myClaims => _myClaims;
  List<ExpenseCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMyClaims() async {
    try {
      final res = await _api.get(ApiConstants.myExpenses);
      final data = ApiService.extractData(res);
      if (data is List) {
        _myClaims = data.map((e) => ExpenseClaim.fromJson(e)).toList();
      }
    } catch (_) {
      _myClaims = [];
    }
    notifyListeners();
  }

  Future<void> fetchCategories() async {
    try {
      final res = await _api.get(ApiConstants.expenseCategories);
      final data = ApiService.extractData(res);
      if (data is List) {
        _categories = data.map((e) => ExpenseCategory.fromJson(e)).toList();
      }
    } catch (_) {
      _categories = [];
    }
    notifyListeners();
  }

  Future<String?> submitClaim({
    required String title,
    required String categoryId,
    required double amount,
    required DateTime claimDate,
    String? description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.post(ApiConstants.createExpense, data: {
        'title': title,
        'categoryId': categoryId,
        'amount': amount,
        'claimDate': claimDate.toIso8601String(),
        'description': description,
      });
      await fetchMyClaims();
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
}
