class AttendanceRecord {
  final String id;
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String status;
  final String? notes;
  final Duration? duration;

  AttendanceRecord({
    required this.id,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.notes,
    this.duration,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) {
    final dateStr = j['date'] ?? '';
    final date = DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();

    DateTime? combine(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) return null;
      try {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          final h = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final s = parts.length > 2 ? int.parse(parts[2].split('.')[0]) : 0;
          return DateTime(date.year, date.month, date.day, h, m, s).toLocal();
        }
      } catch (_) {}
      return null;
    }

    final ci = combine(j['checkInTime'] ?? j['checkIn']);
    final co = combine(j['checkOutTime'] ?? j['checkOut']);

    Duration? dur;
    if (j['totalHours'] != null) {
      dur = Duration(minutes: ((j['totalHours'] as num) * 60).toInt());
    } else if (ci != null && co != null) {
      dur = co.difference(ci);
    }

    return AttendanceRecord(
      id: j['id'] ?? '',
      date: date,
      checkIn: ci,
      checkOut: co,
      status: j['status'] is int ? _statusFromInt(j['status']) : (j['status'] ?? 'Unknown'),
      notes: j['notes'],
      duration: dur,
    );
  }

  static String _statusFromInt(int s) {
    switch (s) {
      case 1: return 'CheckedIn';
      case 2: return 'CheckedOut';
      case 3: return 'MissingCheckout';
      case 4: return 'Absent';
      case 5: return 'OnLeave';
      case 6: return 'Holiday';
      case 7: return 'WorkFromHome';
      default: return 'Unknown';
    }
  }

  bool get isCheckedIn => checkIn != null && checkOut == null;
  bool get isCompleted => checkIn != null && checkOut != null;

  String get durationText {
    if (duration == null) return '--';
    final h = duration!.inHours;
    final m = duration!.inMinutes.remainder(60);
    return '${h}h ${m}m';
  }
}

class AttendanceSummary {
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final double attendanceRate;

  AttendanceSummary({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.attendanceRate,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> j) =>
      AttendanceSummary(
        totalDays: j['totalDays'] ?? 0,
        presentDays: j['presentDays'] ?? 0,
        absentDays: j['absentDays'] ?? 0,
        lateDays: j['lateDays'] ?? 0,
        attendanceRate: ((j['attendanceRate'] ?? 0) as num).toDouble(),
      );
}
