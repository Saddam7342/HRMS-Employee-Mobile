import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_employee_mobile/core/leave_api_dates.dart';

void main() {
  test('toLeaveApiDateOnly formats calendar date', () {
    expect(toLeaveApiDateOnly(DateTime(2026, 5, 13)), '2026-05-13');
    expect(toLeaveApiDateOnly(DateTime(2026, 1, 2)), '2026-01-02');
  });
}
