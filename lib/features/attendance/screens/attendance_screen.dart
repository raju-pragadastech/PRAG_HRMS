import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/services/auth_service.dart';
import '../../../core/services/time_entry_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/attendance_data_manager.dart';
import '../../../core/models/employee.dart';
// Location service import removed - not needed in attendance screen
import '../../../core/constants/api_constants.dart';

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

  // Dynamic attendance data from API
  Map<String, Map<String, dynamic>> _weeklyAttendance = {};
  bool _isLoadingAttendance = true;
  String? _error;
  Employee? _employee;

  // Timer for real-time updates
  Timer? _timer;
  Duration _currentElapsedTime = Duration.zero;

  // Removed clock-in/clock-out state - not needed in attendance screen

  // HTTP client for direct API calls
  final http.Client httpClient = http.Client();

  // Stream subscription for data clearing events
  StreamSubscription<void>? _dataClearSubscription;

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

  // Clear attendance data to ensure fresh data for each user
  void _clearAttendanceData() {
    _weeklyAttendance.clear();
    _isLoadingAttendance = true;
    _error = null;
    _currentElapsedTime = Duration.zero;
    _timer?.cancel();
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

    // Clear any cached data to ensure fresh data for current user
    _clearAttendanceData();

    // Listen for data clearing events from logout
    _dataClearSubscription = AttendanceDataManager().clearDataStream.listen((
      _,
    ) {
      _clearAttendanceData();
    });

    _animationController.forward();
    _testHoursConversion(); // Test the conversion logic
    _loadAttendanceData();
    _startTimer();
    _testApiEndpoints();
  }

  Future<void> _loadAttendanceData() async {
    try {
      // Get employee data
      final employee = await AuthService.getCurrentUserProfile();

      // Check if employee has changed and clear data if needed
      if (_employee?.employeeId != employee?.employeeId) {
        _clearAttendanceData();
      }

      if (mounted) {
        setState(() {
          _employee = employee;
        });
      }

      if (employee?.employeeId != null) {
        print('📊 Loading weekly time entries...');
        // Load real attendance data from API
        final timeEntries = await TimeEntryService.getWeeklyTimeEntries(
          employee!.employeeId!,
        );
        print('✅ Weekly time entries loaded: ${timeEntries.length} entries');
        // Check if we got any data
        if (timeEntries.isEmpty) {
          // Try to get today's data specifically using daily endpoint
          final today = DateTime.now();
          final todayDate = today.toIso8601String().split('T')[0];

          try {
            // Try the daily endpoint
            final dailyData = await _getDailyTimeEntries(
              employee.employeeId!,
              todayDate,
            );

            if (dailyData.isNotEmpty) {
              // Convert daily data to the expected format
              final convertedEntries = _convertDailyDataToTimeEntries(
                dailyData,
              );
              timeEntries.addAll(convertedEntries);
            }
          } catch (e) {
            // Silently handle daily endpoint errors
          }

          // Also try the daily analytics endpoint for weekly summary
          try {
            final analyticsData = await _getDailyAnalytics(
              employee.employeeId!,
              todayDate,
            );

            if (analyticsData.isNotEmpty) {
              // Convert analytics data to time entries format
              final convertedAnalytics = _convertAnalyticsToTimeEntries(
                analyticsData,
              );
              timeEntries.addAll(convertedAnalytics);
            }
          } catch (e) {
            // Silently handle analytics endpoint errors
          }

          // If still no data, try getting data for the last 7 days
          if (timeEntries.isEmpty) {
            final lastWeek = today.subtract(const Duration(days: 7));
            print('📊 Loading last week time entries...');
            final lastWeekEntries = await TimeEntryService.getTimeEntries(
              employee.employeeId!,
              startDate: lastWeek.toIso8601String().split('T')[0],
              endDate: today.toIso8601String().split('T')[0],
            );
            print(
              '✅ Last week time entries loaded: ${lastWeekEntries.length} entries',
            );
            timeEntries.addAll(lastWeekEntries);
          }
        }

        print('🕐 Getting current clock-in status...');
        // Also get current status to show real-time clock-in info
        await TimeEntryService.getCurrentStatus(employee.employeeId!);
        print('✅ Current status retrieved');

        if (mounted) {
          setState(() {
            _isLoadingAttendance = false;
            _weeklyAttendance = _processTimeEntries(timeEntries);
            // Clock-in status logic removed - not needed in attendance screen

            // Data processed successfully
          });
        }
      } else {
        // No employee ID - show empty state
        if (mounted) {
          setState(() {
            _isLoadingAttendance = false;
            _weeklyAttendance = {}; // Empty map - no hardcoded data
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (e.toString().contains('SocketException') ||
              e.toString().contains('Failed host lookup') ||
              e.toString().contains('Network')) {
            _error = 'Network error. Please check your internet connection.';
          } else if (e.toString().contains('JSON') ||
              e.toString().contains('type \'String\' is not a subtype')) {
            _error = 'Data parsing error. Please try again.';
          } else if (e.toString().contains('HttpException')) {
            _error = 'Server error. Please try again later.';
          } else if (e.toString().contains('TimeoutException')) {
            _error = 'Request timeout. Please check your internet connection.';
          } else {
            _error = 'Failed to load attendance data: ${e.toString()}';
          }
          _isLoadingAttendance = false;
          _weeklyAttendance = {}; // Empty map - no hardcoded data
        });
      }
    }
  }

  // Removed _initializeEmptyAttendance() - no hardcoded data, only backend data

  Map<String, Map<String, dynamic>> _processTimeEntries(
    List<Map<String, dynamic>> timeEntries,
  ) {
    // Process only actual data from backend - no hardcoded empty data
    final Map<String, Map<String, dynamic>> attendance = {};

    // Process time entries from API - filter by current employee ID
    final currentEmployeeId = _employee?.employeeId;
    if (currentEmployeeId == null) {
      return attendance;
    }

    for (var entry in timeEntries) {
      try {
        // Filter by employee ID to ensure data isolation
        final entryEmployeeId =
            entry['employeeId'] ??
            entry['employee_id'] ??
            entry['employee'] ??
            entry['empId'];

        if (entryEmployeeId != null &&
            entryEmployeeId.toString() != currentEmployeeId) {
          print(
            '📊 Skipping entry for different employee: $entryEmployeeId (current: $currentEmployeeId)',
          );
          continue;
        }

        // Safely parse DateTime values with better null handling
        // Try multiple possible field names for clock in/out times
        DateTime? clockInTime;
        DateTime? clockOutTime;

        // Try different possible field names for clock in time
        final clockInFields = [
          'clockInTime',
          'clock_in_time',
          'clockIn',
          'startTime',
          'checkInTime',
          'inTime',
        ];
        for (String field in clockInFields) {
          if (entry[field] != null && entry[field].toString().isNotEmpty) {
            try {
              clockInTime = DateTime.parse(entry[field].toString());
              break;
            } catch (e) {
              print('❌ Error parsing $field: ${entry[field]} - $e');
            }
          }
        }

        // Try different possible field names for clock out time
        final clockOutFields = [
          'clockOutTime',
          'clock_out_time',
          'clockOut',
          'endTime',
          'checkOutTime',
          'outTime',
        ];
        for (String field in clockOutFields) {
          if (entry[field] != null && entry[field].toString().isNotEmpty) {
            try {
              clockOutTime = DateTime.parse(entry[field].toString());
              print('📊 Found clock out time in field "$field": $clockOutTime');
              break;
            } catch (e) {
              print('❌ Error parsing $field: ${entry[field]} - $e');
            }
          }
        }

        // Try different possible field names for work location
        final workLocationFields = [
          'workLocation',
          'work_location',
          'location',
          'workPlace',
          'officeLocation',
        ];
        String workLocation = 'N/A';
        for (String field in workLocationFields) {
          if (entry[field] != null && entry[field].toString().isEmpty) {
            workLocation = entry[field].toString();
            print('📊 Found work location in field "$field": $workLocation');
            break;
          }
        }

        // Try different possible field names for total hours
        final totalHoursFields = [
          'totalHours',
          'total_hours',
          'duration',
          'workHours',
          'hoursWorked',
          'timeWorked',
        ];
        String totalHours = '0h 0m';
        for (String field in totalHoursFields) {
          if (entry[field] != null && entry[field].toString().isNotEmpty) {
            totalHours = entry[field].toString();
            print('📊 Found total hours in field "$field": $totalHours');
            break;
          }
        }

        if (clockInTime != null) {
          final dayName = _getDayName(clockInTime.weekday);
          final isCompleted = clockOutTime != null;

          attendance[dayName] = {
            'clockIn': clockInTime,
            'clockOut': clockOutTime,
            'hours': totalHours,
            'completed': isCompleted,
            'status': isCompleted ? 'Completed' : 'Currently Working',
            'location': workLocation,
            'employeeId': _employee?.employeeId ?? 'N/A',
          };

          print(
            '✅ Processed entry for $dayName: Clock-in: $clockInTime, Clock-out: $clockOutTime',
          );
        } else {
          print('⚠️ Skipping entry with null clockInTime: $entry');
        }
      } catch (e) {
        print('❌ Error processing time entry: $e');
        print('❌ Entry data: $entry');
      }
    }

    print('📊 ========== PROCESSED ATTENDANCE DATA ==========');
    print('📊 Final attendance data: $attendance');
    print('📊 Attendance entries count: ${attendance.length}');
    for (var entry in attendance.entries) {
      print('📊 ${entry.key}: ${entry.value}');
    }
    print('📊 ========== PROCESSED ATTENDANCE DATA END ==========');

    return attendance;
  }

  String _getDayName(int weekday) {
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

  // Start timer for real-time updates
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateCurrentElapsedTime();
        setState(() {});
      }
    });
  }

  // Update current elapsed time for today's clock-in
  void _updateCurrentElapsedTime() {
    final todayData = _weeklyAttendance[_currentDay];

    if (todayData != null &&
        todayData['clockIn'] != null &&
        todayData['clockOut'] == null) {
      final clockInTime = todayData['clockIn'] as DateTime?;
      if (clockInTime != null) {
        _currentElapsedTime = DateTime.now().difference(clockInTime);
      } else {
        _currentElapsedTime = Duration.zero;
      }
    } else {
      _currentElapsedTime = Duration.zero;
    }
  }

  // Get current hours display (either from API or real-time calculation)
  String _getCurrentHours() {
    final todayData = _weeklyAttendance[_currentDay];
    if (todayData != null &&
        todayData['clockIn'] != null &&
        todayData['clockOut'] == null) {
      // Currently clocked in - show real-time hours
      return _formatDuration(_currentElapsedTime);
    } else if (todayData != null && todayData['hours'] != null) {
      // Clocked out - show stored hours from backend
      final hoursData = todayData['hours'];
      if (hoursData is num) {
        // Convert decimal hours to formatted string
        final hours = hoursData.toDouble();
        final h = hours.floor();
        final m = ((hours - h) * 60).round();
        return '${h}h ${m}m';
      } else if (hoursData is String) {
        return hoursData;
      }
    }
    return '0h 0m';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dataClearSubscription?.cancel();
    _animationController.dispose();
    httpClient.close();
    super.dispose();
  }

  // Called when the screen becomes visible (e.g., when user switches back to this tab)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh if we don't have data yet to avoid unnecessary API calls
    if (_weeklyAttendance.isEmpty) {
      _refreshAttendanceData();
    }
  }

  // Refresh attendance data for current user
  Future<void> _refreshAttendanceData() async {
    print('🔄 Refreshing attendance data for current user...');
    _clearAttendanceData();
    await _loadAttendanceData();
  }

  // Attendance data clearing is handled automatically on user change and screen refresh

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
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _loadAttendanceData();
              _startTimer();
            },
            tooltip: 'Refresh Data',
          ),
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
        child: _isLoadingAttendance
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading attendance data',
                      style: TextStyle(color: Colors.red[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAttendanceData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
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
        todayData['clockIn'] != null &&
        todayData['clockOut'] == null;
    final isCompleted = todayData != null && todayData['completed'];

    print('🔍 Today status card debug:');
    print('  - todayData: $todayData');
    print('  - isWorking: $isWorking');
    print('  - isCompleted: $isCompleted');
    print('  - clockIn: ${todayData?['clockIn']}');
    print('  - clockOut: ${todayData?['clockOut']}');
    print('  - completed: ${todayData?['completed']}');

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
                        : const Color.fromARGB(255, 197, 142, 142))
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
                        color: const Color.fromARGB(
                          255,
                          27,
                          122,
                          41,
                        ).withOpacity(0.9),
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
                _buildStatusInfo(
                  'Clock In',
                  _formatTime(todayData['clockIn'] as DateTime?),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildStatusInfo('Hours', _getCurrentHours()),
                if (todayData['clockOut'] != null) ...[
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  _buildStatusInfo(
                    'Clock Out',
                    _formatTime(todayData['clockOut'] as DateTime?),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            // Clock-in/clock-out buttons removed - not needed in attendance screen
          ],
        ],
      ),
    );
  }

  Widget _buildStatusInfo(String label, String value) {
    final todayData = _weeklyAttendance[_currentDay];
    final isCurrentlyWorking =
        todayData != null &&
        todayData['clockIn'] != null &&
        todayData['clockOut'] == null;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            if (label == 'Hours' && isCurrentlyWorking) ...[
              const SizedBox(width: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 1000),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isCurrentlyWorking && label == 'Hours'
                ? Colors.green
                : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDailySummaryCard() {
    final todayData = _weeklyAttendance[_currentDay];
    final todayHours = _getCurrentHours();

    // Calculate expected hours (8 hours for weekdays, 0 for weekends)
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
          _buildSummaryRow(
            'Expected Hours',
            expectedHours,
            const Color.fromARGB(255, 230, 177, 177),
          ),
          _buildSummaryRow('Overtime', overtime, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildWeeklySummaryCard() {
    print('📊 Building weekly summary card...');
    print('📊 Weekly attendance data: $_weeklyAttendance');
    print('📊 Weekly attendance entries count: ${_weeklyAttendance.length}');
    print('📊 Available days: ${_weeklyAttendance.keys.toList()}');

    // Calculate weekly totals for weekdays only (Monday-Friday)
    int totalWorkDays = 0;
    int completedDays = 0;
    Duration totalHours = Duration.zero;

    // Only process weekdays
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

    for (String day in weekdays) {
      final data = _weeklyAttendance[day];
      print('📊 Processing $day: data=$data');
      if (data != null && data['clockIn'] != null) {
        totalWorkDays++;
        if (data['completed'] == true) {
          completedDays++;
        }

        // Calculate hours for this day - use backend hours data if available
        final hoursData = data['hours'];
        print(
          '📊 $day hours data: $hoursData (type: ${hoursData.runtimeType})',
        );
        if (hoursData != null) {
          if (hoursData is num) {
            // Convert decimal hours to Duration
            final hours = hoursData.toDouble();
            final h = hours.floor();
            final m = ((hours - h) * 60).round();
            print('📊 Converting $hours hours to ${h}h ${m}m');
            totalHours += Duration(hours: h, minutes: m);
            print(
              '📊 $day: Added ${h}h ${m}m, Total so far: ${totalHours.inHours}h ${totalHours.inMinutes.remainder(60)}m',
            );
          } else if (hoursData is String) {
            // Parse string format like "0h 44m" or "2h 30m" or decimal hours
            final hoursStr = hoursData.toString();
            final hoursMatch = RegExp(r'(\d+)h\s*(\d+)m').firstMatch(hoursStr);
            if (hoursMatch != null) {
              // Already in "Xh Ym" format
              final h = int.parse(hoursMatch.group(1)!);
              final m = int.parse(hoursMatch.group(2)!);
              totalHours += Duration(hours: h, minutes: m);
              print('📊 $day: Added ${h}h ${m}m from string format');
            } else {
              // Try to parse as decimal hours string
              try {
                final hours = double.parse(hoursStr);
                final h = hours.floor();
                final m = ((hours - h) * 60).round();
                print('📊 Converting string "$hoursStr" to ${h}h ${m}m');
                totalHours += Duration(hours: h, minutes: m);
                print(
                  '📊 $day: Added ${h}h ${m}m, Total so far: ${totalHours.inHours}h ${totalHours.inMinutes.remainder(60)}m',
                );
              } catch (e) {
                print('📊 Error parsing hours string "$hoursStr": $e');
              }
            }
          }
        } else {
          // Fallback to calculating from clock in/out times
          final clockIn = data['clockIn'] as DateTime?;
          final clockOut = data['clockOut'] as DateTime?;
          if (clockIn != null) {
            if (clockOut != null) {
              totalHours += clockOut.difference(clockIn);
            } else if (day == _currentDay) {
              // Currently working - add current elapsed time
              totalHours += _currentElapsedTime;
            }
          }
        }
      }
    }

    final totalHoursString = _formatDuration(totalHours);
    print(
      '📊 Weekly total hours: $totalHoursString (${totalHours.inHours}h ${totalHours.inMinutes.remainder(60)}m)',
    );

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

          // Weekly Statistics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeeklyStat('Work Days', '$totalWorkDays/5', Colors.blue),
                _buildWeeklyStat('Completed', '$completedDays/5', Colors.green),
                _buildWeeklyStat(
                  'Total Hours',
                  totalHoursString,
                  Colors.orange,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Daily Breakdown
          if (_weeklyAttendance.isNotEmpty) ...[
            const Text(
              'Daily Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            // Show weekdays in order (Monday to Friday)
            ...['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'].map((
              day,
            ) {
              final data = _weeklyAttendance[day];
              final isToday = day == _currentDay;

              // Format hours data properly
              String hoursDisplay = '0h 0m';
              if (isToday && data != null) {
                hoursDisplay = _getCurrentHours();
              } else if (data != null && data['hours'] != null) {
                final hoursData = data['hours'];
                if (hoursData is num) {
                  // Convert decimal hours to formatted string
                  final hours = hoursData.toDouble();
                  final h = hours.floor();
                  final m = ((hours - h) * 60).round();
                  hoursDisplay = '${h}h ${m}m';
                } else if (hoursData is String) {
                  hoursDisplay = hoursData;
                }
              }

              return _buildWeeklyRow(
                day,
                hoursDisplay,
                data?['completed'] as bool? ?? false,
                data?['status'] as String? ?? 'No Entry',
                isToday: isToday,
                clockIn: data?['clockIn'] as DateTime?,
                clockOut: data?['clockOut'] as DateTime?,
                location: data?['location'] as String?,
              );
            }),
          ] else ...[
            // Show empty state
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No attendance data available',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Data will appear here once you clock in',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeeklyStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
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
                if (location != null && location != 'N/A') ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: location.toLowerCase().contains('office')
                          ? Colors.blue.shade100
                          : location.toLowerCase().contains('home')
                          ? Colors.green.shade100
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: location.toLowerCase().contains('office')
                            ? Colors.blue.shade300
                            : location.toLowerCase().contains('home')
                            ? Colors.green.shade300
                            : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          location.toLowerCase().contains('office')
                              ? Icons.business_rounded
                              : location.toLowerCase().contains('home')
                              ? Icons.home_rounded
                              : Icons.location_on_rounded,
                          size: 12,
                          color: location.toLowerCase().contains('office')
                              ? Colors.blue.shade700
                              : location.toLowerCase().contains('home')
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location.toLowerCase().contains('office')
                              ? 'Office'
                              : location.toLowerCase().contains('home')
                              ? 'WFH'
                              : location,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: location.toLowerCase().contains('office')
                                ? Colors.blue.shade700
                                : location.toLowerCase().contains('home')
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
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
              if (location != null && location != 'N/A') ...[
                _buildDetailRow(
                  'Location',
                  location.toLowerCase().contains('office')
                      ? 'Office 🏢'
                      : location.toLowerCase().contains('home')
                      ? 'Home 🏠'
                      : location,
                  location.toLowerCase().contains('office')
                      ? Icons.business_rounded
                      : location.toLowerCase().contains('home')
                      ? Icons.home_rounded
                      : Icons.location_on,
                  location.toLowerCase().contains('office')
                      ? Colors.blue
                      : location.toLowerCase().contains('home')
                      ? Colors.green
                      : Colors.grey,
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

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  // Test function to verify decimal hours conversion
  void _testHoursConversion() {
    print('🧪 Testing hours conversion:');
    final testHours = [
      7.266666666666667,
      15.95,
      6.733333333333333,
      7.783333333333333,
    ];
    for (double hours in testHours) {
      final h = hours.floor();
      final m = ((hours - h) * 60).round();
      print('  $hours hours = ${h}h ${m}m');
    }

    // Test the expected conversions
    print('🧪 Expected conversions:');
    print('  7.266666666666667 → 7h 16m');
    print('  15.95 → 15h 57m');
    print('  6.733333333333333 → 6h 44m');
    print('  7.783333333333333 → 7h 47m');
  }

  // Get daily time entries using the daily endpoint
  Future<List<Map<String, dynamic>>> _getDailyTimeEntries(
    String employeeId,
    String date,
  ) async {
    try {
      print('📱 Getting daily time entries for date: $date');
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.dailyTimeEntriesEndpoint}?date=$date';
      final headers = await _getHeaders(includeAuth: true);

      print('📱 Daily URL: $url');
      print('📱 Daily Headers: $headers');

      final response = await httpClient
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));

      print('📱 Daily Response Status: ${response.statusCode}');
      print('📱 Daily Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = _handleResponse(response);
        print('📱 Daily Response Data: $responseData');

        if (responseData is List) {
          return responseData.cast<Map<String, dynamic>>();
        } else if (responseData is Map<String, dynamic>) {
          return [responseData];
        }
      }

      return [];
    } catch (e) {
      print('📱 Daily endpoint error: $e');
      return [];
    }
  }

  // Get daily analytics using the analytics endpoint
  Future<List<Map<String, dynamic>>> _getDailyAnalytics(
    String employeeId,
    String date,
  ) async {
    try {
      print('📱 Getting daily analytics for date: $date');
      final url =
          '${ApiConstants.baseUrl}${ApiConstants.dailyAnalyticsEndpoint}?date=$date';
      final headers = await _getHeaders(includeAuth: true);

      print('📱 Analytics URL: $url');
      print('📱 Analytics Headers: $headers');

      final response = await httpClient
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));

      print('📱 Analytics Response Status: ${response.statusCode}');
      print('📱 Analytics Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = _handleResponse(response);
        print('📱 Analytics Response Data: $responseData');

        if (responseData is List) {
          return responseData.cast<Map<String, dynamic>>();
        } else if (responseData is Map<String, dynamic>) {
          return [responseData];
        }
      }

      return [];
    } catch (e) {
      print('📱 Analytics endpoint error: $e');
      return [];
    }
  }

  // Convert daily data to time entries format
  List<Map<String, dynamic>> _convertDailyDataToTimeEntries(
    List<Map<String, dynamic>> dailyData,
  ) {
    final List<Map<String, dynamic>> convertedEntries = [];

    for (var entry in dailyData) {
      print('📱 Converting daily entry: $entry');

      // Map different possible field names to standard format
      final convertedEntry = {
        'clockInTime':
            entry['clockInTime'] ??
            entry['clock_in_time'] ??
            entry['clockIn'] ??
            entry['startTime'],
        'clockOutTime':
            entry['clockOutTime'] ??
            entry['clock_out_time'] ??
            entry['clockOut'] ??
            entry['endTime'],
        'workLocation':
            entry['workLocation'] ??
            entry['work_location'] ??
            entry['location'] ??
            'Unknown',
        'totalHours':
            entry['totalHours'] ??
            entry['total_hours'] ??
            entry['duration'] ??
            '0h 0m',
        'employeeId':
            entry['employeeId'] ?? entry['employee_id'] ?? entry['employee'],
        'date': entry['date'] ?? entry['workDate'] ?? entry['work_date'],
        'status': entry['status'] ?? entry['workStatus'] ?? 'Completed',
      };

      print('📱 Converted entry: $convertedEntry');
      convertedEntries.add(convertedEntry);
    }

    return convertedEntries;
  }

  // Convert analytics data to time entries format
  List<Map<String, dynamic>> _convertAnalyticsToTimeEntries(
    List<Map<String, dynamic>> analyticsData,
  ) {
    final List<Map<String, dynamic>> convertedEntries = [];

    for (var entry in analyticsData) {
      print('📱 Converting analytics entry: $entry');

      // Map different possible field names to standard format
      final convertedEntry = {
        'clockInTime':
            entry['clockInTime'] ??
            entry['clock_in_time'] ??
            entry['clockIn'] ??
            entry['startTime'],
        'clockOutTime':
            entry['clockOutTime'] ??
            entry['clock_out_time'] ??
            entry['clockOut'] ??
            entry['endTime'],
        'workLocation':
            entry['workLocation'] ??
            entry['work_location'] ??
            entry['location'] ??
            'Unknown',
        'totalHours':
            entry['totalHours'] ??
            entry['total_hours'] ??
            entry['duration'] ??
            '0h 0m',
        'employeeId':
            entry['employeeId'] ?? entry['employee_id'] ?? entry['employee'],
        'date': entry['date'] ?? entry['workDate'] ?? entry['work_date'],
        'status': entry['status'] ?? entry['workStatus'] ?? 'Completed',
      };

      print('📱 Converted analytics entry: $convertedEntry');
      convertedEntries.add(convertedEntry);
    }

    return convertedEntries;
  }

  // Get headers for API calls
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (includeAuth) {
      final token = await StorageService.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Handle API response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return json.decode(response.body);
      } catch (e) {
        print('❌ JSON decode error: $e');
        return response.body;
      }
    } else {
      throw Exception(
        'API call failed with status ${response.statusCode}: ${response.body}',
      );
    }
  }

  // Test API endpoints to debug data fetching issues
  Future<void> _testApiEndpoints() async {
    try {
      print('🧪 ========== TESTING API ENDPOINTS ==========');

      if (_employee?.employeeId != null) {
        final employeeId = _employee!.employeeId!;

        // Test time entry status endpoint
        print('🧪 Testing time entry status endpoint...');
        try {
          final status = await TimeEntryService.getCurrentStatus(employeeId);
          print('🧪 Status endpoint result: ${status.toJson()}');
        } catch (e) {
          print('🧪 Status endpoint error: $e');
        }

        // Test time entries endpoint with different date ranges
        print('🧪 Testing time entries endpoint...');
        try {
          final now = DateTime.now();
          final today = now.toIso8601String().split('T')[0];
          final yesterday = now
              .subtract(const Duration(days: 1))
              .toIso8601String()
              .split('T')[0];

          print('🧪 Testing with today\'s date: $today');
          final todayEntries = await TimeEntryService.getTimeEntries(
            employeeId,
            startDate: today,
            endDate: today,
          );
          print('🧪 Today entries result: ${todayEntries.length} entries');

          print('🧪 Testing with yesterday\'s date: $yesterday');
          final yesterdayEntries = await TimeEntryService.getTimeEntries(
            employeeId,
            startDate: yesterday,
            endDate: yesterday,
          );
          print(
            '🧪 Yesterday entries result: ${yesterdayEntries.length} entries',
          );
        } catch (e) {
          print('🧪 Time entries endpoint error: $e');
        }
      }

      print('🧪 ========== API ENDPOINTS TEST COMPLETE ==========');
    } catch (e) {
      print('🧪 API endpoints test error: $e');
    }
  }

  // Clock-in/clock-out methods removed - not needed in attendance screen

  // SnackBar methods removed - not needed in attendance screen
}
