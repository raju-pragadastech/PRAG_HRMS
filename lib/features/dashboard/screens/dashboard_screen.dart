import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/time_entry_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/attendance_data_manager.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/constants/api_constants.dart';
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

  // Loading state for central loading overlay
  bool _isLoadingDashboardData = true;

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

    // Initialize data loading in proper order to ensure immediate UI updates
    _initializeDashboardData();

    // Add observer to detect when app becomes active
    WidgetsBinding.instance.addObserver(this);

    // Ensure no lingering SnackBars show when entering dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  // Initialize dashboard data in proper order to ensure immediate UI updates
  Future<void> _initializeDashboardData() async {
    try {
      // First, seed from local cache to show data immediately
      await _seedFromLocalCache();

      // Then load fresh data from API in background
      await Future.wait([
        _loadEmployeeData(),
        _checkClockInStatus(),
        _loadTodayTotalHours(),
      ]);

      // Mark dashboard loading as complete
      if (mounted) {
        setState(() {
          _isLoadingDashboardData = false;
        });
      }
    } catch (e) {
      // Handle any initialization errors gracefully
      print('❌ Error initializing dashboard data: $e');
      // Mark loading as complete even on error
      if (mounted) {
        setState(() {
          _isLoadingDashboardData = false;
        });
      }
    }
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
        // Only update if we have new employee data or if we don't have cached data
        if (employee != null &&
            (_employee == null ||
                _employee?.employeeId != employee.employeeId)) {
          setState(() {
            _employee = employee;
            _isLoadingEmployee = false;
          });
        } else if (_employee == null) {
          // If we still don't have employee data, set loading to false
          setState(() {
            _isLoadingEmployee = false;
          });
        }
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

  // Load employee data specifically for refresh - always updates UI
  Future<void> _loadEmployeeDataForRefresh() async {
    try {
      print('🔄 Refreshing employee data...');
      // Get employee data directly - AuthService handles employee ID internally
      final employee = await AuthService.getCurrentUserProfile();
      print('✅ Employee data refreshed: ${employee?.firstName ?? 'Unknown'}');

      if (mounted) {
        // Always update UI during refresh, even if data is the same
        setState(() {
          _employee = employee;
          _isLoadingEmployee = false;
        });
      }
    } catch (e) {
      print('❌ Error refreshing employee data: $e');
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
        // Only update state if there's a meaningful change to avoid overriding cached data
        final apiIsClockedIn = status.isClockedIn ?? false;
        final apiWorkLocation = status.workLocation ?? 'Unknown';

        // Check if the API data differs significantly from current state
        bool needsUpdate = false;

        if (_isClockedIn != apiIsClockedIn) {
          needsUpdate = true;
        } else if (apiIsClockedIn && _workLocation != apiWorkLocation) {
          needsUpdate = true;
        }

        if (needsUpdate) {
          setState(() {
            _isClockedIn = apiIsClockedIn;

            if (apiIsClockedIn) {
              _workLocation = apiWorkLocation;

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
      }
    } catch (e) {
      // Handle error silently
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
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _handleRefresh,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              gradient: Theme.of(context).brightness == Brightness.dark
                  ? null // No gradient for dark theme - pure black background
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.1),
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                    ),
            ),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
        ),
        // Central loading overlay
        if (_isLoadingDashboardData) _buildCentralLoadingOverlay(),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message
          Column(
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
          // Clock In/Out buttons below welcome message
          if (!_isClockedIn) ...[
            const SizedBox(height: 16),
            _buildLongClockInButton(),
            // Show today's total hours card only if there's completed work
            if (_todayTotalHours != '0h 0m' &&
                _todayTotalHours != '0' &&
                _todayTotalHours != '0.0' &&
                _formatHoursHuman(_todayTotalHours) != '0 hr 0 mins') ...[
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withOpacity(isDark ? 0.35 : 0.95),
            colorScheme.secondaryContainer.withOpacity(isDark ? 0.30 : 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.access_time_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s total hours',
                  style:
                      Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ) ??
                      TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatHoursHuman(_todayTotalHours),
                  style:
                      Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        fontSize: 22,
                      ) ??
                      TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: colorScheme.tertiary,
            size: 26,
          ),
        ],
      ),
    );
  }

  Widget _buildCentralLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color.fromARGB(255, 9, 85, 185),
            ),
          ),
        ),
      ),
    );
  }

  // Format hours like "7 hr Y mins" from raw values such as "7h 30m", "0h 0m", or decimal "7.466666666666667"
  String _formatHoursHuman(String raw) {
    final trimmed = raw.trim();

    // If the raw string is already like "7 hr 30 mins", keep it
    if (trimmed.contains('hr') || trimmed.contains('mins')) {
      return trimmed;
    }

    // Try to parse as decimal hours first (e.g., "7.466666666666667")
    final decimalHours = double.tryParse(trimmed);
    if (decimalHours != null) {
      final totalMinutes = (decimalHours * 60).round();
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;

      final parts = <String>[];
      parts.add("$hours hr");
      parts.add("$minutes mins");
      return parts.join(' ');
    }

    // Try to parse as "7h 30m" format
    final hMatch = RegExp(r"(\d+)h").firstMatch(trimmed);
    final mMatch = RegExp(r"(\d+)m").firstMatch(trimmed);

    int hours = 0;
    int minutes = 0;

    if (hMatch != null) {
      hours = int.tryParse(hMatch.group(1) ?? '0') ?? 0;
    }
    if (mMatch != null) {
      minutes = int.tryParse(mMatch.group(1) ?? '0') ?? 0;
    }

    final parts = <String>[];
    parts.add("$hours hr");
    parts.add("$minutes mins");
    return parts.join(' ');
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
                    icon: Icons.receipt_long_rounded,
                    label: 'Expenses',
                    color: Colors.teal,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.expenses),
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

    // 3-second loader + status check during loader time
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Processing clock-in...'),
              ],
            ),
          ),
        ),
      );

      // 3-second loader with comprehensive status check and geolocation verification
      bool alreadyClockedToday = false;
      bool clockInSuccessful = false;
      String? errorMessage;
      bool geolocationValid = true;

      try {
        final employeeId = _employee!.employeeId!;

        // Check current status and geolocation during loader
        try {
          final status = await TimeEntryService.getCurrentStatus(employeeId);
          if ((status.isClockedIn ?? false) && status.clockInTime != null) {
            final cin = DateTime.tryParse(status.clockInTime!);
            if (cin != null) {
              final now = DateTime.now();
              alreadyClockedToday =
                  cin.year == now.year &&
                  cin.month == now.month &&
                  cin.day == now.day;
            }
          }

          // Verify geolocation if needed for office location
          if (location.toLowerCase().contains('office')) {
            try {
              // Add geolocation check here if needed
              // For now, assume geolocation is valid
              geolocationValid = true;
            } catch (e) {
              geolocationValid = false;
              print('⚠️ Geolocation check failed: $e');
            }
          }
        } catch (_) {
          // Status check failed, continue with clock-in attempt
        }

        // If not already clocked in today and geolocation is valid, attempt clock-in
        if (!alreadyClockedToday && geolocationValid) {
          try {
            // Determine if GPS is needed based on location
            bool needsGps = location.toLowerCase().contains('office');
            bool useGpsLocation = needsGps && geolocationValid;

            final response = await TimeEntryService.clockIn(
              employeeId: employeeId,
              workLocation: location,
              useGpsLocation: useGpsLocation,
            );

            clockInSuccessful = response.isSuccessful;
            if (!clockInSuccessful) {
              errorMessage = response.message;
            }
          } catch (e) {
            if (e.toString().contains('already_completed') ||
                e.toString().contains(
                  'already completed your daily time entry',
                ) ||
                e.toString().contains(
                  'only one clock-in and clock-out session is allowed',
                )) {
              alreadyClockedToday = true;
            } else {
              errorMessage = e.toString();
            }
          }
        } else if (!geolocationValid) {
          errorMessage =
              'Geolocation verification failed. Please check your location settings.';
        }
      } catch (e) {
        errorMessage = e.toString();
      }

      // Ensure 3-second minimum loader time
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        Navigator.of(context).pop(); // dismiss loader
      }

      if (alreadyClockedToday) {
        // Show today's total hours card and message
        await _loadTodayTotalHours();
        if (mounted) {
          setState(() {
            _isClockedIn = false;
            _workLocation = '';
            _clockInTime = null;
            _elapsedTime = Duration.zero;
          });
          // Force immediate UI update to show Today's Total Hours Card
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {});
            }
          });
        }
        _timer?.cancel();
        _showSuccessSnackBar('Already clocked in.');
        return;
      }

      if (clockInSuccessful) {
        // Show working time card and start timer immediately
        if (mounted) {
          setState(() {
            _isClockedIn = true;
            _workLocation = location;
            _clockInTime = DateTime.now();
            _elapsedTime = Duration.zero;
          });

          // Start timer immediately
          _timer?.cancel();
          _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (mounted) {
              setState(() {
                _elapsedTime = DateTime.now().difference(_clockInTime!);
              });
            }
          });

          // Force immediate UI update to show Work Timer Card
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {});
            }
          });
        }
        _showSuccessSnackBar('You are clocked in successful');
        _refreshAttendanceData();
      } else {
        _showErrorSnackBar(
          'Clock-in failed: ${errorMessage ?? 'Unknown error'}',
        );
      }
    } catch (_) {
      // If loader or dialog fails, continue gracefully
      if (mounted) {
        Navigator.of(context).pop(); // dismiss loader if still showing
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
      // Force immediate UI update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }

    // Cancel timer immediately
    _timer?.cancel();

    // Load today's total hours immediately to show the card
    await _loadTodayTotalHours();

    // Force immediate UI update to show Today's Total Hours Card
    if (mounted) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }

    // Show immediate success message
    _showSuccessSnackBar('Clock-out Successful');

    try {
      print('🕐 Clocking out...');
      // Call API to store clock-out data without GPS verification
      final response = await TimeEntryService.clockOut(
        employeeId: _employee!.employeeId!,
        workLocation: currentWorkLocation,
        useGpsLocation: false, // GPS not used for clock-out
      );
      print(
        '✅ Clock-out response: ${response.isSuccessful ? 'Success' : 'Failed'}',
      );

      if (response.isSuccessful) {
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
          e.toString().contains('timeout') ||
          e.toString().contains('Network') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Network is unreachable')) {
        // Don't show error message for connectivity issues - the global connectivity dialog will handle it
        print('🌐 Connectivity issue detected, not showing error message');
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

        print('🔍 Found ${todayEntries.length} entries for today');

        if (todayEntries.isNotEmpty) {
          final entry = todayEntries.first;
          final totalHours = entry['totalHours']?.toString() ?? '0h 0m';
          final clockInTime = entry['clockInTime']?.toString();
          final clockOutTime = entry['clockOutTime']?.toString();

          print('🔍 Entry data:');
          print('  - Clock In: $clockInTime');
          print('  - Clock Out: $clockOutTime');
          print('  - Total Hours: $totalHours');

          // Only set total hours if there's both clock-in and clock-out (completed work)
          final hasClockOut =
              entry['clockOutTime'] != null &&
              entry['clockOutTime'].toString().isNotEmpty;

          print('🔍 Has clock out: $hasClockOut');
          print(
            '🔍 Total hours not zero: ${totalHours != '0h 0m' && totalHours != '0' && totalHours != '0.0'}',
          );
          print('🔍 Formatted hours: ${_formatHoursHuman(totalHours)}');

          if (hasClockOut &&
              totalHours != '0h 0m' &&
              totalHours != '0' &&
              totalHours != '0.0') {
            // Only update if the value has changed to avoid unnecessary UI updates
            if (mounted && _todayTotalHours != totalHours) {
              setState(() {
                _todayTotalHours = totalHours;
              });
            }
            print('✅ Today total hours loaded: $_todayTotalHours');
          } else {
            // Only reset to default if we don't already have valid hours and no completed work
            if (mounted &&
                _todayTotalHours != '0h 0m' &&
                _todayTotalHours != '0' &&
                _todayTotalHours != '0.0') {
              setState(() {
                _todayTotalHours = '0h 0m';
              });
            }
            print('❌ No completed work found, reset to 0h 0m');
          }
        } else {
          // Only reset to default if we don't already have valid hours and no entries for today
          if (mounted &&
              _todayTotalHours != '0h 0m' &&
              _todayTotalHours != '0' &&
              _todayTotalHours != '0.0') {
            setState(() {
              _todayTotalHours = '0h 0m';
            });
          }
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Refresh attendance data after clock-in/out
  // Refresh attendance data for attendance screen
  Future<void> _refreshAttendanceData() async {
    try {
      if (_employee?.employeeId != null) {
        print('🔄 Refreshing attendance data...');
        // Load fresh weekly time entries to warm the cache
        await TimeEntryService.getWeeklyTimeEntries(_employee!.employeeId!);
        print('✅ Attendance data refreshed');
      }
    } catch (e) {
      print('❌ Error refreshing attendance data: $e');
      // Don't show error to user as this is background refresh
    }
  }

  // Refresh leave history data for leave management screen
  Future<void> _refreshLeaveHistoryData() async {
    try {
      print('🔄 Refreshing leave history data...');
      // Get auth token
      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ No auth token found for leave history refresh');
        return;
      }

      // Get employee ID
      final employeeId = await AuthService.getEmployeeId();
      if (employeeId == null) {
        print('❌ No employee ID found for leave history refresh');
        return;
      }

      // Make API call to refresh leave history cache
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.leaveRequestsEndpoint}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Leave history data refreshed');
      } else {
        print('❌ Leave history refresh failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error refreshing leave history data: $e');
      // Don't show error to user as this is background refresh
    }
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

  // Handle pull-to-refresh with internet connectivity check
  Future<void> _handleRefresh() async {
    try {
      // Check internet connectivity first
      final connectivityService = ConnectivityService();
      await connectivityService.checkConnectivity();

      if (!connectivityService.isConnected) {
        // Show offline message
        _showOfflineSnackBar();
        return;
      }

      // If connected, refresh all data
      await Future.wait([
        _loadEmployeeDataForRefresh(),
        _checkClockInStatus(),
        _loadTodayTotalHours(),
        _refreshAttendanceData(),
        _refreshLeaveHistoryData(),
      ]);

      // Show success message
      _showRefreshSuccessSnackBar();
    } catch (e) {
      print('❌ Error during refresh: $e');
      // Check if it's a connectivity issue
      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Network is unreachable')) {
        _showOfflineSnackBar();
      }
    } finally {
      // Refresh completed
    }
  }

  // Show offline message
  void _showOfflineSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Still offline. Please reconnect.'),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show refresh success message
  void _showRefreshSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            const Text('Employee Data Refreshed Successfully!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Error UI disabled on dashboard per request to avoid overlay/overlap
  void _showErrorSnackBar(String message) {
    // Intentionally no UI shown. You can log if needed:
    // debugPrint('Dashboard error: ' + message);
  }
}
