class LeaveRequest {
  final String id;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final double days;
  final String status;
  final String? reason;
  final DateTime? appliedAt;

  LeaveRequest({
    required this.id,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.status,
    this.reason,
    this.appliedAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> j) => LeaveRequest(
        id: j['id'] ?? '',
        leaveType: j['leaveType'] ?? '',
        startDate: DateTime.tryParse(j['startDate'] ?? '') ?? DateTime.now(),
        endDate: DateTime.tryParse(j['endDate'] ?? '') ?? DateTime.now(),
        days: ((j['days'] ?? j['totalDays'] ?? 1) as num).toDouble(),
        status: j['status'] ?? 'Pending',
        reason: j['reason'],
        appliedAt: j['appliedAt'] != null ? DateTime.tryParse(j['appliedAt']) : null,
      );
}

class LeaveBalance {
  final String leaveType;
  final double total;
  final double used;
  final double remaining;

  LeaveBalance({
    required this.leaveType,
    required this.total,
    required this.used,
    required this.remaining,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> j) => LeaveBalance(
        leaveType: j['leaveType'] ?? '',
        total: ((j['total'] ?? j['totalDays'] ?? 0) as num).toDouble(),
        used: ((j['used'] ?? j['usedDays'] ?? 0) as num).toDouble(),
        remaining: ((j['remaining'] ?? j['remainingDays'] ?? 0) as num).toDouble(),
      );
}
