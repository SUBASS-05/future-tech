import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/admin_provider.dart';

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
      return const Center(child: CircularProgressIndicator());
    }

    if (adminProvider.pendingRequests.isEmpty) {
      return const Center(child: Text('No pending requests.'));
    }

    return ListView.builder(
      itemCount: adminProvider.pendingRequests.length,
      itemBuilder: (context, index) {
        final req = adminProvider.pendingRequests[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(req['fullName'] ?? 'Unknown'),
            subtitle: Text('${req['email']} - ${req['institutionName'] ?? 'No Institution'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => adminProvider.approveStudent(req['studentId']),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => adminProvider.rejectStudent(req['studentId']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
