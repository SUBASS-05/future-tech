import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../providers/student_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../profile_completion_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final authProvider = context.watch<AuthProvider>();
    
    final bool isIncomplete = authProvider.profileStatus == 'INCOMPLETE';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
      ),
      body: provider.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context, provider.profile, isIncomplete),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic>? profile, bool isIncomplete) {
    if (profile == null) return const Center(child: Text('Profile not found'));
    if (profile.containsKey('error')) return Center(child: Text(profile['error'].toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)));
    
    // Calculate completeness
    final List<Map<String, dynamic>> allFields = [
      {'label': 'First Name', 'value': profile['firstName'], 'section': 'Personal'},
      {'label': 'Last Name', 'value': profile['lastName'], 'section': 'Personal'},
      {'label': 'Date of Birth', 'value': profile['dateOfBirth'], 'section': 'Personal'},
      {'label': 'Gender', 'value': profile['gender'], 'section': 'Personal'},
      {'label': 'Phone', 'value': profile['phone'], 'section': 'Personal'},
      {'label': 'Address', 'value': profile['address'], 'section': 'Personal'},
      {'label': 'Education Type', 'value': profile['educationType'], 'section': 'Academic'},
    ];
    
    if (profile['educationType'] != null) {
      if (profile['educationType'] == 'SCHOOL') {
        allFields.addAll([
          {'label': 'School', 'value': profile['institutionName'], 'section': 'Academic'},
          {'label': 'Class / Standard', 'value': profile['classStandard'], 'section': 'Academic'},
        ]);
      } else {
        allFields.addAll([
          {'label': 'College', 'value': profile['institutionName'], 'section': 'Academic'},
          {'label': 'Department', 'value': profile['departmentName'], 'section': 'Academic'},
          {'label': 'Joining Year', 'value': profile['joiningYear'], 'section': 'Academic'},
          {'label': 'Passing Year', 'value': profile['passingYear'], 'section': 'Academic'},
        ]);
      }
    } else {
        allFields.addAll([
          {'label': 'Institution', 'value': null, 'section': 'Academic'},
        ]);
    }
    
    allFields.addAll([
      {'label': 'Parent Name', 'value': profile['parentName'], 'section': 'Parent'},
      {'label': 'Relationship', 'value': profile['parentRelationship'], 'section': 'Parent'},
      {'label': 'Parent Phone', 'value': profile['parentPhone'], 'section': 'Parent'},
    ]);
    
    int completedCount = allFields.where((f) => f['value'] != null && f['value'].toString().isNotEmpty).length;
    int totalCount = allFields.length;
    double progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 50, 
                backgroundImage: profile['profilePhotoUrl'] != null 
                    ? NetworkImage(profile['profilePhotoUrl']) 
                    : null,
                child: profile['profilePhotoUrl'] == null ? const Icon(Icons.person, size: 50) : null,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => _pickAndUploadImage(context, context.read<StudentProvider>()),
                    icon: const Icon(Icons.camera_alt),
                    label: Text(profile['profilePhotoUrl'] == null ? 'Add Profile Photo' : 'Change Profile Photo'),
                  ),
                  if (profile['profilePhotoUrl'] != null)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmRemovePhoto(context, context.read<StudentProvider>()),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        Center(
          child: Column(
            children: [
              Text(
                'Student ID: ${profile['studentCode'] ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Tuition Joining Date: ${_formatDate(profile['tuitionJoiningDate'])}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        if (isIncomplete) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Profile incomplete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Complete your details to keep your information up to date.', style: TextStyle(color: Colors.black87)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Progress Bar
        Text('Profile Completion', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          color: progress == 1.0 ? Colors.green : Colors.blue,
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
        const SizedBox(height: 8),
        Text(
          progress == 1.0 
              ? 'Profile Completed (100%)' 
              : '$completedCount of $totalCount required details completed (${(progress * 100).toInt()}%)',
          style: TextStyle(color: progress == 1.0 ? Colors.green : Colors.black54, fontWeight: progress == 1.0 ? FontWeight.bold : FontWeight.normal),
        ),
        const SizedBox(height: 24),
        
        _buildChecklistSection('Personal Information', allFields.where((f) => f['section'] == 'Personal').toList(), isIncomplete),
        _buildChecklistSection('Academic Information', allFields.where((f) => f['section'] == 'Academic').toList(), isIncomplete),
        _buildChecklistSection('Parent / Guardian', allFields.where((f) => f['section'] == 'Parent').toList(), isIncomplete),
        
        const SizedBox(height: 32),
        Center(
          child: ElevatedButton(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileCompletionScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isIncomplete ? Colors.blue : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(isIncomplete ? 'Complete Profile' : 'Edit Profile'),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistSection(String title, List<Map<String, dynamic>> fields, bool showIcons) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
        const Divider(),
        ...fields.map((f) {
          bool isComplete = f['value'] != null && f['value'].toString().isNotEmpty;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(f['label'])),
                if (!showIcons) 
                  Expanded(flex: 3, child: Text(f['value']?.toString() ?? '-', style: const TextStyle(color: Colors.black54)))
                else
                  isComplete 
                    ? const Icon(Icons.check, color: Colors.green, size: 20)
                    : const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _pickAndUploadImage(BuildContext context, StudentProvider provider) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Basic compression
      );
      
      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      final sizeInBytes = bytes.length;
      if (sizeInBytes > 5 * 1024 * 1024) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image is too large. Please select an image below 5 MB.')));
        }
        return;
      }

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dCtx) => AlertDialog(
            title: const Text('Preview'),
            content: Image.memory(bytes),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Choose Another')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dCtx);
                  final error = await provider.uploadProfilePhoto(bytes, pickedFile.name);
                  if (context.mounted) {
                    if (error == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated'), backgroundColor: Colors.green));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                    }
                  }
                },
                child: const Text('Upload Photo'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open gallery or select image.')));
      }
    }
  }

  Future<void> _confirmRemovePhoto(BuildContext context, StudentProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Profile Photo?'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      )
    );
    
    if (confirm == true && context.mounted) {
      final error = await provider.removeProfilePhoto();
      if (context.mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo removed'), backgroundColor: Colors.green));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
        }
      }
    }
  }
}


