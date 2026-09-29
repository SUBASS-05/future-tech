import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/student_provider.dart';
import '../../../widgets/components.dart';
import '../../../../core/theme/design_system.dart';

class AttendanceTab extends StatelessWidget {
  const AttendanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();

    if (provider.isLoading) {
      return const Center(child: FTLoading());
    }

    if (provider.attendance.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 64, color: FTColors.textSecondary),
            const SizedBox(height: FTSpacing.md),
            Text('No attendance records.', style: FTTypography.bodyLarge.copyWith(color: FTColors.textSecondary)),
          ],
        ),
      );
    }

    int presentCount = provider.attendance.where((a) => a['status'] == 'PRESENT').length;
    int totalCount = provider.attendance.length;
    double percentage = totalCount > 0 ? (presentCount / totalCount) * 100 : 0;

    return ListView(
      padding: const EdgeInsets.all(FTSpacing.md),
      children: [
        FTCard(
          child: Column(
            children: [
              Text('Attendance', style: FTTypography.heading3),
              const SizedBox(height: FTSpacing.sm),
              Text('${percentage.toStringAsFixed(0)}%', style: FTTypography.display.copyWith(color: FTColors.primary)),
              const SizedBox(height: FTSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat('Present', presentCount.toString(), FTColors.success),
                  _buildStat('Absent', (totalCount - presentCount).toString(), FTColors.error),
                  _buildStat('Total', totalCount.toString(), FTColors.textPrimary),
                ],
              ),
              FTProgressIndicator(
                value: totalCount > 0 ? presentCount / totalCount : 0,
                color: FTColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: FTSpacing.xl),
        Text('Recent Records', style: FTTypography.heading3),
        const SizedBox(height: FTSpacing.sm),
        ...provider.attendance.map((att) {
          final isPresent = att['status'] == 'PRESENT';
          return Padding(
            padding: const EdgeInsets.only(bottom: FTSpacing.sm),
            child: FTCard(
              padding: const EdgeInsets.symmetric(vertical: FTSpacing.md, horizontal: FTSpacing.md),
              child: Row(
                children: [
                  Icon(
                    isPresent ? Icons.check_circle : Icons.cancel,
                    color: isPresent ? FTColors.success : FTColors.error,
                  ),
                  const SizedBox(width: FTSpacing.md),
                  Expanded(
                    child: Text(
                      'Date: ${att['attendanceDate']}',
                      style: FTTypography.bodyLarge,
                    ),
                  ),
                  Text(
                    att['status'] ?? '',
                    style: FTTypography.button.copyWith(color: isPresent ? FTColors.success : FTColors.error),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: FTTypography.bodySmall),
        const SizedBox(height: FTSpacing.xxs),
        Text(value, style: FTTypography.heading3.copyWith(color: color)),
      ],
    );
  }
}
