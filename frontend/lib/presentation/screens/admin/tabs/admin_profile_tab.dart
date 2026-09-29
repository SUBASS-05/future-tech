import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../providers/admin_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/theme/design_system.dart';
import '../../../widgets/components.dart';

class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  File? _profileImage;
  
  // Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _qualificationCtrl = TextEditingController();
  final _institutionCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _designationCtrl = TextEditingController();
  
  String _selectedGender = 'MALE';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    final provider = context.read<AdminProvider>();
    await provider.fetchProfile();
    
    if (provider.error == 'Session expired or suspended.' && mounted) {
      context.read<AuthProvider>().logout();
      return;
    }

    final profile = provider.adminProfile;
    if (profile != null) {
      _firstNameCtrl.text = profile['firstName'] ?? '';
      _lastNameCtrl.text = profile['lastName'] ?? '';
      _dobCtrl.text = profile['dateOfBirth'] ?? '';
      _phoneCtrl.text = profile['phone'] ?? '';
      _addressCtrl.text = profile['address'] ?? '';
      _cityCtrl.text = profile['city'] ?? '';
      _stateCtrl.text = profile['state'] ?? '';
      _pincodeCtrl.text = profile['pincode'] ?? '';
      _qualificationCtrl.text = profile['qualification'] ?? '';
      _institutionCtrl.text = profile['institution'] ?? '';
      _departmentCtrl.text = profile['department'] ?? '';
      _designationCtrl.text = profile['designation'] ?? '';
      if (['MALE', 'FEMALE', 'OTHER'].contains(profile['gender'])) {
        _selectedGender = profile['gender'];
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'dateOfBirth': _dobCtrl.text.trim(),
        'gender': _selectedGender,
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
        'qualification': _qualificationCtrl.text.trim(),
        'institution': _institutionCtrl.text.trim(),
        'department': _departmentCtrl.text.trim(),
        'designation': _designationCtrl.text.trim(),
        // TODO: Handle Image upload using Multipart in Provider if needed.
        // For now, sending as part of JSON is not typical for files.
      };

      final provider = context.read<AdminProvider>();
      final isComplete = context.read<AuthProvider>().isProfileCompleted;
      bool success = false;
      if (isComplete) {
        success = await provider.updateProfile(data);
      } else {
        success = await provider.completeProfile(data);
      }

      if (mounted) {
        if (success) {
          context.read<AuthProvider>().markProfileCompleted();
          setState(() {
            _isEditing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved successfully'), backgroundColor: FTColors.success),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.error ?? 'Error saving profile'), backgroundColor: FTColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final authProvider = context.watch<AuthProvider>();
    
    if (provider.isProfileLoading && provider.adminProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final profile = provider.adminProfile;
    if (profile == null) {
      return const Center(child: Text('Failed to load profile.'));
    }

    final isComplete = authProvider.isProfileCompleted;
    final missingFields = provider.missingFields;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(FTSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Read-Only Info
          FTCard(
            padding: const EdgeInsets.all(FTSpacing.md),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: FTColors.secondary,
                  backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null ? const Icon(Icons.person, size: 40, color: FTColors.surface) : null,
                ),
                if (_isEditing)
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Change Photo'),
                  ),
                const SizedBox(height: FTSpacing.md),
                Text('Admin ID: ${profile['adminId'] ?? 'N/A'}', style: FTTypography.heading2),
                Text('Email: ${profile['email'] ?? 'N/A'}'),
                Text('Joined: ${profile['joiningDate'] ?? 'N/A'}'),
              ],
            ),
          ),
          const SizedBox(height: FTSpacing.lg),

          if (!isComplete && !_isEditing) ...[
            FTCard(
              padding: const EdgeInsets.all(FTSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Complete Your Profile', style: FTTypography.heading2, textAlign: TextAlign.center),
                  const SizedBox(height: FTSpacing.sm),
                  const Text('Missing fields:', style: TextStyle(fontWeight: FontWeight.bold, color: FTColors.error)),
                  ...missingFields.map((field) => Text('• $field', style: const TextStyle(color: FTColors.error))),
                  const SizedBox(height: FTSpacing.md),
                  FTButton(text: 'Complete Profile', onPressed: () => setState(() => _isEditing = true)),
                ],
              ),
            ),
          ] else if (isComplete && !_isEditing) ...[
            FTCard(
              padding: const EdgeInsets.all(FTSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Profile Details', style: FTTypography.heading2),
                      IconButton(icon: const Icon(Icons.edit, color: FTColors.primary), onPressed: () => setState(() => _isEditing = true)),
                    ],
                  ),
                  const Divider(),
                  _buildProfileRow('Name', '${profile['firstName']} ${profile['lastName']}'),
                  _buildProfileRow('DOB', profile['dateOfBirth']),
                  _buildProfileRow('Gender', profile['gender']),
                  _buildProfileRow('Phone', profile['phone']),
                  _buildProfileRow('Address', '${profile['address']}, ${profile['city']}, ${profile['state']} - ${profile['pincode']}'),
                  const SizedBox(height: FTSpacing.md),
                  const Text('Professional Info', style: FTTypography.heading2),
                  const Divider(),
                  _buildProfileRow('Qualification', profile['qualification']),
                  _buildProfileRow('Institution', profile['institution']),
                  _buildProfileRow('Department', profile['department']),
                  _buildProfileRow('Designation', profile['designation']),
                ],
              ),
            ),
          ] else ...[
            Form(
              key: _formKey,
              child: Column(
                children: [
                  FTTextField(label: 'First Name', controller: _firstNameCtrl, validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: FTSpacing.sm),
                  FTTextField(label: 'Last Name', controller: _lastNameCtrl, validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: FTSpacing.sm),
                  GestureDetector(
                    onTap: _selectDate,
                    child: AbsorbPointer(
                      child: FTTextField(label: 'Date of Birth', controller: _dobCtrl, validator: (v) => v!.isEmpty ? 'Required' : null),
                    ),
                  ),
                  const SizedBox(height: FTSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: const [
                      DropdownMenuItem(value: 'MALE', child: Text('Male')),
                      DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                      DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _selectedGender = v!),
                  ),
                  const SizedBox(height: FTSpacing.sm),
                  FTTextField(label: 'Phone', controller: _phoneCtrl, validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: FTSpacing.sm),
                  FTTextField(label: 'Address', controller: _addressCtrl, validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: FTSpacing.sm),
                  FTTextField(label: 'City', controller: _cityCtrl, validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: FTSpacing.sm),
                  FTTextField(label: 'State', controller: _stateCtrl, validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: FTSpacing.sm),
                  FTTextField(label: 'Pincode', controller: _pincodeCtrl, validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: FTSpacing.sm),
                  FTTextField(label: 'Qualification', controller: _qualificationCtrl, validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: FTSpacing.sm),
                  FTTextField(label: 'Institution', controller: _institutionCtrl, validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: FTSpacing.sm),
                  FTTextField(label: 'Department', controller: _departmentCtrl, validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: FTSpacing.sm),
                  FTTextField(label: 'Designation', controller: _designationCtrl, validator: (v) => v!.isEmpty ? 'Required' : null),
                  
                  const SizedBox(height: FTSpacing.lg),
                  Row(
                    children: [
                      if (isComplete)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _isEditing = false),
                            child: const Text('Cancel'),
                          ),
                        ),
                      if (isComplete) const SizedBox(width: FTSpacing.md),
                      Expanded(
                        flex: 2,
                        child: FTButton(
                          text: 'Save Profile',
                          isLoading: provider.isProfileLoading,
                          onPressed: _saveProfile,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(child: Text(value?.toString() ?? 'N/A')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _dobCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _qualificationCtrl.dispose();
    _institutionCtrl.dispose();
    _departmentCtrl.dispose();
    _designationCtrl.dispose();
    super.dispose();
  }
}
