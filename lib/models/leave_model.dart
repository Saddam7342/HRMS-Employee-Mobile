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
        startDate: DateTime.tryParse(j['startDate'] ?? '')?.toLocal() ?? DateTime.now(),
        endDate: DateTime.tryParse(j['endDate'] ?? '')?.toLocal() ?? DateTime.now(),
        days: ((j['totalDays'] ?? j['days'] ?? 1) as num).toDouble(),
        status: j['status'] is int
            ? _statusFromInt(j['status'] as int)
            : (j['status']?.toString() ?? 'Pending'),
        reason: j['reason'],
        appliedAt: j['appliedAt'] != null ? DateTime.tryParse(j['appliedAt'])?.toLocal() : null,
      );

  static String _statusFromInt(int s) {
    switch (s) {
      case 1: return 'Pending';
      case 2: return 'Approved';
      case 3: return 'Rejected';
      case 4: return 'Cancelled';
      default: return 'Pending';
    }
  }
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

/// Eligible leave type from `GET /leaves/types`.
class LeaveTypeOption {
  final String id;
  final String name;
  final String code;
  final int defaultDays;
  final bool isGenderSpecific;
  final String? applicableGender;

  LeaveTypeOption({
    required this.id,
    required this.name,
    required this.code,
    required this.defaultDays,
    required this.isGenderSpecific,
    this.applicableGender,
  });

  factory LeaveTypeOption.fromJson(Map<String, dynamic> j) => LeaveTypeOption(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        code: j['code']?.toString() ?? '',
        defaultDays: (j['defaultDays'] as num?)?.toInt() ?? 0,
        isGenderSpecific: j['isGenderSpecific'] == true,
        applicableGender: j['applicableGender']?.toString(),
      );
}
