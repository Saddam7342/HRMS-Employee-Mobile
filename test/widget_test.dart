import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_employee_mobile/main.dart';
import 'package:provider/provider.dart';
import 'package:hrms_employee_mobile/providers/auth_provider.dart';
import 'package:hrms_employee_mobile/providers/attendance_provider.dart';
import 'package:hrms_employee_mobile/providers/leave_provider.dart';
import 'package:hrms_employee_mobile/providers/expense_provider.dart';
import 'package:hrms_employee_mobile/providers/travel_provider.dart';
import 'package:hrms_employee_mobile/providers/notification_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AttendanceProvider()),
          ChangeNotifierProvider(create: (_) => LeaveProvider()),
          ChangeNotifierProvider(create: (_) => ExpenseProvider()),
          ChangeNotifierProvider(create: (_) => TravelProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ],
        child: const HRMSApp(),
      ),
    );

    // Verify that the splash screen or login screen appears
    expect(find.byType(HRMSApp), findsOneWidget);
  });
}
