import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/student_provider.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    final profile = provider.profile;
    if (profile == null) return const Center(child: Text('Profile not found'));
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
        const SizedBox(height: 16),
        Text(profile['firstName'] ?? 'Student', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 32),
        ListTile(leading: const Icon(Icons.badge), title: const Text('Student Code'), subtitle: Text(profile['studentCode'] ?? '')),
        ListTile(leading: const Icon(Icons.school), title: const Text('Institution'), subtitle: Text(profile['institutionName'] ?? '')),
        ListTile(leading: const Icon(Icons.info), title: const Text('Status'), subtitle: Text(profile['status'] ?? '')),
      ],
    );
  }
}
