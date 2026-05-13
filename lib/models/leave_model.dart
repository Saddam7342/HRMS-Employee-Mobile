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
        leaveType: j['leaveTypeName'] ?? j['leaveType'] ?? '',
        startDate: DateTime.tryParse(j['startDate'] ?? '') ?? DateTime.now(),
        endDate: DateTime.tryParse(j['endDate'] ?? '') ?? DateTime.now(),
        days: ((j['totalDays'] ?? j['days'] ?? 1) as num).toDouble(),
        status: j['status'] ?? 'Pending',
        reason: j['reason'],
        appliedAt: j['appliedAt'] != null ? DateTime.tryParse(j['appliedAt']) : null,
      );
}

class LeaveBalance {
  final String leaveTypeId;
  final String leaveType;
  final double total;
  final double used;
  final double remaining;

  LeaveBalance({
    required this.leaveTypeId,
    required this.leaveType,
    required this.total,
    required this.used,
    required this.remaining,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> j) => LeaveBalance(
        leaveTypeId: j['leaveTypeId'] ?? '',
        leaveType: j['leaveTypeName'] ?? j['leaveType'] ?? '',
        total: ((j['totalDays'] ?? j['total'] ?? 0) as num).toDouble(),
        used: ((j['usedDays'] ?? j['used'] ?? 0) as num).toDouble(),
        remaining: ((j['remainingDays'] ?? j['remaining'] ?? 0) as num).toDouble(),
      );
}
