import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/student_provider.dart';
import '../../../providers/auth_provider.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Personal
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
  
  final _schoolController = TextEditingController();
  final _departmentNameController = TextEditingController();
  final _classStandardController = TextEditingController();
  final _sectionController = TextEditingController();
  final _academicYearController = TextEditingController();
  
  final _joiningYearController = TextEditingController();
  final _passingYearController = TextEditingController();
  
  // Parent
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _altParentPhoneController = TextEditingController();
  String? _selectedRelationship;

  @override
  void initState() {
    super.initState();
    _loadData();
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
          _email = profile['email'];
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
            for(var inst in _institutions) {
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
        // Don't clear if already selected and part of the new list
        if (_selectedDepartmentId != null) {
            bool found = false;
            for(var d in _departments) {
                if (d['id'] == _selectedDepartmentId) found = true;
            }
            if(!found) _selectedDepartmentId = null;
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

  String get _calculatedBatch {
    final join = _joiningYearController.text.trim();
    final pass = _passingYearController.text.trim();
    if (join.isNotEmpty && pass.isNotEmpty) {
      return "$join–$pass";
    }
    return "";
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
                ElevatedButton(
                  onPressed: isLoading ? null : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Profile', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCard(String title, Widget content) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            const Divider(),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalSection() {
    return Column(
      children: [
        if (_studentCode != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text("Student ID: $_studentCode", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        TextFormField(
          initialValue: _email ?? 'student@example.com',
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Email (Cannot be changed)',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.black12,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _dobController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () => _selectDate(context),
            ),
          ),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
          items: ['Male', 'Female', 'Other', 'Prefer not to say']
              .map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (v) => setState(() => _selectedGender = v),
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
          keyboardType: TextInputType.phone,
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _pincodeController,
                decoration: const InputDecoration(labelText: 'Pincode', border: OutlineInputBorder()),
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
        DropdownButtonFormField<String>(
          value: _selectedEducationType,
          decoration: const InputDecoration(labelText: 'Education Type', border: OutlineInputBorder()),
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
        const SizedBox(height: 16),
        if (_selectedEducationType != null && _selectedEducationType != 'SCHOOL') ...[
          DropdownButtonFormField<int>(
            value: _selectedInstitutionId,
            decoration: const InputDecoration(labelText: 'College', border: OutlineInputBorder()),
            items: _institutions.map((i) => DropdownMenuItem<int>(value: i['id'], child: Text(i['institutionName']))).toList(),
            onChanged: (v) {
              setState(() {
                _selectedInstitutionId = v;
                _loadDepartments(v!);
              });
            },
            validator: (v) => v == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _departmentNameController,
            decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _joiningYearController.text.isNotEmpty ? _joiningYearController.text : null,
                  decoration: const InputDecoration(labelText: 'Joining Year', border: OutlineInputBorder()),
                  items: List.generate(20, (i) => (DateTime.now().year - 10 + i).toString())
                      .map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                  onChanged: (v) => setState(() => _joiningYearController.text = v!),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _passingYearController.text.isNotEmpty ? _passingYearController.text : null,
                  decoration: const InputDecoration(labelText: 'Passing Year', border: OutlineInputBorder()),
                  items: List.generate(20, (i) => (DateTime.now().year - 10 + i).toString())
                      .map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                  onChanged: (v) => setState(() => _passingYearController.text = v!),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Academic Batch', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(_calculatedBatch.isEmpty ? 'Automatically calculated' : _calculatedBatch, style: const TextStyle(fontSize: 16)),
              ],
            ),
          )
        ],
        if (_selectedEducationType == 'SCHOOL') ...[
          DropdownButtonFormField<int>(
            value: _selectedInstitutionId,
            decoration: const InputDecoration(labelText: 'School', border: OutlineInputBorder()),
            items: _institutions.map((i) => DropdownMenuItem<int>(value: i['id'], child: Text(i['institutionName']))).toList(),
            onChanged: (v) {
              setState(() {
                _selectedInstitutionId = v;
              });
            },
            validator: (v) => v == null ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _classStandardController,
            decoration: const InputDecoration(labelText: 'Class / Standard', border: OutlineInputBorder()),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _academicYearController,
            decoration: const InputDecoration(labelText: 'Academic Year', border: OutlineInputBorder()),
          ),
        ]
      ],
    );
  }

  Widget _buildParentSection() {
    return Column(
      children: [
        TextFormField(
          controller: _parentNameController,
          decoration: const InputDecoration(labelText: 'Parent / Guardian Name', border: OutlineInputBorder()),
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedRelationship,
          decoration: const InputDecoration(labelText: 'Relationship', border: OutlineInputBorder()),
          items: ['Father', 'Mother', 'Guardian', 'Other']
              .map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => setState(() => _selectedRelationship = v),
          validator: (v) => v == null ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _parentPhoneController,
          decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
          keyboardType: TextInputType.phone,
          validator: (v) => v!.isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _altParentPhoneController,
          decoration: const InputDecoration(labelText: 'Alternative Phone Number', border: OutlineInputBorder()),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }
}
