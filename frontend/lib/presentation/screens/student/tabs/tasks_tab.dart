import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/student_provider.dart';

class TasksTab extends StatelessWidget {
  const TasksTab({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    if (provider.tasks.isEmpty) return const Center(child: Text('No daily tasks found.'));
    return ListView.builder(
      itemCount: provider.tasks.length,
      itemBuilder: (context, index) {
        final task = provider.tasks[index];
        final isCompleted = task['status'] == 'COMPLETED';
        return CheckboxListTile(
          title: Text(task['title'] ?? ''),
          subtitle: Text(task['description'] ?? ''),
          value: isCompleted,
          onChanged: (val) {
             if (val != null) provider.updateTaskStatus(task['id'], val ? 'COMPLETED' : 'PENDING');
          },
        );
      },
    );
  }
}
