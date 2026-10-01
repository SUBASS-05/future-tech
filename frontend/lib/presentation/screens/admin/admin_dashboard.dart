import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../core/theme/design_system.dart';
import '../../../core/api/api_service.dart';
import 'tabs/requests_tab.dart';
import 'tabs/tasks_tab.dart';
import 'tabs/admin_management_tab.dart';
import 'tabs/admin_profile_tab.dart';
import 'tabs/admin_fees_tab.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isTopAdmin = context.read<AuthProvider>().role == 'TOP_ADMIN';
      if (isTopAdmin) {
        context.read<AdminProvider>().fetchUnseenNotificationCount();
      }
      context.read<AdminProvider>().fetchProfile();
    });
  }

  String? _getFormattedPhotoUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    String url = rawUrl.trim();
    String baseHost = ApiService.baseUrl.replaceAll('/api', '');
    url = url.replaceAll('http://localhost:8080', baseHost)
             .replaceAll('http://127.0.0.1:8080', baseHost);
    if (url.startsWith('/uploads/')) {
      url = '$baseHost$url';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final adminProvider = context.watch<AdminProvider>();
    final isTopAdmin = authProvider.role == 'TOP_ADMIN';
    final isProfileCompleted = authProvider.isProfileCompleted && adminProvider.missingFields.isEmpty;
    final photoUrl = _getFormattedPhotoUrl(adminProvider.adminProfile?['profilePhotoUrl']);

    final List<Widget> tabs = [];
    final List<BottomNavigationBarItem> navItems = [];
    int? feesTabIndex;

    // Common Tabs
    tabs.add(const RequestsTab());
    navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Students'));

    tabs.add(const TasksTab());
    navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tasks'));

    tabs.add(const Center(child: Text('Attendance - Coming Soon')));
    navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Attendance'));

    // Top Admin Only Tabs
    if (isTopAdmin) {
      feesTabIndex = tabs.length;
      tabs.add(const AdminFeesTab());

      final int unseenCount = adminProvider.unseenPaymentCount;
      Widget feesIcon = const Icon(Icons.attach_money);
      if (unseenCount > 0) {
        feesIcon = Badge(
          label: Text('$unseenCount'),
          backgroundColor: FTColors.error,
          child: const Icon(Icons.attach_money),
        );
      }

      navItems.add(BottomNavigationBarItem(icon: feesIcon, label: 'Fees'));

      tabs.add(const AdminManagementTab());
      navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: 'Admins'));
    }

    // Profile Tab
    tabs.add(const AdminProfileTab());
    navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'));

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
                icon: CircleAvatar(
                  backgroundColor: FTColors.secondary,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null ? const Icon(Icons.person, color: FTColors.surface) : null,
                ),
                onPressed: () {
                  setState(() {
                    _currentIndex = tabs.length - 1; // Profile tab
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
          if (isTopAdmin && feesTabIndex != null && index == feesTabIndex) {
            context.read<AdminProvider>().markNotificationsSeen();
          }
        },
        type: BottomNavigationBarType.fixed,
        items: navItems,
        selectedItemColor: FTColors.primary,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
