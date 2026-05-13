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
    final ci = j['checkIn'] != null ? DateTime.tryParse(j['checkIn']) : null;
    final co = j['checkOut'] != null ? DateTime.tryParse(j['checkOut']) : null;
    Duration? dur;
    if (ci != null && co != null) {
      dur = co.difference(ci);
    }
    return AttendanceRecord(
      id: j['id'] ?? '',
      date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
      checkIn: ci,
      checkOut: co,
      status: j['status'] ?? 'Unknown',
      notes: j['notes'],
      duration: dur,
    );
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
