import java.io.File;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;

public class GeneratePhase10 {
    public static void main(String[] args) throws Exception {
        String basePath = "d:/future tech/frontend/lib";

        Map<String, String> files = new HashMap<>();

        // ---- Admin Provider ----
        files.put(basePath + "/providers/admin_provider.dart",
            "package:flutter/material.dart;\n" + // Note: Fixing standard import format below
            "import 'dart:convert';\n" +
            "import 'package:flutter/material.dart';\n" +
            "import '../core/api/api_service.dart';\n\n" +
            "class AdminProvider with ChangeNotifier {\n" +
            "  final ApiService _apiService = ApiService();\n" +
            "  bool _isLoading = false;\n" +
            "  List<dynamic> _pendingRequests = [];\n\n" +
            "  bool get isLoading => _isLoading;\n" +
            "  List<dynamic> get pendingRequests => _pendingRequests;\n\n" +
            "  Future<void> fetchPendingRequests() async {\n" +
            "    _isLoading = true;\n" +
            "    notifyListeners();\n" +
            "    try {\n" +
            "      final response = await _apiService.get('/admin/requests/pending');\n" +
            "      if (response.statusCode == 200) {\n" +
            "        _pendingRequests = jsonDecode(response.body);\n" +
            "      }\n" +
            "    } catch (e) { print(e); }\n" +
            "    _isLoading = false;\n" +
            "    notifyListeners();\n" +
            "  }\n\n" +
            "  Future<bool> approveStudent(int studentId) async {\n" +
            "    try {\n" +
            "      final response = await _apiService.post('/admin/requests/$studentId/approve', {});\n" +
            "      if (response.statusCode == 200) {\n" +
            "        await fetchPendingRequests();\n" +
            "        return true;\n" +
            "      }\n" +
            "    } catch (e) { print(e); }\n" +
            "    return false;\n" +
            "  }\n\n" +
            "  Future<bool> rejectStudent(int studentId) async {\n" +
            "    try {\n" +
            "      final response = await _apiService.post('/admin/requests/$studentId/reject', {});\n" +
            "      if (response.statusCode == 200) {\n" +
            "        await fetchPendingRequests();\n" +
            "        return true;\n" +
            "      }\n" +
            "    } catch (e) { print(e); }\n" +
            "    return false;\n" +
            "  }\n" +
            "}\n"
        );

        // ---- Student Provider ----
        files.put(basePath + "/providers/student_provider.dart",
            "import 'dart:convert';\n" +
            "import 'package:flutter/material.dart';\n" +
            "import '../core/api/api_service.dart';\n\n" +
            "class StudentProvider with ChangeNotifier {\n" +
            "  final ApiService _apiService = ApiService();\n" +
            "  bool _isLoading = false;\n" +
            "  Map<String, dynamic>? _profile;\n" +
            "  List<dynamic> _tasks = [];\n" +
            "  List<dynamic> _fees = [];\n" +
            "  List<dynamic> _attendance = [];\n\n" +
            "  bool get isLoading => _isLoading;\n" +
            "  Map<String, dynamic>? get profile => _profile;\n" +
            "  List<dynamic> get tasks => _tasks;\n" +
            "  List<dynamic> get fees => _fees;\n" +
            "  List<dynamic> get attendance => _attendance;\n\n" +
            "  Future<void> fetchAllData() async {\n" +
            "    _isLoading = true;\n" +
            "    notifyListeners();\n" +
            "    await Future.wait([\n" +
            "      fetchProfile(),\n" +
            "      fetchTasks(),\n" +
            "      fetchFees(),\n" +
            "      fetchAttendance()\n" +
            "    ]);\n" +
            "    _isLoading = false;\n" +
            "    notifyListeners();\n" +
            "  }\n\n" +
            "  Future<void> fetchProfile() async {\n" +
            "    try {\n" +
            "      final response = await _apiService.get('/student/profile');\n" +
            "      if (response.statusCode == 200) {\n" +
            "        _profile = jsonDecode(response.body);\n" +
            "      }\n" +
            "    } catch (e) { print(e); }\n" +
            "  }\n\n" +
            "  Future<void> fetchTasks() async {\n" +
            "    try {\n" +
            "      final response = await _apiService.get('/student/tasks');\n" +
            "      if (response.statusCode == 200) {\n" +
            "        _tasks = jsonDecode(response.body);\n" +
            "      }\n" +
            "    } catch (e) { print(e); }\n" +
            "  }\n\n" +
            "  Future<bool> updateTaskStatus(int taskId, String status) async {\n" +
            "    try {\n" +
            "      final response = await _apiService.put('/student/tasks/$taskId/status', {'status': status});\n" +
            "      if (response.statusCode == 200) {\n" +
            "        await fetchTasks();\n" +
            "        return true;\n" +
            "      }\n" +
            "    } catch (e) { print(e); }\n" +
            "    return false;\n" +
            "  }\n\n" +
            "  Future<void> fetchFees() async {\n" +
            "    try {\n" +
            "      final response = await _apiService.get('/student/fees');\n" +
            "      if (response.statusCode == 200) {\n" +
            "        _fees = jsonDecode(response.body);\n" +
            "      }\n" +
            "    } catch (e) { print(e); }\n" +
            "  }\n\n" +
            "  Future<void> fetchAttendance() async {\n" +
            "    try {\n" +
            "      final response = await _apiService.get('/student/attendance');\n" +
            "      if (response.statusCode == 200) {\n" +
            "        _attendance = jsonDecode(response.body);\n" +
            "      }\n" +
            "    } catch (e) { print(e); }\n" +
            "  }\n" +
            "}\n"
        );

        // ---- Admin Dashboard ----
        files.put(basePath + "/presentation/screens/admin/admin_dashboard.dart",
            "import 'package:flutter/material.dart';\n" +
            "import 'package:provider/provider.dart';\n" +
            "import '../../../providers/admin_provider.dart';\n" +
            "import '../../../providers/auth_provider.dart';\n\n" +
            "class AdminDashboard extends StatefulWidget {\n" +
            "  const AdminDashboard({super.key});\n" +
            "  @override\n" +
            "  State<AdminDashboard> createState() => _AdminDashboardState();\n" +
            "}\n\n" +
            "class _AdminDashboardState extends State<AdminDashboard> {\n" +
            "  @override\n" +
            "  void initState() {\n" +
            "    super.initState();\n" +
            "    WidgetsBinding.instance.addPostFrameCallback((_) {\n" +
            "      context.read<AdminProvider>().fetchPendingRequests();\n" +
            "    });\n" +
            "  }\n\n" +
            "  @override\n" +
            "  Widget build(BuildContext context) {\n" +
            "    final adminProvider = context.watch<AdminProvider>();\n" +
            "    return Scaffold(\n" +
            "      appBar: AppBar(\n" +
            "        title: const Text('Admin Dashboard'),\n" +
            "        actions: [\n" +
            "          IconButton(\n" +
            "            icon: const Icon(Icons.logout),\n" +
            "            onPressed: () => context.read<AuthProvider>().logout(),\n" +
            "          )\n" +
            "        ],\n" +
            "      ),\n" +
            "      body: adminProvider.isLoading\n" +
            "          ? const Center(child: CircularProgressIndicator())\n" +
            "          : adminProvider.pendingRequests.isEmpty\n" +
            "              ? const Center(child: Text('No pending requests.'))\n" +
            "              : ListView.builder(\n" +
            "                  itemCount: adminProvider.pendingRequests.length,\n" +
            "                  itemBuilder: (context, index) {\n" +
            "                    final req = adminProvider.pendingRequests[index];\n" +
            "                    return Card(\n" +
            "                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),\n" +
            "                      child: ListTile(\n" +
            "                        leading: const CircleAvatar(child: Icon(Icons.person)),\n" +
            "                        title: Text(req['fullName'] ?? 'Unknown'),\n" +
            "                        subtitle: Text('${req['email']} - ${req['institutionName']}'),\n" +
            "                        trailing: Row(\n" +
            "                          mainAxisSize: MainAxisSize.min,\n" +
            "                          children: [\n" +
            "                            IconButton(\n" +
            "                              icon: const Icon(Icons.check, color: Colors.green),\n" +
            "                              onPressed: () => adminProvider.approveStudent(req['studentId']),\n" +
            "                            ),\n" +
            "                            IconButton(\n" +
            "                              icon: const Icon(Icons.close, color: Colors.red),\n" +
            "                              onPressed: () => adminProvider.rejectStudent(req['studentId']),\n" +
            "                            ),\n" +
            "                          ],\n" +
            "                        ),\n" +
            "                      ),\n" +
            "                    );\n" +
            "                  },\n" +
            "                ),\n" +
            "    );\n" +
            "  }\n" +
            "}\n"
        );

        // ---- Student Dashboard (Root with Bottom Nav) ----
        files.put(basePath + "/presentation/screens/student/student_dashboard.dart",
            "import 'package:flutter/material.dart';\n" +
            "import 'package:provider/provider.dart';\n" +
            "import '../../../providers/auth_provider.dart';\n" +
            "import '../../../providers/student_provider.dart';\n" +
            "import 'tabs/profile_tab.dart';\n" +
            "import 'tabs/tasks_tab.dart';\n" +
            "import 'tabs/fees_tab.dart';\n" +
            "import 'tabs/attendance_tab.dart';\n\n" +
            "class StudentDashboard extends StatefulWidget {\n" +
            "  const StudentDashboard({super.key});\n" +
            "  @override\n" +
            "  State<StudentDashboard> createState() => _StudentDashboardState();\n" +
            "}\n\n" +
            "class _StudentDashboardState extends State<StudentDashboard> {\n" +
            "  int _currentIndex = 0;\n" +
            "  final List<Widget> _tabs = [\n" +
            "    const ProfileTab(),\n" +
            "    const TasksTab(),\n" +
            "    const FeesTab(),\n" +
            "    const AttendanceTab(),\n" +
            "  ];\n\n" +
            "  @override\n" +
            "  void initState() {\n" +
            "    super.initState();\n" +
            "    WidgetsBinding.instance.addPostFrameCallback((_) {\n" +
            "      context.read<StudentProvider>().fetchAllData();\n" +
            "    });\n" +
            "  }\n\n" +
            "  @override\n" +
            "  Widget build(BuildContext context) {\n" +
            "    return Scaffold(\n" +
            "      appBar: AppBar(\n" +
            "        title: const Text('Future Tech Student'),\n" +
            "        actions: [\n" +
            "          IconButton(\n" +
            "            icon: const Icon(Icons.logout),\n" +
            "            onPressed: () => context.read<AuthProvider>().logout(),\n" +
            "          )\n" +
            "        ],\n" +
            "      ),\n" +
            "      body: _tabs[_currentIndex],\n" +
            "      bottomNavigationBar: BottomNavigationBar(\n" +
            "        currentIndex: _currentIndex,\n" +
            "        type: BottomNavigationBarType.fixed,\n" +
            "        onTap: (index) => setState(() => _currentIndex = index),\n" +
            "        items: const [\n" +
            "          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),\n" +
            "          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Tasks'),\n" +
            "          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Fees'),\n" +
            "          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Attendance'),\n" +
            "        ],\n" +
            "      ),\n" +
            "    );\n" +
            "  }\n" +
            "}\n"
        );

        // ---- Profile Tab ----
        files.put(basePath + "/presentation/screens/student/tabs/profile_tab.dart",
            "import 'package:flutter/material.dart';\n" +
            "import 'package:provider/provider.dart';\n" +
            "import '../../../../providers/student_provider.dart';\n\n" +
            "class ProfileTab extends StatelessWidget {\n" +
            "  const ProfileTab({super.key});\n" +
            "  @override\n" +
            "  Widget build(BuildContext context) {\n" +
            "    final provider = context.watch<StudentProvider>();\n" +
            "    if (provider.isLoading) return const Center(child: CircularProgressIndicator());\n" +
            "    final profile = provider.profile;\n" +
            "    if (profile == null) return const Center(child: Text('Profile not found'));\n" +
            "    return ListView(\n" +
            "      padding: const EdgeInsets.all(16.0),\n" +
            "      children: [\n" +
            "        const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),\n" +
            "        const SizedBox(height: 16),\n" +
            "        Text(profile['firstName'] ?? 'Student', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),\n" +
            "        const SizedBox(height: 32),\n" +
            "        ListTile(leading: const Icon(Icons.badge), title: const Text('Student Code'), subtitle: Text(profile['studentCode'] ?? '')),\n" +
            "        ListTile(leading: const Icon(Icons.school), title: const Text('Institution'), subtitle: Text(profile['institutionName'] ?? '')),\n" +
            "        ListTile(leading: const Icon(Icons.info), title: const Text('Status'), subtitle: Text(profile['status'] ?? '')),\n" +
            "      ],\n" +
            "    );\n" +
            "  }\n" +
            "}\n"
        );

        // ---- Tasks Tab ----
        files.put(basePath + "/presentation/screens/student/tabs/tasks_tab.dart",
            "import 'package:flutter/material.dart';\n" +
            "import 'package:provider/provider.dart';\n" +
            "import '../../../../providers/student_provider.dart';\n\n" +
            "class TasksTab extends StatelessWidget {\n" +
            "  const TasksTab({super.key});\n" +
            "  @override\n" +
            "  Widget build(BuildContext context) {\n" +
            "    final provider = context.watch<StudentProvider>();\n" +
            "    if (provider.isLoading) return const Center(child: CircularProgressIndicator());\n" +
            "    if (provider.tasks.isEmpty) return const Center(child: Text('No daily tasks found.'));\n" +
            "    return ListView.builder(\n" +
            "      itemCount: provider.tasks.length,\n" +
            "      itemBuilder: (context, index) {\n" +
            "        final task = provider.tasks[index];\n" +
            "        final isCompleted = task['status'] == 'COMPLETED';\n" +
            "        return CheckboxListTile(\n" +
            "          title: Text(task['title'] ?? ''),\n" +
            "          subtitle: Text(task['description'] ?? ''),\n" +
            "          value: isCompleted,\n" +
            "          onChanged: (val) {\n" +
            "             if (val != null) provider.updateTaskStatus(task['id'], val ? 'COMPLETED' : 'PENDING');\n" +
            "          },\n" +
            "        );\n" +
            "      },\n" +
            "    );\n" +
            "  }\n" +
            "}\n"
        );

        // ---- Fees Tab ----
        files.put(basePath + "/presentation/screens/student/tabs/fees_tab.dart",
            "import 'package:flutter/material.dart';\n" +
            "import 'package:provider/provider.dart';\n" +
            "import '../../../../providers/student_provider.dart';\n\n" +
            "class FeesTab extends StatelessWidget {\n" +
            "  const FeesTab({super.key});\n" +
            "  @override\n" +
            "  Widget build(BuildContext context) {\n" +
            "    final provider = context.watch<StudentProvider>();\n" +
            "    if (provider.isLoading) return const Center(child: CircularProgressIndicator());\n" +
            "    if (provider.fees.isEmpty) return const Center(child: Text('No fee records found.'));\n" +
            "    return ListView.builder(\n" +
            "      itemCount: provider.fees.length,\n" +
            "      itemBuilder: (context, index) {\n" +
            "        final fee = provider.fees[index];\n" +
            "        return Card(\n" +
            "          margin: const EdgeInsets.all(8.0),\n" +
            "          child: ListTile(\n" +
            "            leading: const Icon(Icons.payment, color: Colors.blue),\n" +
            "            title: Text(fee['feeName'] ?? ''),\n" +
            "            subtitle: Text('Due: \\$${fee['totalAmount']} - Status: ${fee['status']}'),\n" +
            "          ),\n" +
            "        );\n" +
            "      },\n" +
            "    );\n" +
            "  }\n" +
            "}\n"
        );

        // ---- Attendance Tab ----
        files.put(basePath + "/presentation/screens/student/tabs/attendance_tab.dart",
            "import 'package:flutter/material.dart';\n" +
            "import 'package:provider/provider.dart';\n" +
            "import '../../../../providers/student_provider.dart';\n\n" +
            "class AttendanceTab extends StatelessWidget {\n" +
            "  const AttendanceTab({super.key});\n" +
            "  @override\n" +
            "  Widget build(BuildContext context) {\n" +
            "    final provider = context.watch<StudentProvider>();\n" +
            "    if (provider.isLoading) return const Center(child: CircularProgressIndicator());\n" +
            "    if (provider.attendance.isEmpty) return const Center(child: Text('No attendance records.'));\n" +
            "    return ListView.builder(\n" +
            "      itemCount: provider.attendance.length,\n" +
            "      itemBuilder: (context, index) {\n" +
            "        final att = provider.attendance[index];\n" +
            "        final isPresent = att['status'] == 'PRESENT';\n" +
            "        return ListTile(\n" +
            "          leading: Icon(isPresent ? Icons.check_circle : Icons.cancel, color: isPresent ? Colors.green : Colors.red),\n" +
            "          title: Text('Date: ${att['attendanceDate']}'),\n" +
            "          subtitle: Text('Status: ${att['status']}'),\n" +
            "        );\n" +
            "      },\n" +
            "    );\n" +
            "  }\n" +
            "}\n"
        );

        // Update main.dart
        String mainPath = basePath + "/main.dart";
        if (new File(mainPath).exists()) {
            String mainContent = new String(Files.readAllBytes(Paths.get(mainPath)));
            
            // Fix Provider Imports
            if (!mainContent.contains("admin_provider.dart")) {
                mainContent = mainContent.replace(
                    "import 'providers/auth_provider.dart';",
                    "import 'providers/auth_provider.dart';\nimport 'providers/admin_provider.dart';\nimport 'providers/student_provider.dart';"
                );
            }
            
            // Fix Dashboard Imports
            if (!mainContent.contains("admin_dashboard.dart")) {
                mainContent = mainContent.replace(
                    "import 'presentation/screens/auth/login_screen.dart';",
                    "import 'presentation/screens/auth/login_screen.dart';\nimport 'presentation/screens/admin/admin_dashboard.dart';\nimport 'presentation/screens/student/student_dashboard.dart';"
                );
            }

            // Fix MultiProvider Registration
            if (!mainContent.contains("AdminProvider")) {
                mainContent = mainContent.replace(
                    "ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuthStatus()),",
                    "ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuthStatus()),\n        ChangeNotifierProvider(create: (_) => AdminProvider()),\n        ChangeNotifierProvider(create: (_) => StudentProvider()),"
                );
            }

            // Fix Dashboard Routing
            mainContent = mainContent.replace(
                "return const Scaffold(body: Center(child: Text('Admin Dashboard')));",
                "return const AdminDashboard();"
            );
            mainContent = mainContent.replace(
                "return const Scaffold(body: Center(child: Text('Student Dashboard')));",
                "return const StudentDashboard();"
            );

            Files.write(Paths.get(mainPath), mainContent.getBytes());
        }

        // Write all UI/Provider files
        for (Map.Entry<String, String> entry : files.entrySet()) {
            // Clean up hacky fix for admin_provider
            String content = entry.getValue();
            if (content.startsWith("package:flutter/material.dart;\\n")) {
                content = content.replace("package:flutter/material.dart;\\n", "");
            }
            
            File file = new File(entry.getKey());
            file.getParentFile().mkdirs();
            Files.write(Paths.get(entry.getKey()), content.getBytes());
            System.out.println("Generated: " + entry.getKey());
        }
        
        System.out.println("Phase 10 Frontend Generation Complete!");
    }
}
