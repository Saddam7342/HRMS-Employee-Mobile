class ApiConstants {
  static const String baseUrl =
      'https://hrms-lite-backend-production-fc7c.up.railway.app/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String profile = '/auth/me';
  static const String logout = '/auth/logout';
  static const String changePassword = '/auth/change-password';

  // Employee
  static const String employeeMe = '/employees/me';

  // Attendance
  static const String checkIn = '/attendance/check-in';
  static const String checkOut = '/attendance/check-out';
  static const String todayAttendance = '/attendance/today';
  static const String myAttendance = '/attendance/my';
  static const String attendanceSummary = '/attendance/summary';

  // Leaves
  static const String leaveTypes = '/leaves/types';
  static const String myLeaves = '/leaves/my';
  static const String leaveBalances = '/leaves/balances';
  static const String applyLeave = '/leaves';
  static String cancelLeave(String id) => '/leaves/$id/cancel';

  // Expense Claims
  static const String myExpenses = '/expense-claims/my';
  static const String createExpense = '/expense-claims';
  static const String expenseCategories = '/expense-categories';
  static String expenseById(String id) => '/expense-claims/$id';

  // Travel
  static const String myTravel = '/travel-requests/my';
  static const String travelHistory = '/travel-requests/history';
  static const String createTravel = '/travel-requests';
  static String cancelTravel(String id) => '/travel-requests/$id/cancel';

  // Notifications
  static const String myNotifications = '/notifications/my';
  static const String notificationCount = '/notifications/count';
  static const String markAllRead = '/notifications/read-all';
  static String markRead(String id) => '/notifications/$id/read';
}

class StorageKeys {
  static const String token = 'hrms_auth_token';
  static const String refreshToken = 'hrms_refresh_token';
  static const String userData = 'hrms_user_data';
}
