import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/admin_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/theme/design_system.dart';
import '../../../widgets/components.dart';

class AdminManagementTab extends StatefulWidget {
  const AdminManagementTab({super.key});

  @override
  State<AdminManagementTab> createState() => _AdminManagementTabState();
}

class _AdminManagementTabState extends State<AdminManagementTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<AdminProvider>();
      await provider.fetchAdminManagementData();
      if (provider.error == 'Session expired or suspended.' && mounted) {
        context.read<AuthProvider>().logout();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: FTColors.surface)),
        backgroundColor: FTColors.error,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: FTColors.success,
      ),
    );
  }

  Future<void> _approveAdmin(String adminId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Admin?'),
        content: const Text('Are you sure you want to approve this admin? They will have access to manage students and tasks.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FTButton(text: 'Approve', onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<AdminProvider>().approveAdmin(adminId);
      if (success) {
        _showSuccess('Admin approved successfully');
      } else {
        _showError(context.read<AdminProvider>().error ?? 'Failed to approve');
      }
    }
  }

  Widget _buildAdminCard(dynamic admin, List<Widget> actions) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: FTSpacing.md, vertical: FTSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: FTColors.secondary,
          child: Text(admin['firstName']?[0] ?? 'A', style: const TextStyle(color: FTColors.surface)),
        ),
        title: Text('${admin['firstName']} ${admin['lastName']}'),
        subtitle: Text('${admin['adminId'] ?? ''}\n${admin['email']}'),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: actions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    if (provider.isProfileLoading && provider.pendingAdmins.isEmpty && provider.activeAdmins.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final capacity = provider.capacity;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(FTSpacing.md),
          child: FTCard(
            padding: const EdgeInsets.all(FTSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCapacityStat('Active', '${capacity['activeAdmins']}', Icons.check_circle, FTColors.success),
                _buildCapacityStat('Slots', '${capacity['availableSlots']}', Icons.event_seat, FTColors.primary),
                _buildCapacityStat('Pending', '${capacity['pendingRequests']}', Icons.pending, FTColors.warning),
              ],
            ),
          ),
        ),
        TabBar(
          controller: _tabController,
          labelColor: FTColors.primary,
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'Suspended'),
            Tab(text: 'Rejected'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildList(provider.pendingAdmins, (admin) => [
                IconButton(
                  icon: const Icon(Icons.check, color: FTColors.success),
                  onPressed: () => _approveAdmin(admin['id'].toString()),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: FTColors.error),
                  onPressed: () async {
                    final success = await provider.rejectAdmin(admin['id'].toString());
                    if (success) _showSuccess('Admin rejected');
                    else _showError(provider.error ?? 'Failed to reject');
                  },
                ),
              ]),
              _buildList(provider.activeAdmins, (admin) => [
                IconButton(
                  icon: const Icon(Icons.visibility, color: FTColors.primary),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Padding(
                        padding: const EdgeInsets.all(FTSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Admin Profile', style: FTTypography.heading2),
                            const Divider(),
                            Text('Name: ${admin['firstName']} ${admin['lastName']}'),
                            Text('Admin ID: ${admin['adminId']}'),
                            Text('Email: ${admin['email']}'),
                            Text('Phone: ${admin['phone'] ?? 'N/A'}'),
                            Text('Joined: ${admin['joiningDate'] ?? 'N/A'}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.pause, color: FTColors.warning),
                  onPressed: () async {
                    final success = await provider.suspendAdmin(admin['id'].toString());
                    if (success) _showSuccess('Admin suspended');
                    else _showError(provider.error ?? 'Failed to suspend');
                  },
                ),
              ]),
              _buildList(provider.suspendedAdmins, (admin) => [
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: FTColors.success),
                  onPressed: () async {
                    final success = await provider.activateAdmin(admin['id'].toString());
                    if (success) _showSuccess('Admin activated');
                    else _showError(provider.error ?? 'Failed to activate');
                  },
                ),
              ]),
              _buildList(provider.rejectedAdmins, (admin) => []),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<dynamic> admins, List<Widget> Function(dynamic admin) actionsBuilder) {
    if (admins.isEmpty) {
      return const Center(child: Text('No records found.'));
    }
    return ListView.builder(
      itemCount: admins.length,
      itemBuilder: (context, index) {
        final admin = admins[index];
        return _buildAdminCard(admin, actionsBuilder(admin));
      },
    );
  }

  Widget _buildCapacityStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: FTSpacing.xs),
        Text(value, style: FTTypography.heading2),
        Text(label, style: FTTypography.caption),
      ],
    );
  }
}
