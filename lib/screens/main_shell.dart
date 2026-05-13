import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/attendance_provider.dart';
import '../providers/leave_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/notification_provider.dart';
import 'home_screen.dart';
import 'attendance_screen.dart';
import 'leave_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    AttendanceScreen(),
    LeaveScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  Future<void> _loadInitialData() async {
    final att = context.read<AttendanceProvider>();
    final lv = context.read<LeaveProvider>();
    final notif = context.read<NotificationProvider>();
    final exp = context.read<ExpenseProvider>();
    await Future.wait([
      att.fetchToday(),
      lv.fetchBalances(),
      notif.fetchUnreadCount(),
      exp.fetchCategories(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                _navItem(1, Icons.timer_rounded, Icons.timer_outlined, 'Attendance'),
                _navItem(2, Icons.event_note_rounded, Icons.event_note_outlined, 'Leave'),
                _navItem(3, Icons.person_rounded, Icons.person_outline, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == idx;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = idx),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? AppTheme.primary : AppTheme.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppTheme.primary : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
