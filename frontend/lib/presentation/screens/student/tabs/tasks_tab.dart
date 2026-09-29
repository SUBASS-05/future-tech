import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/student_provider.dart';
import '../../../widgets/ft_card.dart';
import '../../../widgets/ft_button.dart';
import '../../../../core/utils/date_formatter.dart';
import 'dart:async';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().fetchTasks();
    });
    // Update countdowns every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _graceCountdown(DateTime expiresAt) {
    final now = DateTime.now().toUtc();
    final diff = expiresAt.toUtc().difference(now);
    if (diff.isNegative) return 'Expired';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '${hours}h ${minutes}m remaining';
  }
  
  Future<void> _updateStatus(int taskId, String status) async {
    final provider = context.read<StudentProvider>();
    final error = await provider.updateTaskStatus(taskId, status);
    if (mounted) {
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated successfully!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.contains('internet') ? 'Unable to update task. Please check your internet connection.' : error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final tasks = provider.tasks;

    if (provider.isLoading && tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF168A55)));
    }

    if (tasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("You're all caught up!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("No active tasks assigned to you.", style: TextStyle(color: Colors.grey)),
          ],
        )
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF168A55),
      onRefresh: () => provider.fetchTasks(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final item = tasks[index];
          final Map<String, dynamic> taskMap = item is Map<String, dynamic>
              ? (item['task'] is Map<String, dynamic> ? item['task'] : item)
              : {};
          
          final String title = taskMap['title'] ?? item['title'] ?? 'Task';
          final String? description = taskMap['description'] ?? item['description'];
          final String priority = taskMap['priority'] ?? item['priority'] ?? 'MEDIUM';
          final String status = item['status'] ?? 'PENDING';
          final dynamic taskIdRaw = item['taskId'] ?? item['id'] ?? taskMap['id'];
          final int? taskId = taskIdRaw != null ? int.tryParse(taskIdRaw.toString()) : null;
          final String? dueAtStr = item['dueAt'] ?? taskMap['dueAt'];
          final String? expiresAtStr = item['expiresAt'] ?? taskMap['expiresAt'];
          final String? startedAtStr = item['startedAt'] ?? taskMap['startedAt'];
          final dynamic estMinsRaw = item['estimatedMinutes'] ?? taskMap['estimatedMinutes'];
          final int? estMins = estMinsRaw != null ? int.tryParse(estMinsRaw.toString()) : null;

          // Check if estimated time lock applies
          bool isWorkTimerActive = false;
          String workTimeRemainingStr = '';
          if ((status == 'IN_PROGRESS' || status == 'OVERDUE') && startedAtStr != null && estMins != null && estMins > 0) {
            try {
              final startedAt = DateTime.parse(startedAtStr).toUtc();
              final minCompleteAt = startedAt.add(Duration(minutes: estMins));
              final now = DateTime.now().toUtc();
              if (now.isBefore(minCompleteAt)) {
                isWorkTimerActive = true;
                final diff = minCompleteAt.difference(now);
                final m = diff.inMinutes;
                final s = diff.inSeconds % 60;
                workTimeRemainingStr = '${m}m ${s.toString().padLeft(2, '0')}s';
              }
            } catch (_) {}
          }
          
          Color statusColor;
          IconData statusIcon;
          
          switch (status) {
            case 'COMPLETED':
              statusColor = Colors.green;
              statusIcon = Icons.check;
              break;
            case 'IN_PROGRESS':
              statusColor = Colors.orange;
              statusIcon = Icons.circle;
              break;
            case 'OVERDUE':
              statusColor = Colors.amber;
              statusIcon = Icons.warning_amber_rounded;
              break;
            case 'PENDING':
            default:
              statusColor = Colors.grey;
              statusIcon = Icons.radio_button_unchecked;
          }

          return FTCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: status == 'COMPLETED' ? TextDecoration.lineThrough : null,
                          color: status == 'COMPLETED' ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: priority == 'HIGH' ? Colors.red.withAlpha(30) : (priority == 'LOW' ? Colors.green.withAlpha(30) : Colors.orange.withAlpha(30)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: priority == 'HIGH' ? Colors.red.withAlpha(100) : (priority == 'LOW' ? Colors.green.withAlpha(100) : Colors.orange.withAlpha(100))),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(fontSize: 12, color: priority == 'HIGH' ? Colors.red : (priority == 'LOW' ? Colors.green : Colors.orange), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      status.replaceAll('_', ' '),
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                
                Text('Due: ${formatDateTime(dueAtStr)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                
                if (status == 'OVERDUE' && expiresAtStr != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Grace Period: ${_graceCountdown(DateTime.parse(expiresAtStr))}',
                    style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],

                if (isWorkTimerActive) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Estimated time remaining: $workTimeRemainingStr',
                        style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 16),
                if (status == 'PENDING' && taskId != null)
                  FTButton(
                    text: 'Start Task',
                    isLoading: provider.isLoading,
                    onPressed: () => _updateStatus(taskId, 'IN_PROGRESS'),
                  )
                else if ((status == 'IN_PROGRESS' || status == 'OVERDUE') && taskId != null)
                  isWorkTimerActive
                      ? OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Mark Complete ($workTimeRemainingStr left)',
                            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                          ),
                        )
                      : FTButton(
                          text: status == 'OVERDUE' ? 'Complete Now' : 'Mark Complete',
                          isLoading: provider.isLoading,
                          onPressed: () => _updateStatus(taskId, 'COMPLETED'),
                        )
                else if (status == 'COMPLETED')
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Completed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  )
              ],
            )
          );
        },
      ),
    );
  }
}
