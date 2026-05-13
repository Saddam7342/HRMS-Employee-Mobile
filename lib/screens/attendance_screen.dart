import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/attendance_provider.dart';
import '../models/attendance_model.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AttendanceProvider>();
      p.fetchToday();
      p.fetchHistory();
      p.fetchSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final att = context.watch<AttendanceProvider>();
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          await att.fetchToday();
          await att.fetchHistory();
          await att.fetchSummary();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 0,
              backgroundColor: AppTheme.primary,
              title: const Text('Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              automaticallyImplyLeading: false,
            ),
            SliverToBoxAdapter(child: _buildSummaryCards(att.summary)),
            SliverToBoxAdapter(child: _buildTodayCard(context, att)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: const Text('Recent History',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              ),
            ),
            if (att.history.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('No attendance records', style: TextStyle(color: AppTheme.textMuted))),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildHistoryItem(att.history[i]),
                  childCount: att.history.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(AttendanceSummary? s) {
    return Container(
      color: AppTheme.primary,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Row(
        children: [
          _summaryChip('Present', '${s?.presentDays ?? 0}', Colors.white),
          const SizedBox(width: 8),
          _summaryChip('Absent', '${s?.absentDays ?? 0}', Colors.white70),
          const SizedBox(width: 8),
          _summaryChip('Late', '${s?.lateDays ?? 0}', Colors.white60),
          const SizedBox(width: 8),
          _summaryChip('Rate', '${s?.attendanceRate.toStringAsFixed(0) ?? 0}%', Colors.white),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayCard(BuildContext ctx, AttendanceProvider att) {
    final today = att.today;
    final isIn = today?.isCheckedIn ?? false;
    final isDone = today?.isCompleted ?? false;
    final fmt = DateFormat('hh:mm a');
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text("Today", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                const Spacer(),
                _statusBadge(isDone ? 'Completed' : isIn ? 'Active' : 'Not Started'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _infoBox(Icons.login_rounded, 'Clock In', today?.checkIn != null ? fmt.format(today!.checkIn!) : '--:--', AppTheme.accent)),
                const SizedBox(width: 12),
                Expanded(child: _infoBox(Icons.logout_rounded, 'Clock Out', today?.checkOut != null ? fmt.format(today!.checkOut!) : '--:--', AppTheme.danger)),
                const SizedBox(width: 12),
                Expanded(child: _infoBox(Icons.schedule_rounded, 'Duration', today?.durationText ?? '--', AppTheme.primary)),
              ],
            ),
            const SizedBox(height: 16),
            if (!isDone)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: att.isLoading ? null : () async {
                    final err = isIn ? await att.checkOut() : await att.checkIn();
                    if (err != null && ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(err), backgroundColor: AppTheme.danger));
                    }
                  },
                  icon: Icon(isIn ? Icons.logout_rounded : Icons.login_rounded),
                  label: Text(isIn ? 'Clock Out' : 'Clock In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isIn ? AppTheme.danger : AppTheme.accent,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color c = status == 'Completed' ? AppTheme.accent : status == 'Active' ? AppTheme.primary : AppTheme.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildHistoryItem(AttendanceRecord r) {
    final fmt = DateFormat('hh:mm a');
    final dateFmt = DateFormat('EEE, dd MMM');
    Color statusColor = r.status.toLowerCase() == 'present' ? AppTheme.accent : r.status.toLowerCase() == 'absent' ? AppTheme.danger : AppTheme.warning;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.calendar_today_rounded, color: statusColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateFmt.format(r.date), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  r.checkIn != null ? '${fmt.format(r.checkIn!)} → ${r.checkOut != null ? fmt.format(r.checkOut!) : "Active"}' : 'No record',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(r.status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              Text(r.durationText, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
