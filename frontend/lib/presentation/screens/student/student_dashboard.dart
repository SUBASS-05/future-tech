import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/student_provider.dart';
import 'tabs/profile_tab.dart';
import 'tabs/tasks_tab.dart';
import 'tabs/fees_tab.dart';
import 'tabs/attendance_tab.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final List<Widget> _tabs = [
    const TasksTab(),
    const FeesTab(),
    const AttendanceTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().fetchAllData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshCurrentTab(_currentIndex);
    }
  }

  void _refreshCurrentTab(int index) {
    final provider = context.read<StudentProvider>();
    switch (index) {
      case 0:
        provider.fetchTasks();
        break;
      case 1:
        provider.fetchFees();
        break;
      case 2:
        provider.fetchAttendance();
        provider.fetchLeaveRequests();
        break;
    }
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('My Profile')),
          body: const ProfileTab(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final studentProvider = context.watch<StudentProvider>();
    final profile = studentProvider.profile;
    
    final bool isIncomplete = authProvider.profileStatus == 'INCOMPLETE';
    final String? photoUrl = profile?['profilePhotoUrl'];
    final String firstName = profile?['firstName'] ?? 'Student';

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: _openProfile,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  backgroundColor: Colors.grey.shade300,
                  child: photoUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
                ),
                if (isIncomplete)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        title: Text(firstName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _refreshCurrentTab(index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF168A55),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Fees'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Attendance'),
        ],
      ),
    );
  }
}
