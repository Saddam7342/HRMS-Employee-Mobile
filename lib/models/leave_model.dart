class LeaveRequestModel {
  final String id;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String? reason;
  final double days;

  LeaveRequestModel({
    required this.id,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.reason,
    required this.days,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['id'],
      leaveType: json['leaveType'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: json['status'],
      reason: json['reason'],
      days: (json['days'] as num).toDouble(),
    );
  }
}

class LeaveBalanceModel {
  final String leaveType;
  final double total;
  final double used;
  final double remaining;

  LeaveBalanceModel({
    required this.leaveType,
    required this.total,
    required this.used,
    required this.remaining,
  });

  factory LeaveBalanceModel.fromJson(Map<String, dynamic> json) {
    return LeaveBalanceModel(
      leaveType: json['leaveType'],
      total: (json['total'] as num).toDouble(),
      used: (json['used'] as num).toDouble(),
      remaining: (json['remaining'] as num).toDouble(),
    );
  }
}
