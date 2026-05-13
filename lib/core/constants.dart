class ApiConstants {
  static const String baseUrl = 'https://hrms-lite-backend-production-fc7c.up.railway.app/api/v1';
  
  // Auth
  static const String login = '/auth/login';
  static const String profile = '/auth/me';
  
  // Attendance
  static const String checkIn = '/attendance/check-in';
  static const String checkOut = '/attendance/check-out';
  static const String todayAttendance = '/attendance/today';
  static const String myAttendance = '/attendance/my';
  
  // Leaves
  static const String myLeaves = '/leaves/my';
  static const String leaveBalances = '/leaves/balances';
  static const String applyLeave = '/leaves';
}

class StorageKeys {
  static const String token = 'auth_token';
  static const String userData = 'user_data';
}
