import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/design_system.dart';
import 'tabs/requests_tab.dart';
import 'tabs/tasks_tab.dart';
import 'tabs/admin_management_tab.dart';
import 'tabs/admin_profile_tab.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isTopAdmin = authProvider.role == 'TOP_ADMIN';
    final isProfileCompleted = authProvider.isProfileCompleted;

    // Define tabs and their corresponding navigation items dynamically based on role
    final List<Widget> tabs = [];
    final List<BottomNavigationBarItem> navItems = [];

    // Common Tabs
    tabs.add(const RequestsTab());
    navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Students'));

    tabs.add(const TasksTab());
    navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tasks'));

    tabs.add(const Center(child: Text('Attendance - Coming Soon')));
    navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Attendance'));

    // Top Admin Only Tabs
    if (isTopAdmin) {
      tabs.add(const Center(child: Text('Fees Management - Coming Soon')));
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Fees'));

      tabs.add(const AdminManagementTab());
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: 'Admins'));
    }

    // Profile Tab
    tabs.add(const AdminProfileTab());
    navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'));

    // Ensure _currentIndex is within bounds if role changes
    if (_currentIndex >= tabs.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const CircleAvatar(
                  backgroundColor: FTColors.secondary,
                  child: Icon(Icons.person, color: FTColors.surface),
                ),
                onPressed: () {
                  setState(() {
                    _currentIndex = tabs.length - 1; // Navigate to Profile Tab
                  });
                },
              ),
              if (!isProfileCompleted)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: FTColors.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: navItems,
        selectedItemColor: FTColors.primary,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
