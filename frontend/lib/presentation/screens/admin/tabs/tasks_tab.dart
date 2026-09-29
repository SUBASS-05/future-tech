import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/admin_provider.dart';
import '../../../widgets/ft_card.dart';
import '../../../widgets/ft_text_field.dart';
import '../../../widgets/ft_button.dart';
import '../../../../core/utils/date_formatter.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _estimatedMinutesController = TextEditingController();

  String _priority = 'MEDIUM';
  DateTime? _dueDate;
  List<int> _selectedStudentIds = [];
  
  List<dynamic> _taskHistory = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchStudents();
      context.read<AdminProvider>().fetchTasks();
      _fetchHistory();
    });
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoadingHistory = true);
    final history = await context.read<AdminProvider>().fetchTaskHistory();
    if (mounted) {
      setState(() {
        _taskHistory = history;
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _createTask() async {
    if (_formKey.currentState!.validate()) {
      if (_dueDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a due date and time.'), backgroundColor: Colors.red),
        );
        return;
      }
      if (_selectedStudentIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one student.'), backgroundColor: Colors.red),
        );
        return;
      }

      final provider = context.read<AdminProvider>();
      final error = await provider.createTask(
        _titleController.text.trim(),
        _descController.text.trim(),
        _priority,
        _dueDate,
        int.tryParse(_estimatedMinutesController.text.trim()),
        _selectedStudentIds,
      );

      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task assigned successfully!'), backgroundColor: Colors.green),
          );
          _titleController.clear();
          _descController.clear();
          _estimatedMinutesController.clear();
          setState(() {
            _priority = 'MEDIUM';
            _dueDate = null;
            _selectedStudentIds.clear();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _openStudentSelection(List<dynamic> students) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FractionallySizedBox(
              heightFactor: 0.8,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Select Students', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final isSelected = _selectedStudentIds.contains(student['studentId']);
                          return ListTile(
                            leading: Checkbox(
                              value: isSelected,
                              activeColor: const Color(0xFF168A55),
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true) {
                                    _selectedStudentIds.add(student['studentId']);
                                  } else {
                                    _selectedStudentIds.remove(student['studentId']);
                                  }
                                });
                                setState(() {});
                              },
                            ),
                            title: Text(student['fullName'] ?? 'Unknown'),
                            subtitle: Text(student['institutionName'] ?? ''),
                          );
                        },
                      ),
                    ),
                    FTButton(
                      text: 'DONE',
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openTaskProgress(BuildContext context, dynamic task, {bool isHistory = false}) async {
    final taskId = task['id'] is int ? task['id'] : (task['id'] as num).toInt();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return FutureBuilder<dynamic>(
          future: context.read<AdminProvider>().getTaskProgress(taskId),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator(color: Color(0xFF168A55))),
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('Failed to load progress.')),
              );
            }

            final progress = snapshot.data as Map<String, dynamic>;
            final students = (progress['students'] as List<dynamic>?) ?? [];
            final total = progress['totalAssigned'] ?? 0;
            final completed = progress['completed'] ?? 0;
            final inProgress = progress['inProgress'] ?? 0;
            final pending = progress['pending'] ?? 0;
            final overdue = progress['overdue'] ?? 0;
            final expired = progress['expired'] ?? 0;
            final percentage = (progress['completionPercentage'] ?? 0.0).toDouble();
            
            final dueAtStr = progress['dueAt'];
            final expiresAtStr = progress['expiresAt'];

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              minChildSize: 0.4,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Header
                      Row(
                        children: [
                          const Icon(Icons.bar_chart, color: Color(0xFF168A55)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              progress['title'] ?? 'Task Progress',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (dueAtStr != null)
                        Text('Due: ${formatDateTime(dueAtStr)}', style: const TextStyle(color: Colors.grey)),
                      if (isHistory && expiresAtStr != null)
                        Text('Expired: ${formatDateTime(expiresAtStr)}', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),

                      // Progress Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Completion', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('${percentage.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF168A55))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 12,
                          backgroundColor: Colors.grey[200],
                          color: percentage == 100 ? Colors.green : const Color(0xFF168A55),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Stats Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _statChip('Total', total, Colors.blue),
                          _statChip('Done', completed, Colors.green),
                          _statChip('Active', inProgress, Colors.orange),
                          _statChip('Pending', pending, Colors.grey),
                          if (overdue > 0) _statChip('Overdue', overdue, Colors.amber),
                          if (expired > 0) _statChip('Expired', expired, Colors.red),
                        ],
                      ),
                      const SizedBox(height: 20),

                      const Text('Students', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Divider(),

                      // Student List
                      if (students.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: Text('No students assigned.')),
                        )
                      else
                        ...students.map((s) => _buildStudentProgressTile(s)).toList(),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _buildStudentProgressTile(Map<String, dynamic> student) {
    final status = student['status'] ?? 'PENDING';
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'COMPLETED':
        statusColor = Colors.green;
        statusIcon = Icons.check;
        break;
      case 'IN_PROGRESS':
        statusColor = Colors.orange;
        statusIcon = Icons.circle;
        break;
      case 'OVERDUE':
        statusColor = Colors.amber;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case 'EXPIRED':
        statusColor = Colors.red;
        statusIcon = Icons.close;
        break;
      case 'PENDING':
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.radio_button_unchecked;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  student['studentName'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withAlpha(100)),
                ),
                child: Text(
                  status.replaceAll('_', ' '),
                  style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (student['dueAt'] != null) ...[
            const SizedBox(height: 4),
            Text('Due: ${formatDateTime(student['dueAt'])}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
          if (student['expiresAt'] != null) ...[
            const SizedBox(height: 4),
            Text('Expires: ${formatDateTime(student['expiresAt'])}', style: TextStyle(fontSize: 12, color: Colors.red[600])),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _estimatedMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final isLoading = provider.isLoading;
    final students = provider.students;
    final tasks = provider.tasks;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FTCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Assign a New Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  FTTextField(
                    controller: _titleController,
                    label: 'Task Title (Required)',
                    validator: (val) => val == null || val.isEmpty ? 'Please enter a task title.' : null,
                  ),
                  const SizedBox(height: 16),
                  FTTextField(
                    controller: _descController,
                    label: 'Task Description (Optional)',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    value: _priority,
                    items: const [
                      DropdownMenuItem(value: 'LOW', child: Text('Low')),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                      DropdownMenuItem(value: 'HIGH', child: Text('High')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _priority = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Due Date + Time Picker
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null && mounted) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          final selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                          if (selected.isBefore(DateTime.now())) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Due date must be in the future.'), backgroundColor: Colors.red));
                            }
                          } else {
                            setState(() => _dueDate = selected);
                          }
                        }
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due Date & Time (Required)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        suffixIcon: Icon(Icons.calendar_today, color: Color(0xFF168A55)),
                      ),
                      child: Text(
                        _dueDate != null ? formatDateTime(_dueDate!.toIso8601String()) : 'Select Date & Time',
                        style: TextStyle(color: _dueDate != null ? Colors.black : Colors.grey[500]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FTTextField(
                    controller: _estimatedMinutesController,
                    label: 'Estimated Minutes (Optional)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _openStudentSelection(students),
                    icon: const Icon(Icons.people, color: Color(0xFF168A55)),
                    label: Text(
                      'Select Students (${_selectedStudentIds.length} selected)',
                      style: const TextStyle(color: Color(0xFF168A55)),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF168A55)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FTButton(
                    onPressed: isLoading ? null : _createTask,
                    isLoading: isLoading,
                    text: 'ASSIGN TASK',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          const Text('Active Tasks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (tasks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No active tasks.', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...tasks.map((task) => _buildTaskCard(task, isHistory: false)).toList(),
            
          const SizedBox(height: 32),
          const Text('Task History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_isLoadingHistory)
            const Center(child: CircularProgressIndicator(color: Color(0xFF168A55)))
          else if (_taskHistory.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No historical tasks.', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ..._taskHistory.map((task) => _buildTaskCard(task, isHistory: true)).toList(),
        ],
      ),
    );
  }

  Widget _buildTaskCard(dynamic task, {required bool isHistory}) {
    final priority = task['priority'] ?? 'MEDIUM';
    Color priorityColor = priority == 'HIGH' ? Colors.red : priority == 'LOW' ? Colors.green : Colors.orange;
    
    // Calculate stats if available in the summary
    final assigned = task['assignedCount'] ?? task['totalAssigned'] ?? 0;
    final completed = task['completedCount'] ?? task['completed'] ?? 0;
    final pending = task['pendingCount'] ?? 0;
    final inProgress = task['inProgressCount'] ?? 0;
    final overdue = task['overdueCount'] ?? 0;
    
    String statsText = '$assigned assigned • $completed completed';
    if (isHistory) {
      final rate = assigned > 0 ? (completed / assigned * 100).toStringAsFixed(0) : '0';
      statsText = '$rate% completed ($completed/$assigned)';
    }

    return FTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task['title'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: priorityColor.withAlpha(100)),
                ),
                child: Text(
                  priority,
                  style: TextStyle(fontSize: 12, color: priorityColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(statsText, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          if (task['dueAt'] != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Due: ${formatDateTime(task['dueAt'])}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ],
          if (!isHistory) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (pending > 0) Text('Pending: $pending', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (inProgress > 0) Text('In Progress: $inProgress', style: const TextStyle(color: Colors.orange, fontSize: 12)),
                if (overdue > 0) Text('Overdue: $overdue', style: const TextStyle(color: Colors.amber, fontSize: 12)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openTaskProgress(context, task, isHistory: isHistory),
              icon: const Icon(Icons.bar_chart, color: Color(0xFF168A55)),
              label: Text(isHistory ? 'View Results' : 'View Progress', style: const TextStyle(color: Color(0xFF168A55))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF168A55)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
