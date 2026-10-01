import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../providers/admin_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/theme/design_system.dart';
import '../../../../core/api/api_service.dart';
import '../../../widgets/components.dart';

class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  
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
  String _selectedQualification = 'B.E.';
  String _selectedDepartment = 'Computer Science and Engineering';
  String _selectedDesignation = 'Administrator';

  final List<String> _genderOptions = ['MALE', 'FEMALE', 'OTHER', 'PREFER_NOT_TO_SAY'];
  final List<String> _qualificationOptions = ['B.E.', 'B.Tech', 'M.E.', 'M.Tech', 'M.Sc.', 'MBA', 'Ph.D.', 'Other'];
  final List<String> _departmentOptions = [
    'Computer Science and Engineering',
    'Information Technology',
    'Electronics and Communication Engineering',
    'Mechanical Engineering',
    'Commerce',
    'Science',
    'Administration',
    'Other'
  ];
  final List<String> _designationOptions = [
    'Founder',
    'Director',
    'Administrator',
    'Managing Director',
    'Head',
    'Coordinator',
    'Other'
  ];

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
      
      final qual = profile['highestQualification'] ?? profile['qualification'] ?? '';
      if (_qualificationOptions.contains(qual)) {
        _selectedQualification = qual;
        _qualificationCtrl.text = qual;
      } else if (qual.isNotEmpty) {
        _selectedQualification = 'Other';
        _qualificationCtrl.text = qual;
      }

      _institutionCtrl.text = profile['institution'] ?? '';
      
      final dept = profile['department'] ?? '';
      if (_departmentOptions.contains(dept)) {
        _selectedDepartment = dept;
        _departmentCtrl.text = dept;
      } else if (dept.isNotEmpty) {
        _selectedDepartment = 'Other';
        _departmentCtrl.text = dept;
      }

      final desig = profile['designation'] ?? '';
      if (_designationOptions.contains(desig)) {
        _selectedDesignation = desig;
        _designationCtrl.text = desig;
      } else if (desig.isNotEmpty) {
        _selectedDesignation = 'Other';
        _designationCtrl.text = desig;
      }

      if (_genderOptions.contains(profile['gender'])) {
        _selectedGender = profile['gender'];
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final provider = context.read<AdminProvider>();
      final success = await provider.uploadProfilePhoto(pickedFile.path);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated successfully'), backgroundColor: FTColors.success),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.error ?? 'Unable to upload profile photo. Please try again.'), backgroundColor: FTColors.error),
          );
        }
      }
    }
  }

  Future<void> _deletePhoto() async {
    final provider = context.read<AdminProvider>();
    final success = await provider.deleteProfilePhoto();
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo removed'), backgroundColor: FTColors.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to remove photo'), backgroundColor: FTColors.error),
        );
      }
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
      final qualVal = _selectedQualification == 'Other' ? _qualificationCtrl.text.trim() : _selectedQualification;
      final deptVal = _selectedDepartment == 'Other' ? _departmentCtrl.text.trim() : _selectedDepartment;
      final desigVal = _selectedDesignation == 'Other' ? _designationCtrl.text.trim() : _selectedDesignation;

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
        'highestQualification': qualVal,
        'qualification': qualVal,
        'institution': _institutionCtrl.text.trim(),
        'department': deptVal,
        'designation': desigVal,
      };

      final provider = context.read<AdminProvider>();
      final success = await provider.updateProfile(data);

      if (mounted) {
        if (success) {
          final isNowCompleted = provider.missingFields.isEmpty;
          if (isNowCompleted) {
            context.read<AuthProvider>().markProfileCompleted();
          }
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

  String _formatFieldName(String field) {
    switch (field) {
      case 'firstName': return 'First Name';
      case 'lastName': return 'Last Name';
      case 'dateOfBirth': return 'Date of Birth';
      case 'gender': return 'Gender';
      case 'phone': return 'Phone Number';
      case 'address': return 'Address';
      case 'city': return 'City';
      case 'state': return 'State';
      case 'pincode': return 'Pincode';
      case 'highestQualification':
      case 'qualification': return 'Highest Qualification';
      case 'institution': return 'Institution / College';
      case 'department': return 'Department';
      case 'designation': return 'Designation';
      default: return field;
    }
  }

  String _formatGenderLabel(String gender) {
    switch (gender.toUpperCase()) {
      case 'MALE': return 'Male';
      case 'FEMALE': return 'Female';
      case 'OTHER': return 'Other';
      case 'PREFER_NOT_TO_SAY': return 'Prefer not to say';
      default: return gender;
    }
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
    final provider = context.watch<AdminProvider>();
    final authProvider = context.watch<AuthProvider>();
    
    if (provider.isProfileLoading && provider.adminProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final profile = provider.adminProfile;
    if (profile == null) {
      return const Center(child: Text('Failed to load profile.'));
    }

    final missingFields = provider.missingFields;
    final isComplete = missingFields.isEmpty;
    final photoUrl = _getFormattedPhotoUrl(profile['profilePhotoUrl']?.toString());
    final roleName = profile['role'] ?? authProvider.role ?? 'TOP_ADMIN';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(FTSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header Summary Card
          FTCard(
            padding: const EdgeInsets.all(FTSpacing.md),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: FTColors.secondary,
                  backgroundImage: photoUrl != null 
                      ? NetworkImage(photoUrl) 
                      : null,
                  child: photoUrl == null
                      ? const Icon(Icons.person, size: 48, color: FTColors.surface)
                      : null,
                ),
                const SizedBox(height: FTSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _pickAndUploadPhoto,
                      icon: const Icon(Icons.add_a_photo, size: 18),
                      label: Text(photoUrl != null ? 'Change Photo' : 'Add Profile Photo'),
                    ),
                    if (photoUrl != null && photoUrl.toString().isNotEmpty) ...[
                      const SizedBox(width: FTSpacing.xs),
                      TextButton.icon(
                        onPressed: _deletePhoto,
                        icon: const Icon(Icons.delete_outline, size: 18, color: FTColors.error),
                        label: const Text('Remove', style: TextStyle(color: FTColors.error)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: FTSpacing.sm),
                Text(
                  '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim().isEmpty 
                      ? 'Admin User' 
                      : '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}',
                  style: FTTypography.heading1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: FTSpacing.xs),
                Chip(
                  avatar: const Icon(Icons.security, size: 16, color: Colors.white),
                  label: Text(roleName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: FTColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: FTSpacing.md),

          // Read-Only Security Info Card
          FTCard(
            padding: const EdgeInsets.all(FTSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lock_outline, size: 20, color: Colors.grey),
                    SizedBox(width: FTSpacing.xs),
                    Text('Account Info (Read-Only)', style: FTTypography.heading2),
                  ],
                ),
                const Divider(),
                _buildReadOnlyRow('Email', profile['email'] ?? 'N/A'),
                _buildReadOnlyRow('Admin ID', profile['adminId'] ?? 'FTADM001'),
                _buildReadOnlyRow('Role', roleName),
                _buildReadOnlyRow('Joining Date', profile['joiningDate'] ?? 'N/A'),
                _buildReadOnlyRow('Account Status', profile['status'] ?? 'ACTIVE'),
                _buildReadOnlyRow(
                  'Profile Status', 
                  isComplete ? 'COMPLETED' : 'INCOMPLETE',
                  valueColor: isComplete ? FTColors.success : FTColors.error,
                ),
              ],
            ),
          ),
          const SizedBox(height: FTSpacing.md),

          // Profile Incomplete Banner Card
          if (!isComplete && !_isEditing) ...[
            FTCard(
              padding: const EdgeInsets.all(FTSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: FTColors.error, size: 24),
                      SizedBox(width: FTSpacing.sm),
                      Text('Complete Your Profile', style: FTTypography.heading2),
                    ],
                  ),
                  const SizedBox(height: FTSpacing.xs),
                  const Text('Some required profile information is still missing.'),
                  const SizedBox(height: FTSpacing.sm),
                  const Text('Missing:', style: TextStyle(fontWeight: FontWeight.bold, color: FTColors.error)),
                  const SizedBox(height: FTSpacing.xs),
                  ...missingFields.map((field) => Padding(
                    padding: const EdgeInsets.only(left: FTSpacing.sm, bottom: 2),
                    child: Text('• ${_formatFieldName(field)}', style: const TextStyle(color: FTColors.error, fontWeight: FontWeight.w500)),
                  )),
                  const SizedBox(height: FTSpacing.md),
                  FTButton(
                    text: 'Complete Profile',
                    onPressed: () => setState(() => _isEditing = true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: FTSpacing.md),
          ],

          // Profile Details View / Edit Mode
          if (!_isEditing) ...[
            FTCard(
              padding: const EdgeInsets.all(FTSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Personal Information', style: FTTypography.heading2),
                      IconButton(
                        icon: const Icon(Icons.edit, color: FTColors.primary),
                        onPressed: () => setState(() => _isEditing = true),
                        tooltip: 'Edit Profile',
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildProfileRow('First Name', profile['firstName']),
                  _buildProfileRow('Last Name', profile['lastName']),
                  _buildProfileRow('Date of Birth', profile['dateOfBirth']),
                  _buildProfileRow('Gender', profile['gender'] != null ? _formatGenderLabel(profile['gender']) : null),
                  _buildProfileRow('Phone', profile['phone']),
                  _buildProfileRow('Address', profile['address']),
                  _buildProfileRow('City', profile['city']),
                  _buildProfileRow('State', profile['state']),
                  _buildProfileRow('Pincode', profile['pincode']),
                  
                  const SizedBox(height: FTSpacing.lg),
                  const Text('Professional Information', style: FTTypography.heading2),
                  const Divider(),
                  _buildProfileRow('Qualification', profile['highestQualification'] ?? profile['qualification']),
                  _buildProfileRow('Institution', profile['institution']),
                  _buildProfileRow('Department', profile['department']),
                  _buildProfileRow('Designation', profile['designation']),
                  
                  const SizedBox(height: FTSpacing.lg),
                  FTButton(
                    text: 'Edit Profile',
                    onPressed: () => setState(() => _isEditing = true),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Edit Profile Form
            FTCard(
              padding: const EdgeInsets.all(FTSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Edit Profile', style: FTTypography.heading2),
                    const Divider(),
                    const SizedBox(height: FTSpacing.sm),
                    
                    const Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: FTSpacing.md),
                    
                    FTTextField(
                      label: 'First Name',
                      controller: _firstNameCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'First Name is required' : null,
                    ),
                    const SizedBox(height: FTSpacing.md),
                    
                    FTTextField(
                      label: 'Last Name',
                      controller: _lastNameCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Last Name is required' : null,
                    ),
                    const SizedBox(height: FTSpacing.md),
                    
                    GestureDetector(
                      onTap: _selectDate,
                      child: AbsorbPointer(
                        child: FTTextField(
                          label: 'Date of Birth (YYYY-MM-DD)',
                          controller: _dobCtrl,
                          suffixIcon: const Icon(Icons.calendar_today),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Date of Birth is required' : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: FTSpacing.md),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: _genderOptions.map((g) => DropdownMenuItem(
                        value: g,
                        child: Text(_formatGenderLabel(g)),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedGender = v!),
                    ),
                    const SizedBox(height: FTSpacing.md),
                    
                    FTTextField(
                      label: 'Phone Number (10 digits)',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Phone Number is required';
                        if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v.trim())) {
                          return 'Enter valid 10-digit Indian phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: FTSpacing.md),
                    
                    FTTextField(
                      label: 'Address',
                      controller: _addressCtrl,
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                    ),
                    const SizedBox(height: FTSpacing.md),
                    
                    FTTextField(
                      label: 'City',
                      controller: _cityCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'City is required' : null,
                    ),
                    const SizedBox(height: FTSpacing.md),
                    
                    FTTextField(
                      label: 'State',
                      controller: _stateCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'State is required' : null,
                    ),
                    const SizedBox(height: FTSpacing.md),
                    
                    FTTextField(
                      label: 'Pincode (6 digits)',
                      controller: _pincodeCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Pincode is required';
                        if (!RegExp(r'^\d{6}$').hasMatch(v.trim())) {
                          return 'Enter valid 6-digit PIN code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: FTSpacing.xl),

                    const Text('Professional Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: FTSpacing.md),

                    DropdownButtonFormField<String>(
                      value: _selectedQualification,
                      decoration: const InputDecoration(labelText: 'Highest Qualification'),
                      items: _qualificationOptions.map((q) => DropdownMenuItem(
                        value: q,
                        child: Text(q),
                      )).toList(),
                      onChanged: (v) => setState(() {
                        _selectedQualification = v!;
                        if (v != 'Other') _qualificationCtrl.text = v;
                      }),
                    ),
                    if (_selectedQualification == 'Other') ...[
                      const SizedBox(height: FTSpacing.md),
                      FTTextField(
                        label: 'Specify Qualification',
                        controller: _qualificationCtrl,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Qualification is required' : null,
                      ),
                    ],
                    const SizedBox(height: FTSpacing.md),

                    FTTextField(
                      label: 'Institution / College',
                      controller: _institutionCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Institution is required' : null,
                    ),
                    const SizedBox(height: FTSpacing.md),

                    DropdownButtonFormField<String>(
                      value: _selectedDepartment,
                      decoration: const InputDecoration(labelText: 'Department'),
                      items: _departmentOptions.map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(d),
                      )).toList(),
                      onChanged: (v) => setState(() {
                        _selectedDepartment = v!;
                        if (v != 'Other') _departmentCtrl.text = v;
                      }),
                    ),
                    if (_selectedDepartment == 'Other') ...[
                      const SizedBox(height: FTSpacing.md),
                      FTTextField(
                        label: 'Specify Department',
                        controller: _departmentCtrl,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Department is required' : null,
                      ),
                    ],
                    const SizedBox(height: FTSpacing.md),

                    DropdownButtonFormField<String>(
                      value: _selectedDesignation,
                      decoration: const InputDecoration(labelText: 'Designation'),
                      items: _designationOptions.map((ds) => DropdownMenuItem(
                        value: ds,
                        child: Text(ds),
                      )).toList(),
                      onChanged: (v) => setState(() {
                        _selectedDesignation = v!;
                        if (v != 'Other') _designationCtrl.text = v;
                      }),
                    ),
                    if (_selectedDesignation == 'Other') ...[
                      const SizedBox(height: FTSpacing.md),
                      FTTextField(
                        label: 'Specify Designation',
                        controller: _designationCtrl,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Designation is required' : null,
                      ),
                    ],

                    const SizedBox(height: FTSpacing.xxl),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _isEditing = false),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: FTSpacing.md),
                        Expanded(
                          flex: 2,
                          child: FTButton(
                            text: 'Save Changes',
                            isLoading: provider.isProfileLoading,
                            onPressed: _saveProfile,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.lock, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor ?? FTColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              (value == null || value.toString().trim().isEmpty) ? 'Not Provided' : value.toString(),
              style: TextStyle(
                color: (value == null || value.toString().trim().isEmpty) ? Colors.redAccent : FTColors.textPrimary,
                fontStyle: (value == null || value.toString().trim().isEmpty) ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
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
