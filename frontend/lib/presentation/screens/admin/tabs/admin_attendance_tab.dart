import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/admin_provider.dart';
import '../../../widgets/ft_card.dart';
import '../../../widgets/ft_text_field.dart';
import '../../../widgets/ft_button.dart';
import '../../../../core/utils/date_formatter.dart';

class AdminAttendanceTab extends StatefulWidget {
  const AdminAttendanceTab({super.key});

  @override
  State<AdminAttendanceTab> createState() => _AdminAttendanceTabState();
}

class _AdminAttendanceTabState extends State<AdminAttendanceTab> with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  String _selectedStatusFilter = 'ALL';
  late TabController _viewTabController;

  @override
  void initState() {
    super.initState();
    _viewTabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final provider = context.read<AdminProvider>();
    provider.fetchDailyAttendance(_selectedDate);
    provider.fetchLeaveRequests();
    provider.fetchLowAttendanceStudents();
  }

  @override
  void dispose() {
    _viewTabController.dispose();
    super.dispose();
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    context.read<AdminProvider>().fetchDailyAttendance(_selectedDate);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      context.read<AdminProvider>().fetchDailyAttendance(_selectedDate);
    }
  }

  bool get _isFutureDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return selected.isAfter(today);
  }

  void _bulkMarkPresent() async {
    if (_isFutureDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance cannot be marked or modified for future dates.'), backgroundColor: Colors.amber),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bulk Mark Present'),
        content: const Text('Are you sure you want to mark all Unmarked students as Present for this date?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF168A55)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mark Present', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<AdminProvider>().bulkMarkAttendance(_selectedDate, 'PRESENT');
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unmarked students set to Present'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.read<AdminProvider>().error ?? 'Failed to bulk mark'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _updateStudentStatus(int studentId, String status) async {
    if (_isFutureDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance cannot be marked or modified for future dates.'), backgroundColor: Colors.amber),
      );
      return;
    }

    final success = await context.read<AdminProvider>().markAttendance(studentId, _selectedDate, status);
    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<AdminProvider>().error ?? 'Failed to update attendance'), backgroundColor: Colors.red),
      );
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
            controller: _viewTabController,
            labelColor: const Color(0xFF168A55),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF168A55),
            tabs: const [
              Tab(icon: Icon(Icons.fact_check), text: 'Daily Sheet'),
              Tab(icon: Icon(Icons.event_note), text: 'Leaves'),
              Tab(icon: Icon(Icons.warning_amber), text: 'Low Attendance'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _viewTabController,
            children: [
              _buildDailySheetTab(),
              _buildLeavesTab(),
              _buildLowAttendanceTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailySheetTab() {
    final provider = context.watch<AdminProvider>();
    final data = provider.dailyAttendance;
    final isLoading = provider.isLoading;

    if (isLoading && data == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF168A55)));
    }

    final int total = data?['totalStudents'] ?? 0;
    final int present = data?['presentCount'] ?? 0;
    final int absent = data?['absentCount'] ?? 0;
    final int leave = data?['leaveCount'] ?? 0;
    final int notMarked = data?['notMarkedCount'] ?? 0;
    final double rate = (data?['attendanceRate'] ?? 0.0).toDouble();
    final List<dynamic> records = data?['records'] ?? [];

    final filtered = records.filter((r) {
      final String name = (r['studentName'] ?? '').toString().toLowerCase();
      final String code = (r['studentCode'] ?? '').toString().toLowerCase();
      final String status = r['status'] ?? 'NOT_MARKED';
      final matchesSearch = name.contains(_searchQuery.toLowerCase()) || code.contains(_searchQuery.toLowerCase());
      final matchesStatus = _selectedStatusFilter == 'ALL' || status == _selectedStatusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async => provider.fetchDailyAttendance(_selectedDate),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isFutureDate) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Future Date: Attendance cannot be marked or modified for future dates.',
                        style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Date Selector Bar
            FTCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeDate(-1),
                  ),
                  InkWell(
                    onTap: _pickDate,
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, color: Color(0xFF168A55)),
                        const SizedBox(width: 8),
                        Text(
                          formatDate(_selectedDate.toIso8601String()),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeDate(1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary Grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _summaryTile('Total', '$total', Colors.blue),
                _summaryTile('Present', '$present', Colors.green),
                _summaryTile('Absent', '$absent', Colors.red),
                _summaryTile('Leave', '$leave', Colors.orange),
                _summaryTile('Not Marked', '$notMarked', Colors.grey),
                _summaryTile('Rate', '${rate.toStringAsFixed(1)}%', const Color(0xFF168A55)),
              ],
            ),
            const SizedBox(height: 16),

            // Bulk Mark Action Bar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isFutureDate ? null : _bulkMarkPresent,
                    icon: Icon(Icons.done_all, color: _isFutureDate ? Colors.grey : const Color(0xFF168A55)),
                    label: Text('Mark Unmarked as Present', style: TextStyle(color: _isFutureDate ? Colors.grey : const Color(0xFF168A55))),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: _isFutureDate ? Colors.grey.shade300 : const Color(0xFF168A55)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Box
            FTTextField(
              label: 'Search Students by name or code',
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 12),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('ALL', 'All'),
                  _filterChip('PRESENT', 'Present'),
                  _filterChip('ABSENT', 'Absent'),
                  _filterChip('LEAVE', 'Leave'),
                  _filterChip('NOT_MARKED', 'Not Marked'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Student List
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No students found for current filter.', style: TextStyle(color: Colors.grey))),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (ctx, idx) => _buildStudentAttendanceTile(filtered[idx]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = _selectedStatusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFF168A55),
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        onSelected: (val) {
          if (val) setState(() => _selectedStatusFilter = value);
        },
      ),
    );
  }

  Widget _summaryTile(String title, String value, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 48) / 3,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStudentAttendanceTile(dynamic record) {
    final int sId = record['studentId'];
    final String name = record['studentName'] ?? 'Unknown';
    final String code = record['studentCode'] ?? '';
    final String dept = record['department'] ?? record['institution'] ?? '';
    final String status = record['status'] ?? 'NOT_MARKED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: FTCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF168A55).withAlpha(30),
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S', style: const TextStyle(color: Color(0xFF168A55), fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (code.isNotEmpty || dept.isNotEmpty)
                        Text('$code • $dept', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Status Selector Buttons
            Row(
              children: [
                _statusBtn(sId, 'PRESENT', 'Present', Colors.green, status),
                const SizedBox(width: 6),
                _statusBtn(sId, 'ABSENT', 'Absent', Colors.red, status),
                const SizedBox(width: 6),
                _statusBtn(sId, 'LEAVE', 'Leave', Colors.orange, status),
                const SizedBox(width: 6),
                _statusBtn(sId, 'NOT_MARKED', 'Reset', Colors.grey, status),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _statusBtn(int studentId, String targetStatus, String label, Color color, String currentStatus) {
    final bool isSelected = currentStatus == targetStatus;
    final bool isDisabled = _isFutureDate;
    return Expanded(
      child: InkWell(
        onTap: isDisabled ? null : () => _updateStudentStatus(studentId, targetStatus),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDisabled
                ? Colors.grey.shade200
                : (isSelected ? color : color.withAlpha(20)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDisabled ? Colors.grey.shade300 : color),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDisabled ? Colors.grey : (isSelected ? Colors.white : color),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeavesTab() {
    final provider = context.watch<AdminProvider>();
    final requests = provider.leaveRequests;

    return RefreshIndicator(
      onRefresh: () async => provider.fetchLeaveRequests(),
      child: requests.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: const Center(child: Text('No leave requests found.', style: TextStyle(color: Colors.grey))),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (ctx, idx) {
                final req = requests[idx];
                final int lId = req['id'];
                final String sName = req['studentName'] ?? 'Student';
                final String sCode = req['studentCode'] ?? '';
                final String status = req['status'] ?? 'PENDING';
                final String start = req['startDate'] ?? '';
                final String end = req['endDate'] ?? '';
                final String reason = req['reason'] ?? '';

                Color statusColor = status == 'APPROVED' ? Colors.green : (status == 'REJECTED' ? Colors.red : Colors.orange);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: FTCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  if (sCode.isNotEmpty) Text(sCode, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Dates: $start to $end', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('Reason: $reason', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        if (status == 'PENDING') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  onPressed: () async {
                                    final ok = await provider.reviewLeaveRequest(lId, 'APPROVED');
                                    if (mounted) {
                                      if (ok) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave Approved successfully! Moved to History.'), backgroundColor: Colors.green));
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Failed to approve leave request'), backgroundColor: Colors.red));
                                      }
                                    }
                                  },
                                  child: const Text('APPROVE', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                                  onPressed: () async {
                                    final ok = await provider.reviewLeaveRequest(lId, 'REJECTED');
                                    if (mounted) {
                                      if (ok) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave Rejected. Moved to History.'), backgroundColor: Colors.red));
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? 'Failed to reject leave request'), backgroundColor: Colors.red));
                                      }
                                    }
                                  },
                                  child: const Text('REJECT', style: TextStyle(color: Colors.red)),
                                ),
                              ),
                            ],
                          )
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildLowAttendanceTab() {
    final provider = context.watch<AdminProvider>();
    final lowList = provider.lowAttendanceStudents;

    return RefreshIndicator(
      onRefresh: () async => provider.fetchLowAttendanceStudents(),
      child: lowList.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: const Center(child: Text('No students with low attendance (<75%).', style: TextStyle(color: Colors.grey))),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: lowList.length,
              itemBuilder: (ctx, idx) {
                final item = lowList[idx];
                final String name = item['studentName'] ?? '';
                final String code = item['studentCode'] ?? '';
                final double pct = (item['attendancePercentage'] ?? 0.0).toDouble();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: FTCard(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.redAccent,
                        child: Icon(Icons.warning, color: Colors.white),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('$code • ${item['department'] ?? ''}'),
                      trailing: Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

extension IterableExtension<T> on Iterable<T> {
  Iterable<T> filter(bool Function(T element) test) => where(test);
}
