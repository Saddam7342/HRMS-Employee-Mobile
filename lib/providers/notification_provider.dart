import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  Future<void> fetchNotifications() async {
    try {
      final res = await _api.get(ApiConstants.myNotifications);
      final data = ApiService.extractData(res);
      final items = data is List ? data : (data?['items'] ?? data?['notifications'] ?? []);
      if (items is List) {
        _notifications = items.map((e) => AppNotification.fromJson(e)).toList();
      }
    } catch (_) {
      _notifications = [];
    }
    notifyListeners();
  }

  Future<void> fetchUnreadCount() async {
    try {
      final res = await _api.get(ApiConstants.notificationCount);
      final data = ApiService.extractData(res);
      _unreadCount = (data is int)
          ? data
          : ((data?['count'] ?? data?['unreadCount'] ?? 0) as num).toInt();
    } catch (_) {
      _unreadCount = 0;
    }
    notifyListeners();
  }

  Future<void> markAllRead() async {
    try {
      await _api.put(ApiConstants.markAllRead);
      _unreadCount = 0;
      for (var _ in _notifications) {
        // local update
      }
      await fetchNotifications();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    try {
      await _api.put(ApiConstants.markRead(id));
      _unreadCount = (_unreadCount - 1).clamp(0, 9999);
    } catch (_) {}
    notifyListeners();
  }
}
