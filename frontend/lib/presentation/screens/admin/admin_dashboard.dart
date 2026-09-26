import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          )
        ],
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : adminProvider.pendingRequests.isEmpty
              ? const Center(child: Text('No pending requests.'))
              : ListView.builder(
                  itemCount: adminProvider.pendingRequests.length,
                  itemBuilder: (context, index) {
                    final req = adminProvider.pendingRequests[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(req['fullName'] ?? 'Unknown'),
                        subtitle: Text('${req['email']} - ${req['institutionName']}'),
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
                ),
    );
  }
}
