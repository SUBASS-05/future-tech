import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/student_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../presentation/widgets/components.dart';
import '../../../core/theme/design_system.dart';
import '../../../data/secure_storage/secure_storage.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Personal
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  String? _selectedGender;
  String? _email;
  String? _studentCode;
  
  // Academic
  String? _selectedEducationType;
  
  // Lists for dropdowns
  List<dynamic> _institutions = [];
  List<dynamic> _departments = [];
  
  int? _selectedInstitutionId;
  int? _selectedDepartmentId;
  
  final _departmentNameController = TextEditingController();
  final _classStandardController = TextEditingController();
  final _sectionController = TextEditingController();
  final _academicYearController = TextEditingController();
  
  final _joiningYearController = TextEditingController();
  final _passingYearController = TextEditingController();
  final _batchController = TextEditingController();
  
  // Parent
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _altParentPhoneController = TextEditingController();
  String? _selectedRelationship;

  @override
  void initState() {
    super.initState();
    _joiningYearController.addListener(_updateBatch);
    _passingYearController.addListener(_updateBatch);
    _loadEmailFromStorage();
    _loadData();
  }

  void _updateBatch() {
    final join = _joiningYearController.text.trim();
    final pass = _passingYearController.text.trim();
    if (join.isNotEmpty && pass.isNotEmpty) {
      _batchController.text = "$join–$pass";
    } else if (_batchController.text.isEmpty) {
      _batchController.text = "";
    }
  }

  // Loads the email immediately from secure storage (saved at login)
  // so the field never shows a placeholder while waiting for the profile API
  Future<void> _loadEmailFromStorage() async {
    final email = await SecureStorage.getEmail();
    if (email != null && mounted) {
      setState(() {
        _email = email;
        _emailController.text = email;
      });
    }
  }

  Future<void> _loadData() async {
    final studentProvider = context.read<StudentProvider>();
    await studentProvider.fetchProfile();
    final institutions = await studentProvider.fetchInstitutions();
    
    final profile = studentProvider.profile;
    
    if (mounted) {
      setState(() {
        _institutions = institutions;
        
        if (profile != null) {
          _email = profile['email'] ?? _email;
          if (_email != null) {
            _emailController.text = _email!;
          }
          _studentCode = profile['studentCode'];
          
          _firstNameController.text = profile['firstName'] ?? '';
          _lastNameController.text = profile['lastName'] ?? '';
          if (profile['dateOfBirth'] != null) {
            _dobController.text = profile['dateOfBirth'];
          }
          _selectedGender = profile['gender'];
          _phoneController.text = profile['phone'] ?? '';
          _addressController.text = profile['address'] ?? '';
          _cityController.text = profile['city'] ?? '';
          _pincodeController.text = profile['pincode'] ?? '';
          
          String? edType = profile['educationType'];
          if (edType == 'COLLEGE' || edType == 'ARTS_AND_SCIENCE') {
            edType = null;
          }
          _selectedEducationType = edType;
          
          _selectedInstitutionId = profile['institutionId'];
          if (_selectedInstitutionId != null) {
            bool found = false;
            for (var inst in _institutions) {
              if (inst['id'] == _selectedInstitutionId) found = true;
            }
            if (!found) _selectedInstitutionId = null;
          }
          
          _selectedDepartmentId = profile['departmentId'];
          _departmentNameController.text = profile['departmentName'] ?? '';
          
          _classStandardController.text = profile['classStandard'] ?? '';
          _sectionController.text = profile['section'] ?? '';
          _academicYearController.text = profile['academicYear'] ?? '';
          
          if (profile['joiningYear'] != null) {
            _joiningYearController.text = profile['joiningYear'].toString();
          }
          if (profile['passingYear'] != null) {
            _passingYearController.text = profile['passingYear'].toString();
          }
          if (profile['academicBatch'] != null && profile['academicBatch'].toString().isNotEmpty) {
            _batchController.text = profile['academicBatch'].toString();
          } else {
            _updateBatch();
          }
          
          _parentNameController.text = profile['parentName'] ?? '';
          _selectedRelationship = profile['parentRelationship'];
          _parentPhoneController.text = profile['parentPhone'] ?? '';
          _altParentPhoneController.text = profile['alternativeParentPhone'] ?? '';
        }
      });
    }
  }

  Future<void> _loadDepartments(int institutionId) async {
    final studentProvider = context.read<StudentProvider>();
    final depts = await studentProvider.fetchDepartments(institutionId);
    if (mounted) {
      setState(() {
        _departments = depts;
        if (_selectedDepartmentId != null) {
          bool found = false;
          for (var d in _departments) {
            if (d['id'] == _selectedDepartmentId) found = true;
          }
          if (!found) _selectedDepartmentId = null;
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 15)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      final studentProvider = context.read<StudentProvider>();
      
      final profileData = {
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'dateOfBirth': _dobController.text.trim(),
        'gender': _selectedGender,
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'educationType': _selectedEducationType,
        'institutionId': _selectedInstitutionId,
        'departmentName': _departmentNameController.text.trim(),
        'classStandard': _classStandardController.text.trim(),
        'section': _sectionController.text.trim(),
        'academicYear': _academicYearController.text.trim(),
        'joiningYear': int.tryParse(_joiningYearController.text),
        'passingYear': int.tryParse(_passingYearController.text),
        'parentName': _parentNameController.text.trim(),
        'parentRelationship': _selectedRelationship,
        'parentPhone': _parentPhoneController.text.trim(),
        'alternativeParentPhone': _altParentPhoneController.text.trim(),
      };

      final error = await studentProvider.updateProfile(profileData);

      if (mounted) {
        if (error == null) {
          context.read<AuthProvider>().markProfileCompleted();
          Navigator.pop(context);
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
    _joiningYearController.removeListener(_updateBatch);
    _passingYearController.removeListener(_updateBatch);
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _departmentNameController.dispose();
    _classStandardController.dispose();
    _sectionController.dispose();
    _academicYearController.dispose();
    _joiningYearController.dispose();
    _passingYearController.dispose();
    _batchController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _altParentPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<StudentProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
      ),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCard("Personal Information", _buildPersonalSection()),
                const SizedBox(height: 16),
                _buildCard("Academic Information", _buildAcademicSection()),
                const SizedBox(height: 16),
                _buildCard("Parent / Guardian Information", _buildParentSection()),
                const SizedBox(height: 32),
                FTButton(
                  onPressed: _submitProfile,
                  text: 'Save Profile',
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCard(String title, Widget content) {
    return FTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: FTTypography.heading3.copyWith(color: FTColors.primary)),
          const Divider(color: FTColors.border),
          const SizedBox(height: FTSpacing.sm),
          content,
        ],
      ),
    );
  }

  Widget _buildPersonalSection() {
    return Column(
      children: [
        if (_studentCode != null)
          Padding(
            padding: const EdgeInsets.only(bottom: FTSpacing.md),
            child: Text("Student ID: $_studentCode", style: FTTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
          ),
        FTTextField(
          controller: _emailController,
          readOnly: true,
          label: 'Registered Email (Read-Only)',
          suffixIcon: const Icon(Icons.lock_outline, color: FTColors.textSecondary, size: 20),
        ),
        const SizedBox(height: FTSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FTTextField(
                controller: _firstNameController,
                label: 'First Name',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: FTSpacing.md),
            Expanded(
              child: FTTextField(
                controller: _lastNameController,
                label: 'Last Name',
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: FTSpacing.md),
        FTTextField(
          controller: _dobController,
          readOnly: true,
          label: 'Date of Birth',
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: FTSpacing.md),
        FTDropdown<String>(
          value: _selectedGender,
          label: 'Gender',
          items: ['Male', 'Female', 'Other', 'Prefer not to say']
              .map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (v) => setState(() => _selectedGender = v),
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: FTSpacing.md),
        FTTextField(
          controller: _phoneController,
          label: 'Phone Number',
          keyboardType: TextInputType.phone,
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: FTSpacing.md),
        FTTextField(
          controller: _addressController,
          maxLines: 3,
          label: 'Address',
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: FTSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FTTextField(
                controller: _cityController,
                label: 'City',
              ),
            ),
            const SizedBox(width: FTSpacing.md),
            Expanded(
              child: FTTextField(
                controller: _pincodeController,
                label: 'Pincode',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAcademicSection() {
    return Column(
      children: [
        FTDropdown<String>(
          value: _selectedEducationType,
          label: 'Education Type',
          items: const [
            DropdownMenuItem(value: 'SCHOOL', child: Text('School')),
            DropdownMenuItem(value: 'ENGINEERING', child: Text('Engineering')),
            DropdownMenuItem(value: 'ARTS_SCIENCE', child: Text('Arts & Science')),
            DropdownMenuItem(value: 'POLYTECHNIC', child: Text('Polytechnic')),
            DropdownMenuItem(value: 'OTHER', child: Text('Other')),
          ],
          onChanged: (v) => setState(() => _selectedEducationType = v),
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: FTSpacing.md),
        if (_selectedEducationType != null && _selectedEducationType != 'SCHOOL') ...[
          FTDropdown<int>(
            value: _selectedInstitutionId,
            label: 'College',
            items: _institutions.map((i) => DropdownMenuItem<int>(value: i['id'], child: Text(i['institutionName']))).toList(),
            onChanged: (v) {
              setState(() {
                _selectedInstitutionId = v;
                _loadDepartments(v!);
              });
            },
            validator: (v) => v == null ? 'Required' : null,
          ),
          const SizedBox(height: FTSpacing.md),
          FTTextField(
            controller: _departmentNameController,
            label: 'Department',
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: FTSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FTTextField(
                  controller: _joiningYearController,
                  label: 'Joining Year',
                  hint: 'e.g. 2022',
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: FTSpacing.md),
              Expanded(
                child: FTTextField(
                  controller: _passingYearController,
                  label: 'Passing Year',
                  hint: 'e.g. 2026',
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: FTSpacing.md),
          FTTextField(
            controller: _batchController,
            readOnly: true,
            label: 'Academic Batch (Calculated - Read-Only)',
            hint: 'Calculated from Joining & Passing Year (e.g. 2022–2026)',
            suffixIcon: const Icon(Icons.lock_outline, color: FTColors.textSecondary, size: 20),
          ),
        ],
        if (_selectedEducationType == 'SCHOOL') ...[
          FTDropdown<int>(
            value: _selectedInstitutionId,
            label: 'School',
            items: _institutions.map((i) => DropdownMenuItem<int>(value: i['id'], child: Text(i['institutionName']))).toList(),
            onChanged: (v) {
              setState(() {
                _selectedInstitutionId = v;
              });
            },
            validator: (v) => v == null ? 'Required' : null,
          ),
          const SizedBox(height: FTSpacing.md),
          FTTextField(
            controller: _classStandardController,
            label: 'Class / Standard',
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: FTSpacing.md),
          FTTextField(
            controller: _academicYearController,
            label: 'Academic Year',
          ),
        ]
      ],
    );
  }

  Widget _buildParentSection() {
    return Column(
      children: [
        FTTextField(
          controller: _parentNameController,
          label: 'Parent / Guardian Name',
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: FTSpacing.md),
        FTDropdown<String>(
          value: _selectedRelationship,
          label: 'Relationship',
          items: ['Father', 'Mother', 'Guardian', 'Other']
              .map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => setState(() => _selectedRelationship = v),
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: FTSpacing.md),
        FTTextField(
          controller: _parentPhoneController,
          label: 'Phone Number',
          keyboardType: TextInputType.phone,
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: FTSpacing.md),
        FTTextField(
          controller: _altParentPhoneController,
          label: 'Alternative Phone Number',
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }
}
