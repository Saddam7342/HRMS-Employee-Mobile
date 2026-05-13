/// Calendar date as yyyy-MM-dd for the leave API (avoids timezone shifting the day).
String toLeaveApiDateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
