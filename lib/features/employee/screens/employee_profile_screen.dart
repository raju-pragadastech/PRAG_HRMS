import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/employee.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/profile_image_picker.dart';

class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Employee? _employee;
  bool _isLoading = true;
  String? _error;

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

    _loadEmployeeData();
  }

  Future<void> _loadEmployeeData() async {
    try {
      print('👤 Loading employee profile...');
      final employee = await AuthService.getDetailedEmployeeProfile();
      print('✅ Employee profile loaded: ${employee?.firstName ?? 'Unknown'}');

      if (mounted) {
        setState(() {
          _employee = employee;
          _isLoading = false;
        });

        if (employee != null) {
          _animationController.forward();
          print(
            '✅ Detailed employee profile data loaded: ${employee.fullName}',
          );
          print('📱 Profile data: ${employee.toJson()}');
        } else {
          setState(() {
            _error = 'No employee data found. Please check your login status.';
          });
        }
      }
    } catch (e) {
      print('❌ Error loading detailed employee profile data: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Show document picker and upload dialog

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Profile'), elevation: 0),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          gradient: Theme.of(context).brightness == Brightness.dark
              ? null // No gradient for dark theme - pure black background
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading profile...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEmployeeData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_employee == null) {
      return const Center(child: Text('No employee data available'));
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SlideTransition(
              position: _slideAnimation,
              child: _buildProfileHeader(),
            ),
            const SizedBox(height: 24),
            SlideTransition(
              position: _slideAnimation,
              child: _buildPersonalDetails(),
            ),
            const SizedBox(height: 24),
            SlideTransition(
              position: _slideAnimation,
              child: _buildJobDetails(),
            ),
            const SizedBox(height: 24),
            SlideTransition(
              position: _slideAnimation,
              child: _buildSkillsSection(),
            ),
            const SizedBox(height: 24),
            SlideTransition(
              position: _slideAnimation,
              child: _buildSecuritySection(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Profile Photo with Upload Option
            if (_employee?.employeeId != null)
              ProfileImagePicker(
                currentImageUrl: _employee?.profileImage,
                userId: _employee!.employeeId!,
                size: 70.0,
                onImageChanged: (imageUrl) {
                  // Update the employee object with new image URL
                  if (mounted) {
                    setState(() {
                      _employee = Employee(
                        employeeId: _employee?.employeeId,
                        firstName: _employee?.firstName,
                        lastName: _employee?.lastName,
                        email: _employee?.email,
                        phone: _employee?.phone,
                        department: _employee?.department,
                        position: _employee?.position,
                        role: _employee?.role,
                        profileImage: imageUrl.isNotEmpty ? imageUrl : null,
                        joinDate: _employee?.joinDate,
                        status: _employee?.status,
                        address: _employee?.address,
                        dateOfBirth: _employee?.dateOfBirth,
                        emergencyContact: _employee?.emergencyContact,
                        manager: _employee?.manager,
                        workLocation: _employee?.workLocation,
                        experience: _employee?.experience,
                        education: _employee?.education,
                        skills: _employee?.skills,
                      );
                    });
                  }
                },
              )
            else
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                ),
                child: Icon(Icons.person, size: 35, color: Colors.grey[400]),
              ),
            const SizedBox(width: 20),
            // Employee Information on Right
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Employee Name
                  Text(
                    _employee!.fullName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Position
                  Row(
                    children: [
                      Icon(Icons.work_rounded, color: Colors.green, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _employee!.position ?? 'Position not specified',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Employee ID
                  Row(
                    children: [
                      Icon(Icons.badge_rounded, color: Colors.blue, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'ID: ${_employee!.employeeId ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _employee!.status ?? 'Active',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDetails() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Personal Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow(
              Icons.email_rounded,
              'Email',
              _employee!.email ?? 'Email not provided',
              Colors.blue,
            ),
            _buildDetailRow(
              Icons.phone_rounded,
              'Phone',
              _employee!.phone ?? 'Phone not provided',
              Colors.green,
            ),
            _buildDetailRow(
              Icons.location_on_rounded,
              'Address',
              _employee!.address ?? 'Address not provided',
              Colors.orange,
            ),
            _buildDetailRow(
              Icons.cake_rounded,
              'Date of Birth',
              _employee!.dateOfBirth ?? 'Date of birth not provided',
              Colors.purple,
            ),
            _buildDetailRow(
              Icons.emergency_rounded,
              'Emergency Contact',
              _employee!.emergencyContact ?? 'Emergency contact not provided',
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.stars_rounded,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Skills & Experience',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow(
              Icons.work_rounded,
              'Experience',
              _employee!.experience ?? 'Experience not provided',
              Colors.blue,
            ),
            _buildDetailRow(
              Icons.school_rounded,
              'Education',
              _employee!.education ?? 'Education not provided',
              Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Technical Skills',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_employee!.skills ?? ['No skills listed']).map((
                skill,
              ) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.indigo.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    skill,
                    style: TextStyle(
                      color: Colors.indigo.shade700,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobDetails() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.work_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Job Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow(
              Icons.business_rounded,
              'Department',
              _employee!.department ?? 'Department not specified',
              Colors.blue,
            ),
            _buildDetailRow(
              Icons.work_rounded,
              'Position',
              _employee!.position ?? 'Position not specified',
              Colors.green,
            ),
            _buildDetailRow(
              Icons.calendar_today_rounded,
              'Join Date',
              _employee!.joinDate ?? 'Join date not specified',
              Colors.orange,
            ),
            _buildDetailRow(
              Icons.person_rounded,
              'Manager',
              _employee!.manager ?? 'Vamshi Krishna M',
              Colors.purple,
            ),
            _buildDetailRow(
              Icons.location_on_rounded,
              'Work Location',
              _employee!.workLocation ??
                  ' JNTU-Hitech City Road, KPHB, Hyderabad – 500072 ',
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.security_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Security & Privacy',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSecurityOption(
              icon: Icons.logout_rounded,
              title: 'Logout from This Device',
              subtitle:
                  'Sign out from this device only (other devices remain logged in)',
              color: Colors.blue,
              onTap: _showLogoutCurrentDeviceDialog,
            ),
            _buildSecurityOption(
              icon: Icons.logout_rounded,
              title: 'Logout from All Devices',
              subtitle:
                  'Sign out from all devices and require re-authentication',
              color: Colors.orange,
              onTap: _showLogoutAllDevicesDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutCurrentDeviceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.blue),
            SizedBox(width: 8),
            Text('Logout from This Device'),
          ],
        ),
        content: const Text(
          'This will sign you out from this device only. You will remain logged in on other devices. You will need to log in again on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logoutFromCurrentDevice();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout This Device'),
          ),
        ],
      ),
    );
  }

  void _showLogoutAllDevicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Logout from All Devices'),
          ],
        ),
        content: const Text(
          'This will sign you out from all devices where you are currently logged in. You will need to log in again on all devices. This is useful for security purposes or when switching devices.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logoutFromAllDevices();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout All Devices'),
          ),
        ],
      ),
    );
  }

  Future<void> _logoutFromCurrentDevice() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Logging out from this device...'),
            ],
          ),
        ),
      );

      // Logout from current device
      await AuthService.logoutCurrentDevice();

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged out from this device'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Navigate to login screen
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout from this device: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logoutFromAllDevices() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Logging out from all devices...'),
            ],
          ),
        ),
      );

      // Logout from all devices
      await AuthService.logoutAllDevices();

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged out from all devices'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Navigate to login screen
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to logout from all devices: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
