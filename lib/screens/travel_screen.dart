import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../providers/travel_provider.dart';
import '../models/travel_model.dart';

class TravelScreen extends StatefulWidget {
  const TravelScreen({super.key});

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TravelProvider>().fetchMyRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                'My Travel Requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ),
          ),
          _buildTravelList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTravelModal(context),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.flight_takeoff_rounded, color: Colors.white),
        label: const Text('Book Travel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Travel Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        background: Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient)),
      ),
    );
  }

  Widget _buildTravelList() {
    final trv = context.watch<TravelProvider>();
    if (trv.isLoading && trv.myRequests.isEmpty) {
      return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
    }
    if (trv.myRequests.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flight_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('No travel requests', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildTravelItem(context, trv.myRequests[index]),
          childCount: trv.myRequests.length,
        ),
      ),
    );
  }

  Widget _buildTravelItem(BuildContext context, TravelRequest trip) {
    final dateFmt = DateFormat('MMM dd, yyyy');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        trip.destination,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
                      ),
                    ),
                    _buildStatusChip(trip.status),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _infoBadge(Icons.calendar_month_rounded, dateFmt.format(trip.fromDate)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 8),
                    _infoBadge(Icons.calendar_month_rounded, dateFmt.format(trip.toDate)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.primary.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trip.purpose,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (trip.estimatedBudget != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${trip.estimatedBudget!.toInt()} PKR',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved': color = AppTheme.accent; break;
      case 'rejected': color = AppTheme.danger; break;
      case 'cancelled': color = Colors.grey; break;
      default: color = AppTheme.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  void _showAddTravelModal(BuildContext context) {
    final trv = context.read<TravelProvider>();
    DateTime fromDate = DateTime.now().add(const Duration(days: 7));
    DateTime toDate = DateTime.now().add(const Duration(days: 10));
    final destCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              const Text('Request Travel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _textField('DESTINATION', destCtrl, hint: 'City, Country'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _dateInput('FROM', fromDate, () async {
                      final d = await showDatePicker(context: context, initialDate: fromDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (d != null) setModalState(() => fromDate = d);
                    }),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _dateInput('TO', toDate, () async {
                      final d = await showDatePicker(context: context, initialDate: toDate, firstDate: fromDate, lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (d != null) setModalState(() => toDate = d);
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _textField('PURPOSE OF TRIP', purposeCtrl, hint: 'Client Meeting, Training, etc.'),
              const SizedBox(height: 20),
              _textField('ESTIMATED BUDGET (PKR)', budgetCtrl, hint: '0.00', keyboard: TextInputType.number),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: trv.isLoading ? null : () async {
                    if (destCtrl.text.isEmpty || purposeCtrl.text.isEmpty) return;
                    final err = await trv.submitRequest(
                      destination: destCtrl.text,
                      purpose: purposeCtrl.text,
                      fromDate: fromDate,
                      toDate: toDate,
                      estimatedBudget: double.tryParse(budgetCtrl.text),
                    );
                    if (err == null && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted!'), backgroundColor: AppTheme.accent, behavior: SnackBarBehavior.floating));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                  child: trv.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateInput(String label, DateTime date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Text(DateFormat('MMM dd, yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _textField(String label, TextEditingController ctrl, {String? hint, TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
        ),
      ],
    );
  }
}
