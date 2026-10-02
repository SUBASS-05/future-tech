import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/api/api_service.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/components.dart';
import '../../../core/theme/design_system.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _institutionController = TextEditingController();
  String _selectedRole = 'STUDENT';
  bool _obscurePassword = true;

  void _showServerSettingsDialog() {
    final currentUrl = ApiService.baseUrl;
    final urlController = TextEditingController(text: currentUrl);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Server Connection Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your backend server IP or URL (e.g. 192.168.1.5:8080 or localhost:8080):',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Server Base URL',
                hintText: 'http://192.168.x.x:8080/api',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (urlController.text.trim().isNotEmpty) {
                await ApiService.setCustomBaseUrl(urlController.text.trim());
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Server URL updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _institutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Registration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Server Settings',
            onPressed: _showServerSettingsDialog,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FTSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.person_add, size: 64, color: FTColors.primary),
                const SizedBox(height: FTSpacing.xxl),
                FTTextField(
                  label: 'Full Name',
                  controller: _nameController,
                  validator: (value) => 
                      (value == null || value.isEmpty) ? 'Please enter your full name' : null,
                ),
                const SizedBox(height: FTSpacing.md),
                FTTextField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => 
                      (value == null || value.isEmpty) ? 'Please enter your email' : null,
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
                      (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
                ),
                const SizedBox(height: FTSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Register as',
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
                if (_selectedRole == 'STUDENT') ...[
                  const SizedBox(height: FTSpacing.md),
                  FTTextField(
                    label: 'Institution Name (College/School)',
                    controller: _institutionController,
                    validator: (value) => 
                        (value == null || value.isEmpty) ? 'Please enter your institution name' : null,
                  ),
                ],
                const SizedBox(height: FTSpacing.xxxl),
                FTButton(
                  text: 'Register',
                  isLoading: isLoading,
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final authProvider = context.read<AuthProvider>();
                      bool success = false;
                      
                      if (_selectedRole == 'STUDENT') {
                        success = await authProvider.registerStudent(
                          _nameController.text.trim(),
                          _emailController.text.trim(),
                          _passwordController.text,
                          _institutionController.text.trim(),
                          _selectedRole,
                        );
                      } else {
                        final names = _nameController.text.trim().split(' ');
                        final firstName = names.isNotEmpty ? names.first : '';
                        final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';
                        
                        success = await authProvider.registerAdmin(
                          firstName.isEmpty ? 'Unknown' : firstName,
                          lastName.isEmpty ? 'Unknown' : lastName,
                          _emailController.text.trim(),
                          _passwordController.text,
                        );
                      }

                      if (mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _selectedRole == 'ADMIN' 
                                ? 'Registration successful! Your account is pending verification by Top Admin.'
                                : 'Registration successful. Please wait for Admin approval.'
                              ),
                              backgroundColor: FTColors.success,
                            ),
                          );
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: FTColors.surface),
                                  const SizedBox(width: FTSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      authProvider.error ?? 'Registration failed',
                                      style: FTTypography.body.copyWith(color: FTColors.surface),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: FTColors.error,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
