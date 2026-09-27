import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/student_provider.dart';
import '../../../providers/auth_provider.dart';
import 'student_dashboard.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _phoneController = TextEditingController();
  final _joiningYearController = TextEditingController();
  final _passingYearController = TextEditingController();
  
  String _selectedEducationType = 'COLLEGE';

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final studentProvider = context.read<StudentProvider>();
    await studentProvider.fetchProfile();
    final profile = studentProvider.profile;
    if (profile != null) {
      if (mounted) {
        setState(() {
          _phoneController.text = profile['phone'] ?? '';
          if (profile['educationType'] != null) {
            _selectedEducationType = profile['educationType'];
          }
          if (profile['joiningYear'] != null) {
            _joiningYearController.text = profile['joiningYear'].toString();
          }
          if (profile['passingYear'] != null) {
            _passingYearController.text = profile['passingYear'].toString();
          }
        });
      }
    }
  }

  Future<void> _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      final studentProvider = context.read<StudentProvider>();
      final existingProfile = studentProvider.profile ?? {};
      
      final profileData = {
        'phone': _phoneController.text.trim(),
        'educationType': _selectedEducationType,
        'joiningYear': int.tryParse(_joiningYearController.text),
        'passingYear': int.tryParse(_passingYearController.text),
        'firstName': existingProfile['firstName'] ?? 'Student', 
        'lastName': existingProfile['lastName'] ?? '',
      };

      final error = await studentProvider.updateProfile(profileData);

      if (mounted) {
        if (error == null) {
          // Success! Tell AuthProvider so AuthWrapper automatically routes to Dashboard
          context.read<AuthProvider>().markProfileCompleted();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _joiningYearController.dispose();
    _passingYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<StudentProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false, // Force them to complete it
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.account_circle, size: 80, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  'Welcome to Future Tech!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Before you can access your dashboard, we need a few more details to assign you to the correct academic batch.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => 
                      (value == null || value.isEmpty) ? 'Please enter your phone number' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedEducationType,
                  decoration: const InputDecoration(
                    labelText: 'Education Type',
                    prefixIcon: Icon(Icons.school),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'SCHOOL', child: Text('School')),
                    DropdownMenuItem(value: 'COLLEGE', child: Text('College')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedEducationType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _joiningYearController,
                        decoration: const InputDecoration(
                          labelText: 'Joining Year',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => 
                            (value == null || value.isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _passingYearController,
                        decoration: const InputDecoration(
                          labelText: 'Passing Year',
                          prefixIcon: Icon(Icons.event_available),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => 
                            (value == null || value.isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: isLoading ? null : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('SAVE & CONTINUE', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
