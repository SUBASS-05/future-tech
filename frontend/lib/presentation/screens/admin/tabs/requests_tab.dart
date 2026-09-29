import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/admin_provider.dart';
import '../../../widgets/components.dart';
import '../../../../core/theme/design_system.dart';

class RequestsTab extends StatefulWidget {
  const RequestsTab({super.key});

  @override
  State<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchPendingRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    if (adminProvider.isLoading) {
      return const Center(
        child: FTLoading(),
      );
    }

    if (adminProvider.pendingRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: FTColors.textSecondary),
            const SizedBox(height: FTSpacing.md),
            Text('No pending requests', style: FTTypography.bodyLarge.copyWith(color: FTColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(FTSpacing.md),
      itemCount: adminProvider.pendingRequests.length,
      itemBuilder: (context, index) {
        final req = adminProvider.pendingRequests[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: FTSpacing.md),
          child: FTCard(
            padding: const EdgeInsets.all(FTSpacing.sm),
            child: Row(
              children: [
                const FTAvatar(
                  fallbackIcon: Icon(Icons.person, color: FTColors.primary),
                ),
                const SizedBox(width: FTSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req['fullName'] ?? 'Unknown',
                        style: FTTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: FTSpacing.xxs),
                      Text(
                        '${req['email']}\n${req['institutionName'] ?? 'No Institution'}',
                        style: FTTypography.bodySmall,
                      ),
                      const SizedBox(height: FTSpacing.xxs),
                      Text(
                        'Requested: ${req['tuitionJoiningDate']?.substring(0, 10) ?? 'N/A'}',
                        style: FTTypography.caption,
                      )
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: FTColors.success),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => FTDialog(
                            title: 'Approve Student?',
                            content: Text('Are you sure you want to approve ${req['fullName']}?', style: FTTypography.body),
                            actions: [
                              FTButton(onPressed: () => Navigator.pop(ctx, false), text: 'Cancel', isSecondary: true),
                              FTButton(onPressed: () => Navigator.pop(ctx, true), text: 'Approve'),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          adminProvider.approveStudent(req['studentId']);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: FTColors.error),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => FTDialog(
                            title: 'Reject Student?',
                            content: Text('Are you sure you want to reject ${req['fullName']}?', style: FTTypography.body),
                            actions: [
                              FTButton(onPressed: () => Navigator.pop(ctx, false), text: 'Cancel', isSecondary: true),
                              FTButton(onPressed: () => Navigator.pop(ctx, true), text: 'Reject', isDestructive: true),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          adminProvider.rejectStudent(req['studentId']);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
