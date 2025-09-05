import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _selectedRole = 'Employee';

  // Validation errors
  String? _emailError;
  String? _passwordError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Header Section
                _buildHeader(),
                const SizedBox(height: 40),
                // Login Form
                _buildLoginForm(),
                const SizedBox(height: 24),
                // Login Button
                _buildLoginButton(),
                const SizedBox(height: 16),
                // Forgot Password
                _buildForgotPassword(),
                const SizedBox(height: 17),
                // Footer
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.85),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.business_rounded,
            size: 42,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Login to your PragadasTech account',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Card(
      elevation: 12,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Theme.of(context).primaryColor.withOpacity(0.05),
            ],
          ),
          border: Border.all(color: Colors.grey.withOpacity(0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Login Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              // Email/Employee ID Field
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  setState(() {
                    _emailError = null;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Email Address / Employee ID',
                  hintText: 'Enter your email or employee ID',
                  prefixIcon: Icon(
                    Icons.person_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  errorStyle: const TextStyle(height: 0),
                ),
              ),
              // Email/Employee ID Error Message
              if (_emailError != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _emailError!.contains('Network')
                        ? Colors.red.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _emailError!.contains('Network')
                          ? Colors.red.shade300
                          : Colors.red.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _emailError!.contains('Network')
                            ? Icons.wifi_off
                            : Icons.error_outline,
                        color: _emailError!.contains('Network')
                            ? Colors.red.shade600
                            : Colors.red.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _emailError!,
                          style: TextStyle(
                            color: _emailError!.contains('Network')
                                ? Colors.red.shade700
                                : Colors.red.shade600,
                            fontSize: _emailError!.contains('Network')
                                ? 14
                                : 12,
                            fontWeight: _emailError!.contains('Network')
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Password Field
              TextField(
                controller: passwordController,
                obscureText: !_isPasswordVisible,
                onChanged: (value) {
                  setState(() {
                    _passwordError = null;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: Icon(
                    Icons.lock_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  errorStyle: const TextStyle(height: 0),
                ),
              ),
              // Password Error Message
              if (_passwordError != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Text(
                    _passwordError!,
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Role Selection Dropdown
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: 'Role',
                  hintText: 'Select your role',
                  prefixIcon: Icon(
                    Icons.work_outline,
                    color: Theme.of(context).primaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: 'Employee', child: Text('Employee')),
                  DropdownMenuItem(value: 'HR', child: Text('HR')),
                  DropdownMenuItem(value: 'Manager', child: Text('Manager')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Login',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return TextButton(
      onPressed: () {
        // TODO: Implement forgot password functionality
      },
      child: Text(
        'Forgot Password?',
        style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // Debug button (only show in debug mode)
        if (kDebugMode) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.debug);
            },
            child: const Text(
              'View Debug Logs',
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ),
        ],
        Text(
          '© 2024 PragadasTech. All rights reserved.',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  void _handleLogin() async {
    // Clear previous errors
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    // Validate inputs
    bool hasError = false;

    if (emailController.text.trim().isEmpty) {
      setState(() {
        _emailError = 'Please enter your email or employee ID';
      });
      hasError = true;
    } else if (!_isValidEmailOrEmployeeId(emailController.text.trim())) {
      setState(() {
        _emailError = 'Please enter a valid email or employee ID';
      });
      hasError = true;
    }

    if (passwordController.text.trim().isEmpty) {
      setState(() {
        _passwordError = 'Please enter your password';
      });
      hasError = true;
    }

    if (hasError) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Real API call
      final response = await AuthService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      // Debug logging
      print('🔍 Login response debug:');
      print('  - success: ${response.success}');
      print('  - token: ${response.token != null ? "present" : "null"}');
      print('  - message: ${response.message}');
      print('  - employeeId: ${response.employeeId}');
      print('  - role: ${response.role}');
      print('  - firstName: ${response.firstName}');
      print('  - lastName: ${response.lastName}');
      print('  - email: ${response.email}');

      // Check for device limit error in response message first
      bool isDeviceLimitError = false;

      if (response.message != null) {
        final message = response.message!.toLowerCase();
        print('🔍 Checking message for device limit: "$message"');

        // Check for specific device limit patterns
        if (message.contains('device limit') ||
            message.contains('multiple devices') ||
            message.contains('too many devices') ||
            message.contains('device not supported') ||
            message.contains('maximum devices') ||
            message.contains('device limit exceeded') ||
            message.contains('device count') ||
            message.contains('max devices') ||
            message.contains('device quota') ||
            message.contains('concurrent sessions') ||
            message.contains('session limit') ||
            message.contains('device registration') ||
            message.contains('not supported') ||
            message.contains('multiple device') ||
            message.contains('device') ||
            message.contains('multiple')) {
          isDeviceLimitError = true;
          print('🚫 Device limit detected in response message: $message');
        }
      }

      // Also check if success is false and no token (indicating device limit)
      if (response.success == false &&
          response.token == null &&
          (response.message?.toLowerCase().contains('device') == true ||
              response.message?.toLowerCase().contains('multiple') == true)) {
        isDeviceLimitError = true;
        print('🚫 Device limit detected in failed response');
      }

      if (isDeviceLimitError) {
        setState(() {
          _emailError =
              'Device limit exceeded. Please logout from other devices or contact support.';
        });
        if (mounted) {
          _showDeviceLimitDialog();
        }
        return;
      }

      // Check if login was successful (either success field or token exists)
      final isLoginSuccessful =
          (response.success == true) ||
          (response.token != null && response.token!.isNotEmpty);

      if (isLoginSuccessful && response.token != null) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Welcome back! Logged in as ${response.role ?? _selectedRole}',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Navigate to home screen
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        }
      } else {
        // Handle login failure
        if (response.success == false &&
            response.token == null &&
            response.message != null &&
            response.message!.isNotEmpty) {
          final message = response.message!.toLowerCase();
          // Check for device limit keywords
          if (message.contains('device limit') ||
              message.contains('multiple devices') ||
              message.contains('too many devices') ||
              message.contains('device not supported') ||
              message.contains('maximum devices') ||
              message.contains('device limit exceeded') ||
              message.contains('device count') ||
              message.contains('max devices') ||
              message.contains('device quota') ||
              message.contains('concurrent sessions') ||
              message.contains('session limit') ||
              message.contains('device registration') ||
              message.contains('not supported') ||
              message.contains('multiple device')) {
            print('🚫 Device limit detected in message: $message');
            setState(() {
              _emailError =
                  'Device limit exceeded. Please logout from other devices or contact support.';
            });
            if (mounted) {
              _showDeviceLimitDialog();
            }
          } else {
            // Regular login failure
            print('🔍 Regular login failure: $message');
            setState(() {
              _emailError =
                  'Invalid credentials. Please check your email/employee ID and password.';
            });
          }
        } else {
          // No specific message, treat as invalid credentials
          setState(() {
            _emailError =
                'Invalid credentials. Please check your email/employee ID and password.';
          });
        }
      }
    } catch (e) {
      final errorMessage = e.toString();
      print('🔍 Login catch block - Error message: $errorMessage');

      if (errorMessage.contains('password_invalid')) {
        setState(() {
          _passwordError = 'Password is invalid';
        });
      } else if (errorMessage.contains('device_limit_exceeded')) {
        setState(() {
          _emailError =
              'Device limit exceeded. Please logout from other devices or contact support.';
        });

        // Show helpful dialog for device limit exceeded
        if (mounted) {
          _showDeviceLimitDialog();
        }
      } else if (errorMessage.contains('credentials_invalid')) {
        setState(() {
          _emailError =
              'Invalid credentials. Please check your email/employee ID and password.';
        });
      } else if (errorMessage.contains('Network timeout') ||
          errorMessage.contains('Network error') ||
          errorMessage.contains('Cannot connect to server') ||
          errorMessage.contains('SocketException') ||
          errorMessage.contains('Failed host lookup') ||
          errorMessage.contains('TimeoutException')) {
        // Show network error message prominently
        setState(() {
          _emailError =
              'Network error. Please check your internet connection and try again.';
        });

        // Show a more prominent error dialog for network issues
        if (mounted) {
          _showNetworkErrorDialog();
          _showNetworkErrorSnackBar();
        }
      } else {
        setState(() {
          _emailError =
              'Login failed. Please check your credentials and try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Validate email or employee ID format
  bool _isValidEmailOrEmployeeId(String input) {
    // Check if it's a valid email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (emailRegex.hasMatch(input)) {
      return true;
    }

    // Check if it's a valid employee ID (alphanumeric, at least 3 characters)
    final employeeIdRegex = RegExp(r'^[A-Za-z0-9]{3,}$');
    return employeeIdRegex.hasMatch(input);
  }

  // Show device limit exceeded dialog
  void _showDeviceLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.devices, color: Colors.orange),
            SizedBox(width: 8),
            Text('Device Limit Exceeded'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have reached the maximum number of devices allowed for your account.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'To continue, you can:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Logout from other devices'),
            Text('• Contact your administrator for assistance'),
            Text('• Wait for inactive sessions to expire'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to a help/support screen or show contact info
              _showContactSupportDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  // Show contact support dialog
  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.support_agent, color: Colors.blue),
            SizedBox(width: 8),
            Text('Contact Support'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If you need assistance with device management, please contact your administrator or IT support team.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'You can also try:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Logging out from other devices you no longer use'),
            Text('• Clearing browser/app data on unused devices'),
            Text('• Waiting for inactive sessions to automatically expire'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNetworkErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red),
            SizedBox(width: 8),
            Text('Network Error'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unable to connect to the server. Please check your internet connection and try again.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Troubleshooting steps:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Check your internet connection'),
            Text('• Try switching between WiFi and mobile data'),
            Text('• Restart the app'),
            Text('• Contact support if the problem persists'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogin(); // Retry login
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Show a snackbar for network errors
  void _showNetworkErrorSnackBar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Network error. Please check your internet connection.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _handleLogin,
          ),
        ),
      );
    }
  }
}
