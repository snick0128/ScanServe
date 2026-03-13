import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/admin_theme.dart';
import '../../providers/staff_provider.dart';
import '../../providers/admin_auth_provider.dart';
import '../../../models/staff_profile.dart';
import '../../../models/staff_shift.dart';
import '../../../models/staff_task.dart';
import '../../../models/staff_payment.dart';
import '../../../models/staff_notification.dart';
import '../../../models/staff_attendance.dart';
import '../../services/export_service.dart';
import 'package:scan_serve/utils/screen_scale.dart';

class StaffManagementScreen extends StatefulWidget {
  final String tenantId;
  const StaffManagementScreen({super.key, required this.tenantId});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  String? _selectedStaffId;

  @override
  Widget build(BuildContext context) {
    return Consumer2<StaffProvider, AdminAuthProvider>(
      builder: (context, staffProvider, auth, _) {
        if (auth.isCaptain) {
          return _buildCaptainView(context, staffProvider, auth);
        }

        return DefaultTabController(
          length: 8,
          child: Column(
            children: [
              _buildHeader(
                title: 'Staff Management',
                subtitle: 'Profiles, shifts, attendance, payments and reports',
                actions: [
                  TextButton.icon(
                    onPressed: () => _openStaffDialog(context, staffProvider),
                    icon: const Icon(Ionicons.add_outline),
                    label: const Text('Add Staff'),
                  ),
                ],
              ),
              TabBar(
                isScrollable: true,
                labelColor: AdminTheme.primaryColor,
                unselectedLabelColor: AdminTheme.secondaryText,
                indicatorColor: AdminTheme.primaryColor,
                tabs: const [
                  Tab(text: 'Staff'),
                  Tab(text: 'Attendance'),
                  Tab(text: 'Shifts'),
                  Tab(text: 'Tasks'),
                  Tab(text: 'Payments'),
                  Tab(text: 'Performance'),
                  Tab(text: 'Notify'),
                  Tab(text: 'Admin'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildStaffTab(context, staffProvider),
                    _buildAttendanceTab(context, staffProvider),
                    _buildShiftsTab(context, staffProvider),
                    _buildTasksTab(context, staffProvider),
                    _buildPaymentsTab(context, staffProvider),
                    _buildPerformanceTab(context, staffProvider),
                    _buildNotifyTab(context, staffProvider),
                    _buildAdminTab(context, staffProvider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader({
    required String title,
    required String subtitle,
    List<Widget>? actions,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 10.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.primaryText,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AdminTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          if (actions != null) ...actions,
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AdminTheme.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AdminTheme.dividerColor),
      ),
      child: child,
    );
  }

  Widget _buildStaffTab(BuildContext context, StaffProvider provider) {
    if (provider.isLoading && provider.staff.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.staff.isEmpty) {
      return Center(
        child: Text(
          'No staff added yet.',
          style: TextStyle(color: AdminTheme.secondaryText),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: provider.staff.length,
      itemBuilder: (context, index) {
        final staff = provider.staff[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: _buildCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22.r,
                  backgroundColor: AdminTheme.primaryColor.withOpacity(0.1),
                  child: staff.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            staff.photoUrl!,
                            width: 44.w,
                            height: 44.w,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Ionicons.person_outline,
                          color: AdminTheme.primaryColor,
                          size: 22.w,
                        ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.primaryText,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${staff.role.toUpperCase()} • ${staff.employeeId}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AdminTheme.secondaryText,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        staff.contact.isEmpty
                            ? 'Contact not set'
                            : staff.contact,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AdminTheme.secondaryText,
                        ),
                      ),
                      if (staff.email != null && staff.email!.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          staff.email!,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AdminTheme.secondaryText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: staff.isActive
                        ? AdminTheme.success.withOpacity(0.12)
                        : AdminTheme.critical.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    staff.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: staff.isActive
                          ? AdminTheme.success
                          : AdminTheme.critical,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  icon: const Icon(Ionicons.create_outline),
                  tooltip: 'Edit',
                  onPressed: () =>
                      _openStaffDialog(context, provider, staff: staff),
                ),
                IconButton(
                  icon: Icon(
                    staff.isActive
                        ? Ionicons.pause_outline
                        : Ionicons.play_outline,
                  ),
                  tooltip: staff.isActive ? 'Deactivate' : 'Activate',
                  onPressed: () =>
                      provider.setStaffActive(staff.id, !staff.isActive),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceTab(BuildContext context, StaffProvider provider) {
    final lateArrivals = provider.lateArrivals();
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _buildCard(
          child: Row(
            children: [
              Icon(Ionicons.time_outline, color: AdminTheme.info, size: 22.w),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Late alerts today: ${lateArrivals.length}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AdminTheme.primaryText,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _openPunchDialog(context, provider),
                child: const Text('Punch In/Out'),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Recent Attendance',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        if (provider.attendance.isEmpty)
          Text(
            'No attendance records yet.',
            style: TextStyle(color: AdminTheme.secondaryText, fontSize: 13.sp),
          )
        else
          ...provider.attendance.take(50).map((record) {
            final staffName = _staffName(provider, record.staffId);
            final clockOutText = record.clockOutAt != null
                ? DateFormat('hh:mm a').format(record.clockOutAt!)
                : '--';
            final hours = record.totalMinutes != null
                ? provider.formatHours(record.totalMinutes!)
                : '--';
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _buildCard(
                child: Row(
                  children: [
                    Icon(
                      record.status == 'late'
                          ? Ionicons.alert_circle_outline
                          : Ionicons.checkmark_circle_outline,
                      color: record.status == 'late'
                          ? AdminTheme.warning
                          : AdminTheme.success,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        '$staffName • ${DateFormat('MMM dd').format(record.clockInAt)}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${DateFormat('hh:mm a').format(record.clockInAt)} → $clockOutText',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AdminTheme.secondaryText,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      hours,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildShiftsTab(BuildContext context, StaffProvider provider) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _buildCard(
          child: Row(
            children: [
              Icon(
                Ionicons.calendar_outline,
                color: AdminTheme.info,
                size: 22.w,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Assign shifts for upcoming days',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
              TextButton(
                onPressed: () => _openShiftDialog(context, provider),
                child: const Text('Assign Shift'),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Upcoming Shifts',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        if (provider.shifts.isEmpty)
          Text(
            'No shifts scheduled.',
            style: TextStyle(color: AdminTheme.secondaryText, fontSize: 13.sp),
          )
        else
          ...provider.shifts.take(60).map((shift) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _buildCard(
                child: Row(
                  children: [
                    Icon(
                      Ionicons.calendar_outline,
                      color: AdminTheme.primaryColor,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        '${_staffName(provider, shift.staffId)} • ${DateFormat('MMM dd').format(shift.date)}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${DateFormat('hh:mm a').format(shift.startTime)} - ${DateFormat('hh:mm a').format(shift.endTime)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AdminTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildTasksTab(BuildContext context, StaffProvider provider) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _buildCard(
          child: Row(
            children: [
              Icon(
                Ionicons.clipboard_outline,
                color: AdminTheme.info,
                size: 22.w,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Assign tasks or orders to staff',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
              TextButton(
                onPressed: () => _openTaskDialog(context, provider),
                child: const Text('New Task'),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        if (provider.tasks.isEmpty)
          Text(
            'No tasks assigned.',
            style: TextStyle(color: AdminTheme.secondaryText, fontSize: 13.sp),
          )
        else
          ...provider.tasks.take(80).map((task) {
            final color = task.priority == 'urgent'
                ? AdminTheme.critical
                : AdminTheme.secondaryText;
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _buildCard(
                child: Row(
                  children: [
                    Icon(
                      task.priority == 'urgent'
                          ? Ionicons.flash_outline
                          : Ionicons.checkbox_outline,
                      color: color,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${_staffName(provider, task.staffId)} • ${task.status.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AdminTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) =>
                          provider.updateTaskStatus(task.id, value),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'assigned',
                          child: Text('Assigned'),
                        ),
                        PopupMenuItem(
                          value: 'in_progress',
                          child: Text('In Progress'),
                        ),
                        PopupMenuItem(value: 'done', child: Text('Done')),
                      ],
                      child: const Icon(Ionicons.ellipsis_vertical),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPaymentsTab(BuildContext context, StaffProvider provider) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _buildCard(
          child: Row(
            children: [
              Icon(Ionicons.cash_outline, color: AdminTheme.info, size: 22.w),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Track advances and payroll',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
              TextButton(
                onPressed: () => _openPaymentDialog(context, provider),
                child: const Text('Record Payment'),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Payment History',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        if (provider.payments.isEmpty)
          Text(
            'No payments recorded.',
            style: TextStyle(color: AdminTheme.secondaryText, fontSize: 13.sp),
          )
        else
          ...provider.payments.take(80).map((payment) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _buildCard(
                child: Row(
                  children: [
                    Icon(Ionicons.cash_outline, color: AdminTheme.success),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        '${_staffName(provider, payment.staffId)} • ${payment.type.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '₹${payment.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      DateFormat('MMM dd').format(payment.paidAt),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AdminTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        SizedBox(height: 16.h),
        Text(
          'Remaining Salary',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        ...provider.staff.map((staff) {
          final remaining = provider.remainingSalary(staff);
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: _buildCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      staff.name,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '₹${remaining.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: remaining == 0
                          ? AdminTheme.success
                          : AdminTheme.warning,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPerformanceTab(BuildContext context, StaffProvider provider) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        Text(
          'Performance Snapshot',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        if (provider.staff.isEmpty)
          Text(
            'No staff found.',
            style: TextStyle(color: AdminTheme.secondaryText, fontSize: 13.sp),
          )
        else
          ...provider.staff.map((staff) {
            final perf = provider.performanceForStaff(staff);
            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: _buildCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18.r,
                      backgroundColor: AdminTheme.primaryColor.withOpacity(0.1),
                      child: Icon(
                        Ionicons.star_outline,
                        color: AdminTheme.primaryColor,
                        size: 18.w,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staff.name,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Rating: ${staff.rating.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AdminTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Orders: ${perf['orders']}',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        Text(
                          'Revenue: ₹${(perf['revenue'] as double).toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildNotifyTab(BuildContext context, StaffProvider provider) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _buildCard(
          child: Row(
            children: [
              Icon(
                Ionicons.notifications_outline,
                color: AdminTheme.info,
                size: 22.w,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Send alerts for tasks, shifts, or payments',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
              TextButton(
                onPressed: () => _openNotificationDialog(context, provider),
                child: const Text('Send Notification'),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        if (provider.notifications.isEmpty)
          Text(
            'No notifications yet.',
            style: TextStyle(color: AdminTheme.secondaryText, fontSize: 13.sp),
          )
        else
          ...provider.notifications.take(80).map((note) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _buildCard(
                child: Row(
                  children: [
                    Icon(Ionicons.mail_outline, color: AdminTheme.primaryColor),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            note.message,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AdminTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd').format(note.createdAt),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AdminTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAdminTab(BuildContext context, StaffProvider provider) {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _buildCard(
          child: Row(
            children: [
              Icon(
                Ionicons.download_outline,
                color: AdminTheme.info,
                size: 22.w,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Export weekly or monthly staff reports',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
              TextButton(
                onPressed: () => ExportService.exportStaffReportToPdf(
                  provider,
                  period: const Duration(days: 7),
                  periodLabel: 'Weekly',
                ),
                child: const Text('Weekly PDF'),
              ),
              TextButton(
                onPressed: () => ExportService.exportStaffReportToPdf(
                  provider,
                  period: const Duration(days: 30),
                  periodLabel: 'Monthly',
                ),
                child: const Text('Monthly PDF'),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        _buildCard(
          child: Row(
            children: [
              Icon(
                Ionicons.person_add_outline,
                color: AdminTheme.primaryColor,
                size: 22.w,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Add or update staff roles, shifts, and payroll.',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
              TextButton(
                onPressed: () => _openStaffDialog(context, provider),
                child: const Text('Manage Staff'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCaptainView(
    BuildContext context,
    StaffProvider provider,
    AdminAuthProvider auth,
  ) {
    final staff = provider.selfStaff;
    if (staff == null) {
      return Center(
        child: Text(
          'Staff profile is being prepared. Please wait...',
          style: TextStyle(color: AdminTheme.secondaryText),
        ),
      );
    }

    final tasks = provider.tasksForStaff(staff.id);
    StaffAttendance? openAttendance;
    for (final entry in provider.attendanceForStaff(staff.id)) {
      if (entry.clockOutAt == null) {
        openAttendance = entry;
        break;
      }
    }

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _buildHeader(
          title: 'My Shift',
          subtitle: 'Clock in/out and view assigned tasks',
        ),
        _buildCard(
          child: Row(
            children: [
              Icon(Ionicons.time_outline, color: AdminTheme.info),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  openAttendance == null
                      ? 'You are currently clocked out'
                      : 'Clocked in at ${DateFormat('hh:mm a').format(openAttendance.clockInAt)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    if (openAttendance == null) {
                      await provider.clockIn(staff.id);
                    } else {
                      await provider.clockOut(staff.id);
                    }
                    _showSnack(
                      context,
                      openAttendance == null
                          ? 'Clocked in successfully'
                          : 'Clocked out successfully',
                    );
                  } catch (e) {
                    _showSnack(context, e.toString(), isError: true);
                  }
                },
                child: Text(openAttendance == null ? 'Clock In' : 'Clock Out'),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'My Tasks',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        if (tasks.isEmpty)
          Text(
            'No tasks assigned yet.',
            style: TextStyle(color: AdminTheme.secondaryText),
          )
        else
          ...tasks.map((task) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _buildCard(
                child: Row(
                  children: [
                    Icon(
                      task.priority == 'urgent'
                          ? Ionicons.flash_outline
                          : Ionicons.checkbox_outline,
                      color: task.priority == 'urgent'
                          ? AdminTheme.critical
                          : AdminTheme.secondaryText,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) =>
                          provider.updateTaskStatus(task.id, value),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'assigned',
                          child: Text('Assigned'),
                        ),
                        PopupMenuItem(
                          value: 'in_progress',
                          child: Text('In Progress'),
                        ),
                        PopupMenuItem(value: 'done', child: Text('Done')),
                      ],
                      child: const Icon(Ionicons.ellipsis_vertical),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  String _staffName(StaffProvider provider, String staffId) {
    final staff = provider.staff.firstWhere(
      (s) => s.id == staffId,
      orElse: () => StaffProfile(
        id: staffId,
        name: 'Unknown',
        contact: '',
        role: 'staff',
        employeeId: staffId,
        baseSalary: 0,
        payCycle: 'monthly',
        createdAt: DateTime.now(),
      ),
    );
    return staff.name;
  }

  Future<void> _openStaffDialog(
    BuildContext context,
    StaffProvider provider, {
    StaffProfile? staff,
  }) async {
    final nameController = TextEditingController(text: staff?.name ?? '');
    final contactController = TextEditingController(text: staff?.contact ?? '');
    final employeeIdController = TextEditingController(
      text: staff?.employeeId ?? '',
    );
    final shiftController = TextEditingController(
      text: staff?.shiftSchedule ?? '',
    );
    final salaryController = TextEditingController(
      text: staff?.baseSalary.toString() ?? '0',
    );
    final ratingController = TextEditingController(
      text: staff?.rating.toString() ?? '0',
    );
    final photoController = TextEditingController(text: staff?.photoUrl ?? '');
    final userIdController = TextEditingController(text: staff?.userId ?? '');
    final emailController = TextEditingController(text: staff?.email ?? '');
    final passwordController = TextEditingController();
    String role = staff?.role ?? 'captain';
    String payCycle = staff?.payCycle ?? 'monthly';
    bool createLogin = false;
    bool obscurePassword = true;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AdminTheme.cardBackground,
          title: Text(staff == null ? 'Add Staff' : 'Edit Staff'),
          content: SizedBox(
            width: 420.w,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _textField('Name', nameController),
                  _textField('Contact', contactController),
                  _textField('Employee ID', employeeIdController),
                  _textField(
                    'Shift Schedule (e.g. Mon-Fri 10-6)',
                    shiftController,
                  ),
                  _textField('Photo URL (optional)', photoController),
                  _textField('User UID (optional)', userIdController),
                  _textField('Login Email (optional)', emailController),
                  _textField('Base Salary', salaryController, isNumber: true),
                  _textField('Rating (0-5)', ratingController, isNumber: true),
                  SizedBox(height: 10.h),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const [
                      DropdownMenuItem(
                        value: 'captain',
                        child: Text('Captain'),
                      ),
                      DropdownMenuItem(
                        value: 'kitchen',
                        child: Text('Kitchen'),
                      ),
                      DropdownMenuItem(
                        value: 'cashier',
                        child: Text('Cashier'),
                      ),
                      DropdownMenuItem(
                        value: 'manager',
                        child: Text('Manager'),
                      ),
                      DropdownMenuItem(value: 'staff', child: Text('Staff')),
                    ],
                    onChanged: (value) => role = value ?? role,
                  ),
                  SizedBox(height: 10.h),
                  DropdownButtonFormField<String>(
                    value: payCycle,
                    decoration: const InputDecoration(labelText: 'Pay Cycle'),
                    items: const [
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(
                        value: 'monthly',
                        child: Text('Monthly'),
                      ),
                    ],
                    onChanged: (value) => payCycle = value ?? payCycle,
                  ),
                  SizedBox(height: 12.h),
                  if (staff == null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Create login credentials',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AdminTheme.primaryText,
                            ),
                          ),
                        ),
                        Switch(
                          value: createLogin,
                          onChanged: (value) =>
                              setDialogState(() => createLogin = value),
                        ),
                      ],
                    ),
                    if (createLogin) ...[
                      _textField('Login Email', emailController),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Ionicons.eye_outline
                                  : Ionicons.eye_off_outline,
                            ),
                            onPressed: () => setDialogState(
                              () => obscurePassword = !obscurePassword,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ] else if (staff.userId != null &&
                      staff.userId!.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Login linked to UID: ${staff.userId}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AdminTheme.secondaryText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final salary =
                    double.tryParse(salaryController.text.trim()) ?? 0;
                final rating =
                    double.tryParse(ratingController.text.trim()) ?? 0;
                final now = DateTime.now();
                final updated = StaffProfile(
                  id: staff?.id ?? '',
                  name: nameController.text.trim(),
                  contact: contactController.text.trim(),
                  role: role,
                  employeeId: employeeIdController.text.trim().isEmpty
                      ? DateFormat('yyyyMMddHHmm').format(now)
                      : employeeIdController.text.trim(),
                  shiftSchedule: shiftController.text.trim(),
                  baseSalary: salary,
                  payCycle: payCycle,
                  photoUrl: photoController.text.trim().isEmpty
                      ? null
                      : photoController.text.trim(),
                  userId: userIdController.text.trim().isEmpty
                      ? null
                      : userIdController.text.trim(),
                  email: emailController.text.trim().isEmpty
                      ? null
                      : emailController.text.trim(),
                  isActive: staff?.isActive ?? true,
                  rating: rating,
                  createdAt: staff?.createdAt ?? now,
                  updatedAt: now,
                );
                if (staff == null && createLogin) {
                  final email = emailController.text.trim();
                  final password = passwordController.text.trim();
                  if (email.isEmpty || password.length < 6) {
                    _showSnack(
                      context,
                      'Provide valid email and 6+ char password',
                      isError: true,
                    );
                    return;
                  }
                  await provider.addStaffWithLogin(
                    staff: updated,
                    email: email,
                    password: password,
                  );
                } else {
                  await provider.addOrUpdateStaff(updated);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPunchDialog(
    BuildContext context,
    StaffProvider provider,
  ) async {
    _selectedStaffId ??= provider.staff.isNotEmpty
        ? provider.staff.first.id
        : null;
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AdminTheme.cardBackground,
          title: const Text('Punch In/Out'),
          content: SizedBox(
            width: 360.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStaffPickerRow(
                  context,
                  provider,
                  selectedId: _selectedStaffId,
                  onSelected: (staff) =>
                      setDialogState(() => _selectedStaffId = staff?.id),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedStaffId == null
                            ? null
                            : () async {
                                try {
                                  await provider.clockIn(_selectedStaffId!);
                                  if (context.mounted) Navigator.pop(context);
                                } catch (e) {
                                  _showSnack(
                                    context,
                                    e.toString(),
                                    isError: true,
                                  );
                                }
                              },
                        child: const Text('Clock In'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedStaffId == null
                            ? null
                            : () async {
                                try {
                                  await provider.clockOut(_selectedStaffId!);
                                  if (context.mounted) Navigator.pop(context);
                                } catch (e) {
                                  _showSnack(
                                    context,
                                    e.toString(),
                                    isError: true,
                                  );
                                }
                              },
                        child: const Text('Clock Out'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openShiftDialog(
    BuildContext context,
    StaffProvider provider,
  ) async {
    String? staffId = provider.staff.isNotEmpty
        ? provider.staff.first.id
        : null;
    DateTime date = DateTime.now();
    TimeOfDay startTime = const TimeOfDay(hour: 10, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 0);
    final noteController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AdminTheme.cardBackground,
          title: const Text('Assign Shift'),
          content: SizedBox(
            width: 380.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStaffPickerRow(
                  context,
                  provider,
                  selectedId: staffId,
                  onSelected: (staff) =>
                      setDialogState(() => staffId = staff?.id),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 1),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 60),
                            ),
                          );
                          if (picked != null) {
                            setDialogState(() => date = picked);
                          }
                        },
                        child: Text(DateFormat('MMM dd').format(date)),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: startTime,
                          );
                          if (picked != null) {
                            setDialogState(() => startTime = picked);
                          }
                        },
                        child: Text('Start ${startTime.format(context)}'),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: endTime,
                          );
                          if (picked != null) {
                            setDialogState(() => endTime = picked);
                          }
                        },
                        child: Text('End ${endTime.format(context)}'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                _textField('Note (optional)', noteController),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: staffId == null
                  ? null
                  : () async {
                      final dateOnly = DateTime(
                        date.year,
                        date.month,
                        date.day,
                      );
                      final start = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        startTime.hour,
                        startTime.minute,
                      );
                      final end = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        endTime.hour,
                        endTime.minute,
                      );
                      final shift = StaffShift(
                        id: '',
                        staffId: staffId!,
                        date: dateOnly,
                        startTime: start,
                        endTime: end,
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                      );
                      await provider.addShift(shift);
                      await provider.addNotification(
                        StaffNotification(
                          id: '',
                          staffId: staffId,
                          title: 'Shift Assigned',
                          message:
                              'Shift on ${DateFormat('MMM dd').format(dateOnly)} • ${DateFormat('hh:mm a').format(start)} - ${DateFormat('hh:mm a').format(end)}',
                          type: 'shift',
                          createdAt: DateTime.now(),
                        ),
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTaskDialog(
    BuildContext context,
    StaffProvider provider,
  ) async {
    String? staffId = provider.staff.isNotEmpty
        ? provider.staff.first.id
        : null;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final orderIdController = TextEditingController();
    String priority = 'normal';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminTheme.cardBackground,
        title: const Text('New Task'),
        content: SizedBox(
          width: 380.w,
          child: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String?>(
                  value: staffId,
                  decoration: const InputDecoration(labelText: 'Assign To'),
                  items: provider.staff
                      .map(
                        (s) => DropdownMenuItem<String?>(
                          value: s.id,
                          child: Text(s.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => staffId = value,
                ),
                _textField('Task Title', titleController),
                _textField('Description', descController),
                _textField('Order ID (optional)', orderIdController),
                SizedBox(height: 10.h),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                  ],
                  onChanged: (value) => priority = value ?? priority,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: staffId == null
                ? null
                : () async {
                    final task = StaffTask(
                      id: '',
                      staffId: staffId!,
                      title: titleController.text.trim().isEmpty
                          ? 'Task'
                          : titleController.text.trim(),
                      description: descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim(),
                      orderId: orderIdController.text.trim().isEmpty
                          ? null
                          : orderIdController.text.trim(),
                      priority: priority,
                      createdAt: DateTime.now(),
                    );
                    await provider.addTask(task);
                    if (priority == 'urgent') {
                      await provider.addNotification(
                        StaffNotification(
                          id: '',
                          staffId: staffId,
                          title: 'Urgent Task Assigned',
                          message: task.title,
                          type: 'task',
                          createdAt: DateTime.now(),
                        ),
                      );
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPaymentDialog(
    BuildContext context,
    StaffProvider provider,
  ) async {
    String? staffId = provider.staff.isNotEmpty
        ? provider.staff.first.id
        : null;
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String type = 'advance';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminTheme.cardBackground,
        title: const Text('Record Payment'),
        content: SizedBox(
          width: 360.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                value: staffId,
                decoration: const InputDecoration(labelText: 'Staff'),
                items: provider.staff
                    .map(
                      (s) => DropdownMenuItem<String?>(
                        value: s.id,
                        child: Text(s.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => staffId = value,
              ),
              _textField('Amount', amountController, isNumber: true),
              _textField('Note (optional)', noteController),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'advance', child: Text('Advance')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                ],
                onChanged: (value) => type = value ?? type,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: staffId == null
                ? null
                : () async {
                    final amount =
                        double.tryParse(amountController.text.trim()) ?? 0;
                    final payment = StaffPayment(
                      id: '',
                      staffId: staffId!,
                      amount: amount,
                      type: type,
                      paidAt: DateTime.now(),
                      note: noteController.text.trim().isEmpty
                          ? null
                          : noteController.text.trim(),
                    );
                    await provider.addPayment(payment);
                    await provider.addNotification(
                      StaffNotification(
                        id: '',
                        staffId: staffId,
                        title: 'Payment Recorded',
                        message:
                            '₹${amount.toStringAsFixed(0)} ${type.toUpperCase()}',
                        type: 'payment',
                        createdAt: DateTime.now(),
                      ),
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _openNotificationDialog(
    BuildContext context,
    StaffProvider provider,
  ) async {
    String? staffId = provider.staff.isNotEmpty
        ? provider.staff.first.id
        : null;
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    String type = 'general';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminTheme.cardBackground,
        title: const Text('Send Notification'),
        content: SizedBox(
          width: 380.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                value: staffId,
                decoration: const InputDecoration(labelText: 'Send To'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Broadcast to all'),
                  ),
                  ...provider.staff.map(
                    (s) => DropdownMenuItem<String?>(
                      value: s.id,
                      child: Text(s.name),
                    ),
                  ),
                ],
                onChanged: (value) => staffId = value,
              ),
              _textField('Title', titleController),
              _textField('Message', messageController),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'general', child: Text('General')),
                  DropdownMenuItem(value: 'shift', child: Text('Shift')),
                  DropdownMenuItem(value: 'task', child: Text('Task')),
                  DropdownMenuItem(value: 'payment', child: Text('Payment')),
                ],
                onChanged: (value) => type = value ?? type,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final notification = StaffNotification(
                id: '',
                staffId: staffId,
                title: titleController.text.trim().isEmpty
                    ? 'Notification'
                    : titleController.text.trim(),
                message: messageController.text.trim(),
                type: type,
                createdAt: DateTime.now(),
              );
              await provider.addNotification(notification);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffPickerRow(
    BuildContext context,
    StaffProvider provider, {
    String? selectedId,
    required ValueChanged<StaffProfile?> onSelected,
  }) {
    final selected = provider.staff
        .where((s) => s.id == selectedId)
        .cast<StaffProfile?>()
        .firstWhere((s) => s != null, orElse: () => null);

    return InkWell(
      onTap: () async {
        final picked = await _pickStaffBottomSheet(
          context,
          provider.staff,
          selectedId: selectedId,
        );
        if (picked != null) onSelected(picked);
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AdminTheme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(Ionicons.person_outline, color: AdminTheme.secondaryText),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                selected?.name ?? 'Select Staff',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: selected == null
                      ? AdminTheme.secondaryText
                      : AdminTheme.primaryText,
                ),
              ),
            ),
            Text(
              'Change',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: AdminTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<StaffProfile?> _pickStaffBottomSheet(
    BuildContext context,
    List<StaffProfile> staff, {
    String? selectedId,
  }) async {
    final controller = TextEditingController();
    return showModalBottomSheet<StaffProfile?>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final query = controller.text.trim().toLowerCase();
            final filtered = staff.where((s) {
              if (query.isEmpty) return true;
              return s.name.toLowerCase().contains(query) ||
                  s.role.toLowerCase().contains(query) ||
                  s.employeeId.toLowerCase().contains(query);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 16.w,
                right: 16.w,
                top: 12.h,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: AdminTheme.dividerColor,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                  ),
                  Text(
                    'Select Staff',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Ionicons.search_outline),
                      labelText: 'Search by name or role',
                    ),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  SizedBox(height: 12.h),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: AdminTheme.dividerColor),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isSelected = item.id == selectedId;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AdminTheme.primaryColor
                                .withOpacity(0.12),
                            child: Icon(
                              Ionicons.person_outline,
                              color: AdminTheme.primaryColor,
                            ),
                          ),
                          title: Text(item.name),
                          subtitle: Text(
                            '${item.role.toUpperCase()} • ${item.employeeId}',
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Ionicons.checkmark_circle,
                                  color: AdminTheme.success,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  void _showSnack(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceAll('Exception: ', '')),
        backgroundColor: isError
            ? AdminTheme.critical
            : AdminTheme.primaryColor,
      ),
    );
  }
}
