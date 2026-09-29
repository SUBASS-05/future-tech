import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/student_provider.dart';
import '../../../widgets/components.dart';
import '../../../../core/theme/design_system.dart';

class FeesTab extends StatelessWidget {
  const FeesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();

    if (provider.isLoading) {
      return const Center(child: FTLoading());
    }

    if (provider.fees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 64, color: FTColors.textSecondary),
            const SizedBox(height: FTSpacing.md),
            Text('No fee records found.', style: FTTypography.bodyLarge.copyWith(color: FTColors.textSecondary)),
          ],
        ),
      );
    }

    double totalFee = 0;
    double paidFee = 0;
    for (var fee in provider.fees) {
      double amount = double.tryParse(fee['totalAmount']?.toString() ?? '0') ?? 0;
      totalFee += amount;
      if (fee['status'] == 'PAID') {
        paidFee += amount;
      }
    }
    double dueFee = totalFee - paidFee;

    return ListView(
      padding: const EdgeInsets.all(FTSpacing.md),
      children: [
        FTCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fee Summary', style: FTTypography.heading3),
              const SizedBox(height: FTSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat('Total', '₹${totalFee.toStringAsFixed(0)}'),
                  _buildStat('Paid', '₹${paidFee.toStringAsFixed(0)}'),
                  _buildStat('Due', '₹${dueFee.toStringAsFixed(0)}', color: dueFee > 0 ? FTColors.warning : FTColors.textPrimary),
                ],
              ),
              FTProgressIndicator(
                value: totalFee > 0 ? paidFee / totalFee : 0,
                color: FTColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: FTSpacing.xl),
        Text('Payment History', style: FTTypography.heading3),
        const SizedBox(height: FTSpacing.sm),
        ...provider.fees.map((fee) {
          final isPaid = fee['status'] == 'PAID';
          return Padding(
            padding: const EdgeInsets.only(bottom: FTSpacing.sm),
            child: FTCard(
              padding: const EdgeInsets.all(FTSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(FTSpacing.xs),
                    decoration: BoxDecoration(
                      color: isPaid ? FTColors.primaryLight : FTColors.secondaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.payment,
                      color: isPaid ? FTColors.primary : FTColors.secondary,
                    ),
                  ),
                  const SizedBox(width: FTSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fee['feeName'] ?? 'Fee Payment', style: FTTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: FTSpacing.xxs),
                        Text('Amount: ₹${fee['totalAmount']}', style: FTTypography.bodySmall),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        fee['status'] ?? '',
                        style: FTTypography.label.copyWith(
                          color: isPaid ? FTColors.success : FTColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FTTypography.bodySmall),
        const SizedBox(height: FTSpacing.xxs),
        Text(value, style: FTTypography.bodyLarge.copyWith(color: color ?? FTColors.textPrimary, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
