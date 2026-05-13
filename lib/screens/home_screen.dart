import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/leave_provider.dart';
import '../providers/notification_provider.dart';
import '../models/attendance_model.dart';
import '../models/leave_model.dart';
import 'notifications_screen.dart';
import '../providers/navigation_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().fetchToday();
      context.read<LeaveProvider>().fetchBalances();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final att = context.watch<AttendanceProvider>();
    final leave = context.watch<LeaveProvider>();
    final notif = context.watch<NotificationProvider>();
    final profile = auth.profile;
    final today = att.today;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          await Future.wait([
            context.read<AttendanceProvider>().fetchToday(),
            context.read<LeaveProvider>().fetchBalances(),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(context, profile?.fullName ?? auth.user?.email ?? 'Employee', notif.unreadCount),
            ),
            SliverToBoxAdapter(child: _buildAttendanceCard(context, today, att)),
            SliverToBoxAdapter(child: _buildStatsRow(context, leave.balances, today)),
            SliverToBoxAdapter(child: _buildQuickActions(context)),
            SliverToBoxAdapter(child: _buildLeaveBalances(context, leave.balances)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext ctx, String name, int unread) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$greeting 👋',
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(ctx,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                ),
              ),
              if (unread > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: AppTheme.danger, shape: BoxShape.circle),
                    child: Text('$unread',
                        style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(
      BuildContext ctx, AttendanceRecord? today, AttendanceProvider att) {
    final isIn = today?.isCheckedIn ?? false;
    final isDone = today?.isCompleted ?? false;
    final fmt = DateFormat('hh:mm a');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: isDone
              ? AppTheme.successGradient
              : isIn
                  ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)])
                  : AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Today's Attendance",
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        isDone
                            ? 'Work Complete'
                            : isIn
                                ? 'You\'re Clocked In'
                                : 'Not Clocked In',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDone
                        ? Icons.check_circle_outline
                        : isIn
                            ? Icons.timer
                            : Icons.timer_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _timeBox('Check In', today?.checkIn != null ? fmt.format(today!.checkIn!) : '--:--'),
                const SizedBox(width: 12),
                _timeBox('Check Out', today?.checkOut != null ? fmt.format(today!.checkOut!) : '--:--'),
                const SizedBox(width: 12),
                _timeBox('Duration', today?.durationText ?? '--'),
              ],
            ),
            const SizedBox(height: 20),
            if (!isDone)
              GestureDetector(
                onTap: att.isLoading
                    ? null
                    : () async {
                        final err = isIn
                            ? await att.checkOut()
                            : await att.checkIn();
                        if (err != null && ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text(err),
                            backgroundColor: AppTheme.danger,
                          ));
                        }
                      },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: att.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                      : Text(
                          isIn ? '  Clock Out' : '  Clock In',
                          style: TextStyle(
                            color: isIn ? AppTheme.danger : AppTheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _timeBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
      BuildContext ctx, List<LeaveBalance> balances, AttendanceRecord? today) {
    final totalRemaining = balances.fold<double>(0, (s, b) => s + b.remaining);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _statCard('Leave Days', '${totalRemaining.toInt()}', Icons.event_note_rounded,
              AppTheme.warning, 'Remaining'),
          const SizedBox(width: 12),
          _statCard('Status', today?.status ?? 'N/A', Icons.radio_button_checked,
              today?.isCheckedIn == true ? AppTheme.accent : AppTheme.textMuted, 'Today'),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext ctx) {
    final nav = ctx.read<NavigationProvider>();
    final actions = [
      {
        'label': 'Apply Leave',
        'icon': Icons.beach_access_rounded,
        'color': const Color(0xFFF59E0B),
        'onTap': () => nav.setIndex(2)
      },
      {
        'label': 'Attendance',
        'icon': Icons.timer_rounded,
        'color': const Color(0xFF10B981),
        'onTap': () => nav.setIndex(1)
      },
      {
        'label': 'Expenses',
        'icon': Icons.receipt_long_rounded,
        'color': const Color(0xFF3B82F6),
        'onTap': () {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('Expenses feature coming soon!')),
          );
        }
      },
      {
        'label': 'Profile',
        'icon': Icons.person_rounded,
        'color': const Color(0xFF8B5CF6),
        'onTap': () => nav.setIndex(3)
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final a = actions[index];
              final color = a['color'] as Color;
              return GestureDetector(
                onTap: a['onTap'] as VoidCallback,
                child: Column(
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
                      ),
                      child: Icon(a['icon'] as IconData, color: color, size: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      a['label'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveBalances(BuildContext ctx, List<LeaveBalance> balances) {
    if (balances.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Leave Balances',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: balances.length,
              itemBuilder: (_, i) {
                final b = balances[i];
                final pct = b.total > 0 ? b.remaining / b.total : 0.0;
                final colors = [AppTheme.primary, AppTheme.accent, AppTheme.warning, AppTheme.secondary];
                final c = colors[i % colors.length];
                return Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(b.remaining.toInt().toString(),
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: c)),
                          Text('/${b.total.toInt()}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(b.leaveType,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.0, 1.0),
                          backgroundColor: c.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(c),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
