import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/student_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/admin/admin_dashboard.dart';
import 'presentation/screens/student/student_dashboard.dart';

void main() {
  runApp(const FutureTechApp());
}

class FutureTechApp extends StatelessWidget {
  const FutureTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuthStatus()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
      ],
      child: MaterialApp(
        title: 'Future Tech',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Basic routing logic
    if (authProvider.isAuthenticated) {
      if (authProvider.role == 'ADMIN') {
        return const AdminDashboard();
      } else {
        return const StudentDashboard();
      }
    }
    
    return const LoginScreen();
  }
}
