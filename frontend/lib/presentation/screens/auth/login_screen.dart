import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import 'register_screen.dart';
import '../../widgets/components.dart';
import '../../../core/theme/design_system.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'STUDENT';
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = context.read<AuthProvider>();
      
      final profileStatus = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
        _selectedRole,
      );

      if (profileStatus == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: FTColors.surface),
                const SizedBox(width: FTSpacing.sm),
                Text(authProvider.error ?? 'Login failed', style: FTTypography.body.copyWith(color: FTColors.surface)),
              ],
            ),
            backgroundColor: FTColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FTSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.school, size: 64, color: FTColors.primary),
                const SizedBox(height: FTSpacing.lg),
                const Text(
                  'Future Tech',
                  textAlign: TextAlign.center,
                  style: FTTypography.heading1,
                ),
                const SizedBox(height: FTSpacing.xs),
                const Text(
                  'Learn • Grow • Achieve',
                  textAlign: TextAlign.center,
                  style: FTTypography.body,
                ),
                const SizedBox(height: FTSpacing.xxxl),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Login as',
                    prefixIcon: Icon(Icons.people),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'STUDENT', child: Text('Student')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value!;
                    });
                  },
                ),
                const SizedBox(height: FTSpacing.md),
                FTTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => 
                      (value == null || value.isEmpty) ? 'Please enter a valid email address.' : null,
                ),
                const SizedBox(height: FTSpacing.md),
                FTTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) => 
                      (value == null || value.isEmpty) ? 'Please enter your password.' : null,
                ),
                const SizedBox(height: FTSpacing.xl),
                FTButton(
                  text: 'Login',
                  isLoading: isLoading,
                  onPressed: _login,
                ),
                const SizedBox(height: FTSpacing.lg),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: const Text('Don\'t have an account? Create Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
