import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/student_provider.dart';
import '../../../widgets/ft_card.dart';
import '../../../widgets/ft_text_field.dart';
import '../../../widgets/ft_button.dart';
import '../../../../core/utils/date_formatter.dart';

class AttendanceTab extends StatefulWidget {
  const AttendanceTab({super.key});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _leaveFormKey = GlobalKey<FormState>();
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().fetchAttendance();
      context.read<StudentProvider>().fetchLeaveRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitLeave() async {
    if (_leaveFormKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select start and end dates.'), backgroundColor: Colors.red),
        );
        return;
      }
      if (_endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End date cannot be before start date.'), backgroundColor: Colors.red),
        );
        return;
      }

      final provider = context.read<StudentProvider>();
      final error = await provider.applyLeave(_startDate!, _endDate!, _reasonController.text.trim());

      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Leave request submitted successfully!'), backgroundColor: Colors.green),
          );
          _reasonController.clear();
          setState(() {
            _startDate = null;
            _endDate = null;
          });
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
    return Column(
      children: [
        Material(
          color: Colors.white,
          elevation: 1,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF168A55),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF168A55),
            tabs: const [
              Tab(icon: Icon(Icons.bar_chart), text: 'My Attendance'),
              Tab(icon: Icon(Icons.event_available), text: 'Leave Requests'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAttendanceOverview(),
              _buildLeaveRequestsView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceOverview() {
    final provider = context.watch<StudentProvider>();
    final summary = provider.attendanceSummary;
    final history = provider.attendance;

    if (provider.isLoading && summary == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF168A55)));
    }

    final double percentage = (summary?['attendancePercentage'] ?? 0.0).toDouble();
    final int present = summary?['presentCount'] ?? 0;
    final int absent = summary?['absentCount'] ?? 0;
    final int leave = summary?['leaveCount'] ?? 0;
    final int evaluated = summary?['totalEvaluatedDays'] ?? (present + absent);

    return RefreshIndicator(
      onRefresh: () async => provider.fetchAttendance(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Main Percentage Card
          FTCard(
            child: Column(
              children: [
                const Text('Attendance Score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: percentage >= 75 ? const Color(0xFF168A55) : Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 12,
                    backgroundColor: Colors.grey[200],
                    color: percentage >= 75 ? const Color(0xFF168A55) : Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('Present', '$present', Colors.green),
                    _statItem('Absent', '$absent', Colors.red),
                    _statItem('Leave', '$leave', Colors.orange),
                    _statItem('Evaluated', '$evaluated', Colors.blue),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Note: Attendance % = Present / (Present + Absent) × 100. Approved Leave days are not penalized.',
              style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Attendance History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No attendance records logged yet.', style: TextStyle(color: Colors.grey))),
            )
          else
            ...history.map((rec) {
              final String status = rec['status'] ?? 'NOT_MARKED';
              final String dateStr = rec['attendanceDate'] ?? '';
              final String? remarks = rec['remarks'];

              Color statusColor;
              IconData statusIcon;

              switch (status) {
                case 'PRESENT':
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle_outline;
                  break;
                case 'ABSENT':
                  statusColor = Colors.red;
                  statusIcon = Icons.highlight_off;
                  break;
                case 'LEAVE':
                  statusColor = Colors.orange;
                  statusIcon = Icons.event_busy;
                  break;
                default:
                  statusColor = Colors.grey;
                  statusIcon = Icons.help_outline;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: FTCard(
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formatDate(dateStr), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            if (remarks != null && remarks.isNotEmpty)
                              Text(remarks, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _buildLeaveRequestsView() {
    final provider = context.watch<StudentProvider>();
    final leaves = provider.leaveRequests;

    return RefreshIndicator(
      onRefresh: () async => provider.fetchLeaveRequests(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leave Application Form Card
            FTCard(
              child: Form(
                key: _leaveFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Apply for Leave', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                              );
                              if (picked != null) setState(() => _startDate = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                              ),
                              child: Text(_startDate != null ? formatDate(_startDate!.toIso8601String()) : 'Select Date'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate ?? DateTime.now(),
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                              );
                              if (picked != null) setState(() => _endDate = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                              ),
                              child: Text(_endDate != null ? formatDate(_endDate!.toIso8601String()) : 'Select Date'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FTTextField(
                      controller: _reasonController,
                      label: 'Reason for Leave',
                      maxLines: 3,
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a reason.' : null,
                    ),
                    const SizedBox(height: 16),
                    FTButton(
                      text: 'SUBMIT LEAVE REQUEST',
                      isLoading: provider.isLoading,
                      onPressed: _submitLeave,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Active / Pending Leave Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (leaves.where((l) => l['status'] == 'PENDING').isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No active pending leave requests.', style: TextStyle(color: Colors.grey)),
              )
            else
              ...leaves.where((l) => l['status'] == 'PENDING').map((l) {
                final String status = l['status'] ?? 'PENDING';
                final String start = l['startDate'] ?? '';
                final String end = l['endDate'] ?? '';
                final String reason = l['reason'] ?? '';
                final String? remarks = l['adminRemarks'];
                Color statusColor = Colors.orange;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: FTCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$start to $end', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Reason: $reason', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        if (remarks != null && remarks.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Admin Note: $remarks', style: const TextStyle(color: Colors.blueGrey, fontSize: 13, fontStyle: FontStyle.italic)),
                        ]
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),
            const Text('Leave Request History (Archived)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),

            if (leaves.where((l) => l['status'] != 'PENDING').isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No leave request history.', style: TextStyle(color: Colors.grey)),
              )
            else
              ...leaves.where((l) => l['status'] != 'PENDING').map((l) {
                final String status = l['status'] ?? 'PENDING';
                final String start = l['startDate'] ?? '';
                final String end = l['endDate'] ?? '';
                final String reason = l['reason'] ?? '';
                final String? remarks = l['adminRemarks'];
                Color statusColor = status == 'APPROVED' ? Colors.green : Colors.red;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: FTCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$start to $end', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Reason: $reason', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        if (remarks != null && remarks.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Admin Note: $remarks', style: const TextStyle(color: Colors.blueGrey, fontSize: 13, fontStyle: FontStyle.italic)),
                        ]
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
