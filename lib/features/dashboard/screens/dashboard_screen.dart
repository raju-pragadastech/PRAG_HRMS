import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/time_entry_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/attendance_data_manager.dart';
import '../../../core/models/employee.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isClockedIn = false;
  String _workLocation = '';
  DateTime? _clockInTime;
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;

  // Today's total hours (for display after clock-out)
  String _todayTotalHours = '0h 0m';

  // Employee data
  Employee? _employee;
  bool _isLoadingEmployee = true;
  String? _fallbackEmployeeId;

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
    _seedFromLocalCache();
    _loadEmployeeData();
    _checkClockInStatus();
    _loadTodayTotalHours();

    // Add observer to detect when app becomes active
    WidgetsBinding.instance.addObserver(this);

    // Ensure no lingering SnackBars show when entering dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  // Seed UI instantly from locally cached data to avoid initial delay after cold start
  Future<void> _seedFromLocalCache() async {
    try {
      // Prefer runtime cache warmed by splash; fallback to secure storage
      final cachedEmployee =
          AttendanceDataManager().cachedEmployeeData ??
          await StorageService.getEmployeeData();
      if (cachedEmployee != null && mounted) {
        setState(() {
          _employee = Employee.fromJson(cachedEmployee);
          _isLoadingEmployee = false;
        });
      }

      // Seed clock-in state from runtime cache; fallback to storage
      final cachedClockIn = AttendanceDataManager().cachedClockInData;
      final clockInData =
          cachedClockIn ?? await StorageService.getClockInData();
      final clockOutData = cachedClockIn == null
          ? await StorageService.getClockOutData()
          : null;
      if (clockInData != null && clockOutData == null) {
        final clockInIso = clockInData['clockInTime']?.toString();
        DateTime? clockIn;
        if (clockInIso != null && clockInIso.isNotEmpty) {
          try {
            clockIn = DateTime.parse(clockInIso);
          } catch (_) {
            clockIn = DateTime.now();
          }
        } else {
          clockIn = DateTime.now();
        }

        if (mounted) {
          setState(() {
            _isClockedIn = true;
            _workLocation =
                (clockInData['workLocation']?.toString().isNotEmpty ?? false)
                ? clockInData['workLocation'].toString()
                : 'Unknown';
            _clockInTime = clockIn;
            _elapsedTime = DateTime.now().difference(_clockInTime!);
          });
        }

        // Start/resume timer immediately
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted && _clockInTime != null) {
            setState(() {
              _elapsedTime = DateTime.now().difference(_clockInTime!);
            });
          }
        });
      }
    } catch (_) {
      // Ignore cache seed errors silently
    }
  }

  Future<void> _loadEmployeeData() async {
    try {
      print('📱 Loading employee data...');
      // Get employee data directly - AuthService handles employee ID internally
      final employee = await AuthService.getCurrentUserProfile();
      print('✅ Employee data loaded: ${employee?.firstName ?? 'Unknown'}');

      if (mounted) {
        setState(() {
          _employee = employee;
          _isLoadingEmployee = false;
        });
      }
    } catch (e) {
      print('❌ Error loading employee data: $e');
      if (mounted) {
        setState(() {
          _isLoadingEmployee = false;
        });
      }
    }
  }

  Future<void> _checkClockInStatus() async {
    try {
      // Use employee ID from loaded data or get it if not available
      final employeeId =
          _employee?.employeeId ?? await AuthService.getEmployeeId();
      if (employeeId == null) {
        return;
      }

      print('🕐 Checking clock-in status...');
      // Get current status from API
      final status = await TimeEntryService.getCurrentStatus(employeeId);
      print(
        '✅ Clock-in status: ${(status.isClockedIn ?? false) ? 'Clocked In' : 'Not Clocked In'}',
      );

      if (mounted) {
        setState(() {
          _isClockedIn = status.isClockedIn ?? false;

          if (status.isClockedIn ?? false) {
            _workLocation = status.workLocation ?? 'Unknown';

            if (status.clockInTime != null) {
              try {
                _clockInTime = DateTime.parse(status.clockInTime!);
                _elapsedTime = DateTime.now().difference(_clockInTime!);

                // Start timer if clocked in
                _timer?.cancel();
                _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                  if (mounted && _clockInTime != null) {
                    setState(() {
                      _elapsedTime = DateTime.now().difference(_clockInTime!);
                    });
                  }
                });
              } catch (e) {
                _clockInTime = DateTime.now();
                _elapsedTime = Duration.zero;
              }
            }
          } else {
            _workLocation = '';
            _clockInTime = null;
            _elapsedTime = Duration.zero;
            _timer?.cancel();
          }
        });
      }
    } catch (e) {
      // Silently handle the error - don't show error messages to user
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App became active, refresh clock-in status
      _checkClockInStatus();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _checkClockInStatus();
          await _loadEmployeeData();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Theme.of(context).scaffoldBackgroundColor,
              ],
            ),
          ),
          child: Column(
            children: [
              // Welcome Section (under unified header)
              _buildWelcomeSection(),
              // Clock Section
              _buildClockSection(),
              const SizedBox(height: 24),
              // Quick Actions Grid
              _buildQuickActionsGrid(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message - always aligned to left
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${_isLoadingEmployee ? 'Loading...' : (_employee?.firstName ?? 'Employee')} 👋',
                      style: TextStyle(
                        fontSize: 26, // Increased from 22 to 26
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Employee ID: ${_isLoadingEmployee ? 'Loading...' : (_employee?.employeeId ?? _fallbackEmployeeId ?? 'N/A')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Clock In/Out buttons below welcome message
          if (!_isClockedIn) ...[
            const SizedBox(height: 16),
            _buildLongClockInButton(),
            // Show today's total hours if available
            if (_todayTotalHours != '0h 0m') ...[
              const SizedBox(height: 12),
              _buildTodayHoursCard(),
            ],
          ] else ...[
            // Show clock-out button and timer when clocked in
            const SizedBox(height: 16),
            _buildClockOutButton(),
            const SizedBox(height: 12),
            _buildWorkingTimerCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildClockOutButton() {
    return GestureDetector(
      onTap: _showClockOutPopup,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.red, Colors.red.shade600],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Clock Out',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingTimerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(255, 255, 181, 69),
            const Color.fromARGB(255, 255, 176, 79),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 240, 177, 84).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Currently Working',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatDuration(_elapsedTime),
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_workLocation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Location: $_workLocation',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLongClockInButton() {
    return GestureDetector(
      onTap: _showClockInPopup,
      child: Container(
        width: double.infinity, // Long button
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ), // Increased size
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green, Colors.green.shade600],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            const Text(
              'Clock In',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayHoursCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            color: Colors.blue.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Total Hours',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _todayTotalHours,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: Colors.green.shade600,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildClockSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // This section is now empty as timer is shown in welcome section
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildQuickActionCard(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    color: Colors.blue,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.employeeProfile),
                  ),
                  _buildQuickActionCard(
                    icon: Icons.calendar_today_rounded,
                    label: 'Leave',
                    color: Colors.orange,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.leave),
                  ),
                  _buildQuickActionCard(
                    icon: Icons.access_time_rounded,
                    label: 'Attendance',
                    color: Colors.green,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.attendance),
                  ),
                  _buildQuickActionCard(
                    icon: Icons.campaign_rounded,
                    label: 'Announcements',
                    color: Colors.purple,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.announcements),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(0.1),
                          color.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showClockInPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color.fromARGB(
                    255,
                    30,
                    30,
                    30,
                  ) // Light black for dark theme
                : Colors.white, // White for light theme
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                spreadRadius: 1,
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Work Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildLocationOption(
                      icon: Icons.business_rounded,
                      label: 'Office 🏢',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        _clockIn('Office');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLocationOption(
                      icon: Icons.home_rounded,
                      label: 'Work From Home 🏠',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        _clockIn('Work From Home');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClockOutPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E1E) // Light black for dark theme
                : Colors.white, // White for light theme
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                spreadRadius: 1,
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Clock Out',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Are you sure you want to clock out?',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clockOut();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Clock Out'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clockIn(String location) async {
    if (_employee?.employeeId == null) {
      _showErrorSnackBar('Employee ID not found. Please login again.');
      return;
    }

    // Store original state for rollback if needed
    final originalIsClockedIn = _isClockedIn;
    final originalWorkLocation = _workLocation;
    final originalClockInTime = _clockInTime;
    final originalElapsedTime = _elapsedTime;

    // IMMEDIATE UI UPDATE - Update UI state first for instant feedback
    if (mounted) {
      setState(() {
        _isClockedIn = true;
        _workLocation = location;
        _clockInTime = DateTime.now();
        _elapsedTime = Duration.zero;
      });
    }

    // Start timer immediately
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_clockInTime!);
        });
      }
    });

    // Show immediate success message
    _showSuccessSnackBar('Clocking in at $location...');

    try {
      // Check if user is properly authenticated
      final isAuthenticated = await AuthService.isAuthenticated();
      if (!isAuthenticated) {
        // Rollback UI state
        if (mounted) {
          setState(() {
            _isClockedIn = originalIsClockedIn;
            _workLocation = originalWorkLocation;
            _clockInTime = originalClockInTime;
            _elapsedTime = originalElapsedTime;
          });
        }
        _timer?.cancel();

        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Authentication Required'),
              content: const Text('Please login again to continue.'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                  },
                  child: const Text('Login'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Clear any existing messages
      ScaffoldMessenger.of(context).clearSnackBars();

      // Determine if GPS is needed based on location
      bool needsGps = location.toLowerCase().contains('office');
      bool useGpsLocation = needsGps;

      print('🕐 Clocking in...');
      // Call API to store clock-in data with appropriate location handling
      final response = await TimeEntryService.clockIn(
        employeeId: _employee!.employeeId!,
        workLocation: location,
        useGpsLocation: useGpsLocation,
      );
      print(
        '✅ Clock-in response: ${response.isSuccessful ? 'Success' : 'Failed'}',
      );

      if (response.isSuccessful) {
        _showSuccessSnackBar('Successfully clocked in at $location');
        // Refresh attendance data after successful clock-in
        _refreshAttendanceData();
      } else {
        // Rollback UI state on API failure
        if (mounted) {
          setState(() {
            _isClockedIn = originalIsClockedIn;
            _workLocation = originalWorkLocation;
            _clockInTime = originalClockInTime;
            _elapsedTime = originalElapsedTime;
          });
        }
        _timer?.cancel();
        _showErrorSnackBar('Clock-in failed: ${response.message}');
      }
    } catch (e) {
      // Rollback UI state on any error
      if (mounted) {
        setState(() {
          _isClockedIn = originalIsClockedIn;
          _workLocation = originalWorkLocation;
          _clockInTime = originalClockInTime;
          _elapsedTime = originalElapsedTime;
        });
      }
      _timer?.cancel();

      // Handle specific errors
      if (e.toString().contains('already_completed') ||
          e.toString().contains('already completed your daily time entry') ||
          e.toString().contains(
            'only one clock-in and clock-out session is allowed',
          )) {
        _showSuccessSnackBar(
          'You have already completed your time entry for today',
        );
        return;
      } else if (e.toString().contains('credentials_invalid')) {
        // Show dialog to confirm logout and redirect to login
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Authentication Error'),
              content: const Text(
                'Your session has expired. Please login again to continue.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Clear storage and redirect to login
                    AuthService.logout();
                    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                  },
                  child: const Text('Login Again'),
                ),
              ],
            ),
          );
        }
        return; // Don't show snackbar if showing dialog
      } else if (e.toString().contains('TimeoutException') ||
          e.toString().contains('timeout')) {
        _showErrorSnackBar(
          'Request timeout. Please check your connection and try again.',
        );
      } else if (e.toString().contains('Network') ||
          e.toString().contains('SocketException')) {
        _showErrorSnackBar('Network error. Please check your connection');
      } else {
        _showErrorSnackBar('Clock-in failed: ${e.toString()}');
      }
    }
  }

  void _clockOut() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E) // Light black for dark theme
              : Colors.white, // White for light theme
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Clock Out',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          content: Text(
            'Are you sure you want to clock out?',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).textTheme.bodySmall?.color,
              ),
              child: const Text(
                'No',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _performClockOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Yes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performClockOut() async {
    if (_employee?.employeeId == null) {
      _showErrorSnackBar('Employee ID not found. Please login again.');
      return;
    }

    // Store work location before clearing UI state
    final currentWorkLocation = _workLocation;

    // Immediately update UI state to show clock-out action
    if (mounted) {
      setState(() {
        _isClockedIn = false;
        _workLocation = '';
        _clockInTime = null;
        _elapsedTime = Duration.zero;
      });
    }

    // Cancel timer immediately
    _timer?.cancel();

    // Show immediate success message
    _showSuccessSnackBar('Clocking out...');

    try {
      // Clear any existing messages
      ScaffoldMessenger.of(context).clearSnackBars();

      // Determine if GPS is needed based on work location
      bool needsGps = currentWorkLocation.toLowerCase().contains('office');
      bool useGpsLocation = needsGps;

      print('🕐 Clocking out...');
      // Call API to store clock-out data with appropriate location handling
      final response = await TimeEntryService.clockOut(
        employeeId: _employee!.employeeId!,
        workLocation: currentWorkLocation,
        useGpsLocation: useGpsLocation,
      );
      print(
        '✅ Clock-out response: ${response.isSuccessful ? 'Success' : 'Failed'}',
      );

      if (response.isSuccessful) {
        // Load today's total hours before updating UI
        await _loadTodayTotalHours();

        _showSuccessSnackBar(
          'Clocked out successfully. Total hours: ${response.totalHours ?? _todayTotalHours}',
        );

        // Refresh attendance data after successful clock-out
        _refreshAttendanceData();
      } else {
        // Restore UI state if clock-out failed
        if (mounted) {
          setState(() {
            _isClockedIn = true;
            _workLocation = currentWorkLocation;
            _clockInTime = DateTime.now().subtract(_elapsedTime);
          });
        }
        _showErrorSnackBar('Clock-out failed: ${response.message}');
      }
    } catch (e) {
      // Restore UI state if clock-out failed
      if (mounted) {
        setState(() {
          _isClockedIn = true;
          _workLocation = currentWorkLocation;
          _clockInTime = DateTime.now().subtract(_elapsedTime);
        });
      }

      // Handle specific errors
      if (e.toString().contains('not_clocked_in')) {
        _showErrorSnackBar('You are not currently clocked in');
      } else if (e.toString().contains('credentials_invalid')) {
        _showErrorSnackBar('Authentication error. Please login again');
      } else if (e.toString().contains('TimeoutException') ||
          e.toString().contains('timeout')) {
        _showErrorSnackBar(
          'Request timeout. Please check your connection and try again.',
        );
      } else if (e.toString().contains('Network') ||
          e.toString().contains('SocketException')) {
        _showErrorSnackBar('Network error. Please check your connection');
      } else {
        _showErrorSnackBar('Clock-out failed: ${e.toString()}');
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  // Load today's total hours from attendance data
  Future<void> _loadTodayTotalHours() async {
    try {
      if (_employee?.employeeId != null) {
        print('📊 Loading today total hours...');
        final timeEntries = await TimeEntryService.getWeeklyTimeEntries(
          _employee!.employeeId!,
        );
        print('✅ Today total hours loaded: ${_todayTotalHours}');
        final today = DateTime.now();
        final todayEntries = timeEntries.where((entry) {
          if (entry['clockInTime'] != null) {
            final clockInTime = DateTime.parse(entry['clockInTime'].toString());
            return clockInTime.year == today.year &&
                clockInTime.month == today.month &&
                clockInTime.day == today.day;
          }
          return false;
        }).toList();

        if (todayEntries.isNotEmpty) {
          final entry = todayEntries.first;
          final totalHours = entry['totalHours']?.toString() ?? '0h 0m';
          if (mounted) {
            setState(() {
              _todayTotalHours = totalHours;
            });
          }
        }
      }
    } catch (e) {}
  }

  // Refresh attendance data after clock-in/out
  void _refreshAttendanceData() {
    // This will trigger a refresh when user navigates to attendance screen
    // The attendance screen will fetch fresh data from API
  }

  // Show Success SnackBar
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Error UI disabled on dashboard per request to avoid overlay/overlap
  void _showErrorSnackBar(String message) {
    // Intentionally no UI shown. You can log if needed:
    // debugPrint('Dashboard error: ' + message);
  }
}
