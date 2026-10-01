import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/admin_provider.dart';
import '../../../widgets/components.dart';
import '../../../../core/theme/design_system.dart';

class AdminFeesTab extends StatefulWidget {
  const AdminFeesTab({super.key});

  @override
  State<AdminFeesTab> createState() => _AdminFeesTabState();
}

class _AdminFeesTabState extends State<AdminFeesTab> {
  String _selectedFilter = 'today'; // 'today', 'week', 'month'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    context.read<AdminProvider>().fetchAdminFeesSummary(
          filter: _selectedFilter,
          search: _searchController.text.trim(),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProofDialog(BuildContext context, Map<String, dynamic> payment) {
    final String proofUrl = payment['proofUrl'] ?? '';
    final String studentName = payment['studentName'] ?? 'Student';
    final String studentId = payment['studentId'] ?? '';
    final String amount = payment['amount']?.toString() ?? '0';
    final String date = payment['paymentDateFormatted'] ?? payment['paymentDate'] ?? '';
    final String time = payment['paymentTimeFormatted'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Payment Proof', style: FTTypography.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student: $studentName ($studentId)', style: FTTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Amount: ₹$amount', style: FTTypography.body.copyWith(color: FTColors.primary, fontWeight: FontWeight.bold)),
            Text('Date: $date ${time.isNotEmpty ? "• $time" : ""}', style: FTTypography.bodySmall.copyWith(color: FTColors.textSecondary)),
            const SizedBox(height: FTSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                proofUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Container(
                  padding: const EdgeInsets.all(FTSpacing.md),
                  color: Colors.grey.shade200,
                  child: const Row(
                    children: [
                      Icon(Icons.broken_image, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Screenshot proof image unavailable'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showStudentDetailsModal(BuildContext context, String studentId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: FTLoading()),
    );

    final details = await context.read<AdminProvider>().fetchAdminStudentFeeDetails(studentId);

    if (context.mounted) {
      Navigator.pop(context); // Dismiss loading dialog
      if (details == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load student fee details')),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          final String name = details['studentName'] ?? 'Student';
          final String sId = details['studentId'] ?? '';
          final String joiningDate = details['tuitionJoiningDate'] ?? '';
          final String cycleStart = details['feeCycleStart'] ?? '';
          final String cycleEnd = details['feeCycleEnd'] ?? '';
          final double annualFee = (details['annualFee'] as num?)?.toDouble() ?? 15000.0;
          final double paidAmount = (details['paidAmount'] as num?)?.toDouble() ?? 0.0;
          final double remainingAmount = (details['remainingAmount'] as num?)?.toDouble() ?? 0.0;
          final String statusStr = details['status'] ?? 'PENDING';
          final List history = details['payments'] ?? [];

          Color statusColor = FTColors.error;
          String statusLabel = 'PENDING';
          if (statusStr == 'PAID') {
            statusColor = FTColors.success;
            statusLabel = 'PAID';
          } else if (statusStr == 'PARTIALLY_PAID') {
            statusColor = FTColors.warning;
            statusLabel = 'PARTIALLY PAID';
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            padding: const EdgeInsets.all(FTSpacing.lg),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: FTSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: FTTypography.heading3),
                          Text('Student ID: $sId', style: FTTypography.bodySmall.copyWith(color: FTColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(statusLabel, style: FTTypography.label.copyWith(color: statusColor, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: FTSpacing.md),
                const Divider(),
                const SizedBox(height: FTSpacing.xs),
                if (joiningDate.isNotEmpty)
                  Text('Tuition Joining Date: $joiningDate', style: FTTypography.bodySmall),
                if (cycleStart.isNotEmpty && cycleEnd.isNotEmpty)
                  Text('Current Fee Cycle: $cycleStart – $cycleEnd', style: FTTypography.bodySmall),
                const SizedBox(height: FTSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard('Annual Fee', '₹${annualFee.toStringAsFixed(0)}'),
                    _buildStatCard('Total Paid', '₹${paidAmount.toStringAsFixed(0)}', color: FTColors.success),
                    _buildStatCard('Remaining', '₹${remainingAmount.toStringAsFixed(0)}', color: remainingAmount > 0 ? FTColors.warning : FTColors.textPrimary),
                  ],
                ),
                const SizedBox(height: FTSpacing.lg),
                Text('Payment History', style: FTTypography.heading3),
                const SizedBox(height: FTSpacing.sm),
                Expanded(
                  child: history.isEmpty
                      ? Center(
                          child: Text('No payments recorded for this student.',
                              style: FTTypography.body.copyWith(color: FTColors.textSecondary)),
                        )
                      : ListView.builder(
                          itemCount: history.length,
                          itemBuilder: (ctx, index) {
                            final p = history[index];
                            final String amt = p['amount']?.toString() ?? '0';
                            final String dt = p['paymentDateFormatted'] ?? p['paymentDate'] ?? '';
                            final String tm = p['paymentTimeFormatted'] ?? '';
                            final String proof = p['proofUrl'] ?? '';

                            return Card(
                              margin: const EdgeInsets.only(bottom: FTSpacing.sm),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: FTColors.primaryLight,
                                  child: Icon(Icons.payment, color: FTColors.primary),
                                ),
                                title: Text('₹$amt', style: FTTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                                subtitle: Text('$dt ${tm.isNotEmpty ? "• $tm" : ""}', style: FTTypography.bodySmall),
                                trailing: proof.isNotEmpty
                                    ? OutlinedButton(
                                        onPressed: () => _showProofDialog(context, p),
                                        child: const Text('View Proof'),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildStatCard(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FTTypography.bodySmall),
        const SizedBox(height: 2),
        Text(value, style: FTTypography.bodyLarge.copyWith(color: color ?? FTColors.textPrimary, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    if (provider.isFeesLoading && provider.adminFeesSummary == null) {
      return const Center(child: FTLoading());
    }

    if (provider.feesError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: FTColors.error),
            const SizedBox(height: FTSpacing.md),
            Text(
              provider.feesError!,
              style: FTTypography.bodyLarge.copyWith(color: FTColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: FTSpacing.md),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(backgroundColor: FTColors.primary),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final summary = provider.adminFeesSummary;
    final String filterTitle = summary?['filter'] ?? _selectedFilter.toUpperCase();
    final double totalCollected = (summary?['totalCollected'] as num?)?.toDouble() ?? 0.0;
    final int paymentCount = summary?['paymentCount'] ?? 0;
    final int studentsPaidCount = summary?['studentsPaidCount'] ?? 0;
    final List payments = summary?['payments'] ?? [];

    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: ListView(
        padding: const EdgeInsets.all(FTSpacing.md),
        children: [
          // Filter selector (Today, This Week, This Month)
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'today', label: Text('Today')),
              ButtonSegment(value: 'week', label: Text('This Week')),
              ButtonSegment(value: 'month', label: Text('This Month')),
            ],
            selected: {_selectedFilter},
            onSelectionChanged: (newSelection) {
              setState(() {
                _selectedFilter = newSelection.first;
              });
              _loadData();
            },
          ),
          const SizedBox(height: FTSpacing.md),
          // Search input
          TextField(
            controller: _searchController,
            onChanged: (_) => _loadData(),
            decoration: InputDecoration(
              hintText: 'Search student name or ID...',
              prefixIcon: const Icon(Icons.search, color: FTColors.primary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadData();
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: FTSpacing.md),
          // Summary cards
          FTCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(filterTitle, style: FTTypography.heading3.copyWith(color: FTColors.primary)),
                const SizedBox(height: FTSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard('Total Collected', '₹${totalCollected.toStringAsFixed(0)}', color: FTColors.success),
                    _buildStatCard('Payments', '$paymentCount'),
                    _buildStatCard('Students Paid', '$studentsPaidCount'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: FTSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Student Payments', style: FTTypography.heading3),
              Text('$paymentCount records', style: FTTypography.bodySmall.copyWith(color: FTColors.textSecondary)),
            ],
          ),
          const SizedBox(height: FTSpacing.sm),
          if (payments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(FTSpacing.xl),
                child: Column(
                  children: [
                    const Icon(Icons.inbox, size: 48, color: FTColors.textSecondary),
                    const SizedBox(height: FTSpacing.sm),
                    Text(
                      'No student payments recorded for this filter.',
                      style: FTTypography.body.copyWith(color: FTColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ...payments.map((p) {
              final String name = p['studentName'] ?? 'Student';
              final String studentId = p['studentId'] ?? '';
              final double amount = (p['amount'] as num?)?.toDouble() ?? 0.0;
              final String date = p['paymentDateFormatted'] ?? p['paymentDate'] ?? '';
              final String time = p['paymentTimeFormatted'] ?? '';
              final String proofUrl = p['proofUrl'] ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: FTSpacing.sm),
                child: FTCard(
                  padding: const EdgeInsets.all(FTSpacing.md),
                  child: InkWell(
                    onTap: () => _showStudentDetailsModal(context, studentId),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: FTTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    studentId,
                                    style: FTTypography.bodySmall.copyWith(color: FTColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${amount.toStringAsFixed(0)}',
                              style: FTTypography.heading3.copyWith(color: FTColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: FTSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$date ${time.isNotEmpty ? "• $time" : ""}',
                              style: FTTypography.bodySmall.copyWith(color: FTColors.textSecondary),
                            ),
                            if (proofUrl.isNotEmpty)
                              TextButton.icon(
                                onPressed: () => _showProofDialog(context, p),
                                icon: const Icon(Icons.image, size: 16),
                                label: const Text('View Proof'),
                                style: TextButton.styleFrom(
                                  foregroundColor: FTColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
