import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Sample attendance data that would come from API (simulating real-time data)
  Map<String, Map<String, dynamic>> _weeklyAttendance = {
    'Monday': {
      'clockIn': DateTime(2024, 2, 12, 9, 0),
      'clockOut': DateTime(2024, 2, 12, 17, 30),
      'hours': '8h 30m',
      'completed': true,
      'status': 'Completed',
      'location': 'Office',
      'employeeId': 'EMP001',
    },
    'Tuesday': {
      'clockIn': DateTime(2024, 2, 13, 8, 45),
      'clockOut': DateTime(2024, 2, 13, 17, 15),
      'hours': '8h 30m',
      'completed': true,
      'status': 'Completed',
      'location': 'Office',
      'employeeId': 'EMP001',
    },
    'Wednesday': {
      'clockIn': DateTime(2024, 2, 14, 9, 15),
      'clockOut': DateTime(2024, 2, 14, 18, 0),
      'hours': '8h 45m',
      'completed': true,
      'status': 'Completed',
      'location': 'Work From Home',
      'employeeId': 'EMP001',
    },
    'Thursday': {
      'clockIn': DateTime(2024, 2, 15, 8, 30),
      'clockOut': DateTime(2024, 2, 15, 17, 45),
      'hours': '9h 15m',
      'completed': true,
      'status': 'Completed',
      'location': 'Office',
      'employeeId': 'EMP001',
    },
    'Friday': {
      'clockIn': DateTime.now().subtract(
        const Duration(hours: 2),
      ), // Simulate current day
      'clockOut': null, // Currently working
      'hours': '2h 0m', // Current elapsed time
      'completed': false,
      'status': 'Currently Working',
      'location': 'Office',
      'employeeId': 'EMP001',
    },
  };

  // Get current day name
  String get _currentDay {
    final now = DateTime.now();
    final weekday = now.weekday;
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();

    // Simulate fetching attendance data from API
    _fetchAttendanceData();
  }

  // Simulate API call to fetch attendance data
  Future<void> _fetchAttendanceData() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // In real app, this would be an API call:
    // final response = await AttendanceService.getWeeklyAttendance('EMP001');
    // setState(() {
    //   _weeklyAttendance = response;
    // });

    print('Fetched attendance data from API');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Attendance',
            onPressed: _exportAttendanceData,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Today's Status Card
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildTodayStatusCard(),
                ),
              ),

              const SizedBox(height: 20),

              // Daily Summary Card
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildDailySummaryCard(),
                ),
              ),

              const SizedBox(height: 20),

              // Weekly Summary Card
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildWeeklySummaryCard(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayStatusCard() {
    final todayData = _weeklyAttendance[_currentDay];
    final isWorking =
        todayData != null &&
        !todayData['completed'] &&
        todayData['clockIn'] != null;
    final isCompleted = todayData != null && todayData['completed'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isWorking
              ? [Colors.orange.shade400, Colors.orange.shade600]
              : isCompleted
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.grey.shade400, Colors.grey.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                (isWorking
                        ? Colors.orange
                        : isCompleted
                        ? Colors.green
                        : Colors.grey)
                    .withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isWorking
                      ? Icons.access_time_rounded
                      : isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.schedule_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentDay,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isWorking
                          ? 'Currently Working'
                          : isCompleted
                          ? 'Work Completed'
                          : 'Not Started',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (todayData != null) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusInfo('Clock In', _formatTime(todayData['clockIn'])),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatusInfo('Hours', todayData['hours']),
                if (todayData['clockOut'] != null) ...[
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildStatusInfo(
                    'Clock Out',
                    _formatTime(todayData['clockOut']),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDailySummaryCard() {
    final todayData = _weeklyAttendance[_currentDay];
    final todayHours = todayData != null
        ? todayData['hours'] as String
        : '0h 0m';

    // Calculate expected hours (8 hours for weekdays)
    final isWeekday = _currentDay != 'Saturday' && _currentDay != 'Sunday';
    final expectedHours = isWeekday ? '8h 0m' : '0h 0m';

    // Calculate overtime
    String overtime = '0h 0m';
    if (todayData != null && todayData['completed'] as bool) {
      final clockIn = todayData['clockIn'] as DateTime?;
      final clockOut = todayData['clockOut'] as DateTime?;

      if (clockIn != null && clockOut != null) {
        final duration = clockOut.difference(clockIn);
        final totalMinutes = duration.inMinutes;
        final expectedMinutes = 8 * 60;

        if (totalMinutes > expectedMinutes) {
          final overtimeMinutes = totalMinutes - expectedMinutes;
          final overtimeHours = overtimeMinutes ~/ 60;
          final overtimeRemainingMinutes = overtimeMinutes % 60;
          overtime = '${overtimeHours}h ${overtimeRemainingMinutes}m';
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.today_rounded, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Daily Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSummaryRow('Total Hours', todayHours, Colors.blue),
          _buildSummaryRow('Expected Hours', expectedHours, Colors.grey),
          _buildSummaryRow('Overtime', overtime, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildWeeklySummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_view_week_rounded,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Weekly Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._weeklyAttendance.entries.map((entry) {
            final day = entry.key;
            final data = entry.value;
            final isToday = day == _currentDay;

            return _buildWeeklyRow(
              day,
              data['hours'] as String,
              data['completed'] as bool,
              data['status'] as String,
              isToday: isToday,
              clockIn: data['clockIn'] as DateTime?,
              clockOut: data['clockOut'] as DateTime?,
              location: data['location'] as String?,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyRow(
    String day,
    String hours,
    bool completed,
    String status, {
    bool isToday = false,
    DateTime? clockIn,
    DateTime? clockOut,
    String? location,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday ? Colors.blue.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: isToday ? Border.all(color: Colors.blue.shade200) : null,
      ),
      child: InkWell(
        onTap: () => _showDayDetailsDialog(day, clockIn, clockOut, location),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isToday ? Colors.blue : Colors.black87,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ],
                if (location != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: location == 'Office'
                          ? Colors.green.shade100
                          : Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      location == 'Office' ? '🏢' : '🏠',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
            Row(
              children: [
                Text(
                  hours,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: completed ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  completed ? Icons.check_circle : Icons.schedule,
                  color: completed ? Colors.green : Colors.orange,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDayDetailsDialog(
    String day,
    DateTime? clockIn,
    DateTime? clockOut,
    String? location,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.blue),
              const SizedBox(width: 8),
              Text('$day Details'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (location != null) ...[
                _buildDetailRow(
                  'Location',
                  location,
                  Icons.location_on,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
              ],
              if (clockIn != null) ...[
                _buildDetailRow(
                  'Clock In',
                  _formatTime(clockIn),
                  Icons.login,
                  Colors.green,
                ),
                const SizedBox(height: 12),
              ],
              if (clockOut != null) ...[
                _buildDetailRow(
                  'Clock Out',
                  _formatTime(clockOut),
                  Icons.logout,
                  Colors.red,
                ),
                const SizedBox(height: 12),
              ],
              if (clockIn != null && clockOut != null) ...[
                _buildDetailRow(
                  'Total Hours',
                  _formatDuration(clockOut.difference(clockIn)),
                  Icons.access_time,
                  Colors.orange,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
      ],
    );
  }

  void _exportAttendanceData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attendance data exported successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}
