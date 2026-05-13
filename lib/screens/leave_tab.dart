import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/hrms_provider.dart';
import '../core/theme.dart';

class LeaveTab extends StatefulWidget {
  const LeaveTab({super.key});

  @override
  State<LeaveTab> createState() => _LeaveTabState();
}

class _LeaveTabState extends State<LeaveTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HRMSProvider>().fetchMyLeaves();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hrms = context.watch<HRMSProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Leaves', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showApplyLeaveDialog(context),
          ),
        ],
      ),
      body: hrms.myLeaves.isEmpty
          ? const Center(child: Text('No leave requests found'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: hrms.myLeaves.length,
              itemBuilder: (context, index) {
                final leave = hrms.myLeaves[index];
                return Card(
                  child: ListTile(
                    title: Text(leave.leaveType, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${DateFormat('MMM dd').format(leave.startDate)} - ${DateFormat('MMM dd, yyyy').format(leave.endDate)}'),
                    trailing: _buildStatusChip(leave.status),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved': color = Colors.green; break;
      case 'pending': color = Colors.orange; break;
      case 'rejected': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  void _showApplyLeaveDialog(BuildContext context) {
    // Implementation for applying leave
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Apply for Leave', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            // Add form fields here
            Text('Form fields will be added here'),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
