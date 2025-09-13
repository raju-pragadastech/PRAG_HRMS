import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../services/screens/services_screen.dart';
import '../../announcements/screens/announcements_screen.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/employee.dart';
import '../../../core/widgets/theme_selector.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1; // Start with Home (middle tab)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Employee? _employee;
  bool _isLoadingEmployee = true;

  final List<Widget> _screens = [
    const ServicesScreen(),
    const DashboardScreen(),
    const AnnouncementsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
  }

  Future<void> _loadEmployeeData() async {
    try {
      setState(() {
        _isLoadingEmployee = true;
      });

      final employee = await AuthService.getCurrentUserProfile();

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

  Future<void> _refreshEmployeeData() async {
    await _loadEmployeeData();
  }

  Widget _buildUnifiedHeader() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        String titleText = 'Home';
        if (_currentIndex == 0) {
          titleText = 'Services';
        } else if (_currentIndex == 2) {
          titleText = 'Announcements';
        }
        return AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          title: Text(
            titleText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            // Theme Toggle Button
            IconButton(
              icon: Icon(
                themeService.isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
              ),
              onPressed: () => _showThemeSelector(),
              tooltip: 'Theme Settings',
            ),
            // Profile Photo (Smaller)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.employeeProfile);
                },
                child: Tooltip(
                  message: 'View Profile',
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: _employee?.profileImage != null
                        ? ClipOval(
                            child: Image.network(
                              _employee!.profileImage!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 18,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: _buildUnifiedHeader(),
      ),
      drawer: _buildDrawer(),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: Theme.of(context).primaryColor,
              unselectedItemColor: Colors.grey,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.apps_rounded),
                  label: 'Services',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.notifications_rounded),
                  label: 'Announcements',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Drawer(
          width:
              MediaQuery.of(context).size.width * 0.65, // 65% of screen width
          backgroundColor: themeService.isDarkMode
              ? const Color(0xFF000000) // Pure black for dark theme
              : null, // Use theme default for light theme
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: themeService.isDarkMode
                      ? const Color(0xFF000000) // Pure black for dark theme
                      : Theme.of(
                          context,
                        ).primaryColor, // Primary color for light theme
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _showImagePicker,
                      child: Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: themeService.isDarkMode
                                  ? Colors.white.withOpacity(
                                      0.2,
                                    ) // White for dark theme
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onPrimary.withOpacity(
                                      0.2,
                                    ), // Theme color for light theme
                              border: Border.all(
                                color: themeService.isDarkMode
                                    ? Colors.white.withOpacity(
                                        0.3,
                                      ) // White for dark theme
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onPrimary.withOpacity(
                                        0.3,
                                      ), // Theme color for light theme
                                width: 2,
                              ),
                            ),
                            child: _employee?.profileImage != null
                                ? ClipOval(
                                    child: Image.network(
                                      _employee!.profileImage!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.person_rounded,
                                          color: themeService.isDarkMode
                                              ? Colors
                                                    .white // White for dark theme
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary, // Theme color for light theme
                                          size: 30,
                                        );
                                      },
                                    ),
                                  )
                                : Icon(
                                    Icons.person_rounded,
                                    color: themeService.isDarkMode
                                        ? Colors
                                              .white // White for dark theme
                                        : Theme.of(context)
                                              .colorScheme
                                              .onPrimary, // Theme color for light theme
                                    size: 30,
                                  ),
                          ),
                          // Refresh button
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _refreshEmployeeData,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: themeService.isDarkMode
                                      ? Colors
                                            .white // White for dark theme
                                      : Theme.of(context)
                                            .colorScheme
                                            .onPrimary, // Theme color for light theme
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.refresh_rounded,
                                  size: 12,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingEmployee)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            themeService.isDarkMode
                                ? Colors
                                      .white // White for dark theme
                                : Theme.of(context)
                                      .colorScheme
                                      .onPrimary, // Theme color for light theme
                          ),
                        ),
                      )
                    else
                      Text(
                        _employee?.fullName ?? 'Loading...',
                        style: TextStyle(
                          color: themeService.isDarkMode
                              ? Colors
                                    .white // White for dark theme
                              : Theme.of(context)
                                    .colorScheme
                                    .onPrimary, // Theme color for light theme
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    const SizedBox(height: 2),
                    if (!_isLoadingEmployee)
                      Text(
                        _employee?.email ?? 'No email available',
                        style: TextStyle(
                          color: themeService.isDarkMode
                              ? Colors.white.withOpacity(
                                  0.9,
                                ) // White for dark theme
                              : Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withOpacity(
                                  0.9,
                                ), // Theme color for light theme
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    const SizedBox(height: 2),
                    if (!_isLoadingEmployee)
                      Text(
                        'Employee ID: ${_employee?.employeeId ?? 'N/A'}',
                        style: TextStyle(
                          color: themeService.isDarkMode
                              ? Colors.white.withOpacity(
                                  0.8,
                                ) // White for dark theme
                              : Theme.of(
                                  context,
                                ).colorScheme.onPrimary.withOpacity(
                                  0.8,
                                ), // Theme color for light theme
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                  ],
                ),
              ),
              _buildDrawerItem(
                icon: Icons.dashboard_rounded,
                title: 'Dashboard',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 1); // Switch to Dashboard tab
                },
              ),
              _buildDrawerItem(
                icon: Icons.person_rounded,
                title: 'Profile',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.employeeProfile);
                },
              ),
              _buildDrawerItem(
                icon: Icons.calendar_today_rounded,
                title: 'Leave Management',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.leave);
                },
              ),
              _buildDrawerItem(
                icon: Icons.access_time_rounded,
                title: 'Attendance',
                color: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.attendance);
                },
              ),
              _buildDrawerItem(
                icon: Icons.campaign_rounded,
                title: 'Announcements',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  setState(
                    () => _currentIndex = 2,
                  ); // Switch to Announcements tab
                },
              ),
              _buildDrawerItem(
                icon: Icons.support_agent_rounded,
                title: 'Support',
                color: Colors.teal,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.support);
                },
              ),
              const Divider(),
              _buildDrawerItem(
                icon: Icons.palette_rounded,
                title: 'Theme Settings',
                color: Colors.indigo,
                onTap: () {
                  Navigator.pop(context);
                  _showThemeSelector();
                },
              ),
              _buildDrawerItem(
                icon: Icons.logout_rounded,
                title: 'Logout',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (color ?? Theme.of(context).primaryColor).withOpacity(
                  0.1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color ?? Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            onTap: onTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            hoverColor: Theme.of(context).primaryColor.withOpacity(0.05),
          ),
        );
      },
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Update Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildImageOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Take Photo',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        _takePhoto();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImageOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Choose from Gallery',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(context);
                        _chooseFromGallery();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageOption({
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

  void _takePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Camera functionality would be implemented here'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _chooseFromGallery() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gallery functionality would be implemented here'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: const ThemeSelector(),
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
