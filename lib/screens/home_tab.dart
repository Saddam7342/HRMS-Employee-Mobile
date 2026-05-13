import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/hrms_provider.dart';
import '../core/theme.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final hrms = context.watch<HRMSProvider>();
    final today = hrms.todayAttendance;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            title: Text(
              'Hi, ${user?.firstName ?? "Employee"}',
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAttendanceCard(context, today, hrms),
                const SizedBox(height: 24),
                Text('Quick Actions', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                _buildQuickActions(context),
                const SizedBox(height: 24),
                Text('Leave Balances', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                _buildLeaveBalances(hrms.balances),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(BuildContext context, dynamic today, HRMSProvider hrms) {
    final isCheckedIn = today?.checkIn != null && today?.checkOut == null;
    final timeFormat = DateFormat('hh:mm a');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today\'s Attendance', style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      today?.checkIn != null ? timeFormat.format(today.checkIn!) : '--:--',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
                Icon(
                  isCheckedIn ? Icons.check_circle : Icons.timer,
                  color: isCheckedIn ? Colors.green : Colors.grey,
                  size: 40,
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: hrms.isLoading
                  ? null
                  : () {
                      if (isCheckedIn) {
                        hrms.checkOut();
                      } else {
                        hrms.checkIn();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isCheckedIn ? Colors.red.shade400 : AppTheme.primaryColor,
              ),
              child: Text(isCheckedIn ? 'Clock Out' : 'Clock In'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _actionItem(context, Icons.calendar_today, 'Request Leave', Colors.orange),
        _actionItem(context, Icons.receipt_long, 'My Expenses', Colors.blue),
        _actionItem(context, Icons.flight, 'Travel Request', Colors.teal),
        _actionItem(context, Icons.description, 'Payslips', Colors.purple),
      ],
    );
  }

  Widget _actionItem(BuildContext context, IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveBalances(List<dynamic> balances) {
    if (balances.isEmpty) return const Text('No balances available');
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: balances.length,
        itemBuilder: (context, index) {
          final balance = balances[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(balance.leaveType, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text('${balance.remaining}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                const Text('Days Left', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
              ],
            ),
          );
        },
      ),
    );
  }
}
