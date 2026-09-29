import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../providers/student_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../profile_completion_screen.dart';
import '../../../widgets/components.dart';
import '../../../../core/theme/design_system.dart';

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
        backgroundColor: FTColors.surface,
      ),
      body: provider.isLoading 
          ? const Center(child: FTLoading())
          : _buildBody(context, provider.profile, isIncomplete),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic>? profile, bool isIncomplete) {
    if (profile == null) return Center(child: Text('Profile not found', style: FTTypography.bodyLarge));
    if (profile.containsKey('error')) {
      return Center(
        child: Text(
          profile['error'].toString(),
          textAlign: TextAlign.center,
          style: FTTypography.bodyLarge.copyWith(color: FTColors.error),
        ),
      );
    }
    
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
      padding: const EdgeInsets.all(FTSpacing.md),
      children: [
        Center(
          child: Column(
            children: [
              FTAvatar(
                radius: 50,
                imageUrl: profile['profilePhotoUrl'],
              ),
              const SizedBox(height: FTSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => _pickAndUploadImage(context, context.read<StudentProvider>()),
                    icon: const Icon(Icons.camera_alt, color: FTColors.primary),
                    label: Text(profile['profilePhotoUrl'] == null ? 'Add Photo' : 'Change Photo', style: FTTypography.button.copyWith(color: FTColors.primary)),
                  ),
                  if (profile['profilePhotoUrl'] != null)
                    IconButton(
                      icon: const Icon(Icons.delete, color: FTColors.error),
                      onPressed: () => _confirmRemovePhoto(context, context.read<StudentProvider>()),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: FTSpacing.md),
        
        Center(
          child: Column(
            children: [
              Text(
                'Student ID: ${profile['studentCode'] ?? 'N/A'}',
                style: FTTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: FTSpacing.xxs),
              Text(
                'Tuition Joining Date: ${_formatDate(profile['tuitionJoiningDate'])}',
                style: FTTypography.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: FTSpacing.xl),
        
        if (isIncomplete) ...[
          Container(
            padding: const EdgeInsets.all(FTSpacing.md),
            decoration: BoxDecoration(
              color: FTColors.secondaryLight,
              borderRadius: BorderRadius.circular(FTRadius.medium),
              border: Border.all(color: FTColors.warning.withAlpha(128)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: FTColors.warning),
                    const SizedBox(width: FTSpacing.sm),
                    Text('Profile incomplete', style: FTTypography.bodyLarge.copyWith(color: FTColors.warning, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: FTSpacing.sm),
                Text('Complete your details to keep your information up to date.', style: FTTypography.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: FTSpacing.md),
        ],

        FTCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profile Completion', style: FTTypography.heading3),
              const SizedBox(height: FTSpacing.md),
              FTProgressIndicator(
                value: progress,
                color: progress == 1.0 ? FTColors.success : FTColors.primary,
              ),
              const SizedBox(height: FTSpacing.sm),
              Text(
                progress == 1.0 
                    ? 'Profile Completed (100%)' 
                    : '$completedCount of $totalCount required details completed (${(progress * 100).toInt()}%)',
                style: FTTypography.bodySmall.copyWith(
                  color: progress == 1.0 ? FTColors.success : FTColors.textSecondary,
                  fontWeight: progress == 1.0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: FTSpacing.xl),
        
        _buildChecklistSection('Personal Information', allFields.where((f) => f['section'] == 'Personal').toList(), isIncomplete),
        _buildChecklistSection('Academic Information', allFields.where((f) => f['section'] == 'Academic').toList(), isIncomplete),
        _buildChecklistSection('Parent / Guardian', allFields.where((f) => f['section'] == 'Parent').toList(), isIncomplete),
        
        const SizedBox(height: FTSpacing.xl),
        Center(
          child: FTButton(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileCompletionScreen()));
            },
            text: isIncomplete ? 'Complete Profile' : 'Edit Profile',
          ),
        ),
        const SizedBox(height: FTSpacing.xl),
      ],
    );
  }

  Widget _buildChecklistSection(String title, List<Map<String, dynamic>> fields, bool showIcons) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FTSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: FTTypography.heading3.copyWith(color: FTColors.primary)),
          const Divider(color: FTColors.border, height: FTSpacing.xl),
          ...fields.map((f) {
            bool isComplete = f['value'] != null && f['value'].toString().isNotEmpty;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: FTSpacing.xs),
              child: Row(
                children: [
                  Expanded(flex: 2, child: Text(f['label'], style: FTTypography.body)),
                  if (!showIcons) 
                    Expanded(flex: 3, child: Text(f['value']?.toString() ?? '-', style: FTTypography.body.copyWith(color: FTColors.textSecondary)))
                  else
                    isComplete 
                      ? const Icon(Icons.check_circle, color: FTColors.success, size: 20)
                      : const Icon(Icons.warning_amber_rounded, color: FTColors.warning, size: 20),
                ],
              ),
            );
          }),
        ],
      ),
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
          builder: (dCtx) => FTDialog(
            title: 'Preview',
            content: Image.memory(bytes),
            actions: [
              FTButton(onPressed: () => Navigator.pop(dCtx), text: 'Choose Another', isSecondary: true),
              FTButton(
                onPressed: () async {
                  Navigator.pop(dCtx);
                  final error = await provider.uploadProfilePhoto(bytes, pickedFile.name);
                  if (context.mounted) {
                    if (error == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated'), backgroundColor: FTColors.success));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: FTColors.error));
                    }
                  }
                },
                text: 'Upload Photo',
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open gallery or select image.'), backgroundColor: FTColors.error));
      }
    }
  }

  Future<void> _confirmRemovePhoto(BuildContext context, StudentProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => FTDialog(
        title: 'Remove Profile Photo?',
        content: Text('Are you sure?', style: FTTypography.body),
        actions: [
          FTButton(onPressed: () => Navigator.pop(ctx, false), text: 'Cancel', isSecondary: true),
          FTButton(onPressed: () => Navigator.pop(ctx, true), text: 'Remove', isDestructive: true),
        ],
      )
    );
    
    if (confirm == true && context.mounted) {
      final error = await provider.removeProfilePhoto();
      if (context.mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo removed'), backgroundColor: FTColors.success));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: FTColors.error));
        }
      }
    }
  }
}
