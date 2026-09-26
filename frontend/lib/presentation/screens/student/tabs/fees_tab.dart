import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/student_provider.dart';

class FeesTab extends StatelessWidget {
  const FeesTab({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    if (provider.fees.isEmpty) return const Center(child: Text('No fee records found.'));
    return ListView.builder(
      itemCount: provider.fees.length,
      itemBuilder: (context, index) {
        final fee = provider.fees[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: const Icon(Icons.payment, color: Colors.blue),
            title: Text(fee['feeName'] ?? ''),
            subtitle: Text('Due: \$${fee['totalAmount']} - Status: ${fee['status']}'),
          ),
        );
      },
    );
  }
}
