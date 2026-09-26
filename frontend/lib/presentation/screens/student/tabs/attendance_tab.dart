import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/student_provider.dart';

class AttendanceTab extends StatelessWidget {
  const AttendanceTab({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    if (provider.attendance.isEmpty) return const Center(child: Text('No attendance records.'));
    return ListView.builder(
      itemCount: provider.attendance.length,
      itemBuilder: (context, index) {
        final att = provider.attendance[index];
        final isPresent = att['status'] == 'PRESENT';
        return ListTile(
          leading: Icon(isPresent ? Icons.check_circle : Icons.cancel, color: isPresent ? Colors.green : Colors.red),
          title: Text('Date: ${att['attendanceDate']}'),
          subtitle: Text('Status: ${att['status']}'),
        );
      },
    );
  }
}
