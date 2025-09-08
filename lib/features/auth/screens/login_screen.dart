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

  // Validation errors
  String? _emailError;
  String? _passwordError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                _buildHeader(),
                const SizedBox(height: 32),
                _buildLoginForm(),
                const SizedBox(height: 24),
                _buildLoginButton(),
                const SizedBox(height: 12),
                _buildForgotPassword(),
                const SizedBox(height: 12),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset(
            'assets/Prag_LOGO.png',
            width: 72,
            height: 72,
            fit: BoxFit.contain,
            // Prevent crashes if the asset is temporarily missing
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.business_rounded,
              size: 42,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Login to your PragadasTech account',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
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
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          color: Theme.of(context).cardColor,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Login Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
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
                    color: _emailError != null
                        ? Colors.red
                        : Theme.of(context).primaryColor,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _emailError != null
                          ? Colors.red
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _emailError != null
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  errorStyle: const TextStyle(height: 0),
                ),
              ),
              // Email/Employee ID Error Message
              if (_emailError != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Text(
                    _emailError!,
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
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
                    color: _passwordError != null
                        ? Colors.red
                        : Theme.of(context).primaryColor,
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
                    borderSide: BorderSide(
                      color: _passwordError != null
                          ? Colors.red
                          : Colors.grey.shade300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _passwordError != null
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
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
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          minimumSize: const Size(0, 36),
        ),
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
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
    } else if (passwordController.text.trim().length < 6) {
      setState(() {
        _passwordError = 'Password must be at least 6 digits';
      });
      hasError = true;
    }

    if (hasError) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔐 Attempting login...');
      // API call
      final response = await AuthService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      print('✅ Login response: ${response.success ? 'Success' : 'Failed'}');

      // Check if login was successful
      if (response.success == true && response.token != null) {
        // Clear any snackbars and navigate to home screen
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        }
      } else {
        // Handle login failure based on response message
        if (response.message != null) {
          final message = response.message!.toLowerCase();
          if (message.contains('password') &&
              message.contains('6') &&
              message.contains('100')) {
            // Password length error
            setState(() {
              _passwordError = 'Password must be at least 6 digits';
            });
          } else if (message.contains('password_invalid') ||
              message.contains('invalid_password') ||
              message.contains('wrong password') ||
              (message.contains('password') &&
                  message.contains('invalid') &&
                  !message.contains('employee') &&
                  !message.contains('email'))) {
            // Password invalid
            setState(() {
              _passwordError = 'Password is invalid';
            });
          } else if (message.contains('invalid employee id') ||
              message.contains('invalid employee') ||
              message.contains('employee id') ||
              (message.contains('email') && message.contains('invalid')) ||
              message.contains('user_not_found') ||
              message.contains('employee_not_found') ||
              message.contains('invalid employee id/email or password')) {
            // Email/Employee ID error - backend says both could be wrong but we'll show email error
            setState(() {
              _emailError = 'Invalid email/employee ID';
            });
          } else {
            // Both fields wrong
            setState(() {
              _emailError = 'Invalid email/employee ID';
              _passwordError = 'Both credentials are invalid';
            });
          }
        } else {
          // No specific message - both fields wrong
          setState(() {
            _emailError = 'Invalid email/employee ID';
            _passwordError = 'Both credentials are invalid';
          });
        }
      }
    } catch (e) {
      final errorMessage = e.toString();

      // Check for specific error types
      if (errorMessage.contains('password') &&
          (errorMessage.contains('6') ||
              errorMessage.contains('length') ||
              errorMessage.contains('characters'))) {
        // Password length error
        setState(() {
          _passwordError = 'Password must be at least 6 digits';
        });
      } else if (errorMessage.contains('password_invalid') ||
          errorMessage.contains('invalid_password') ||
          errorMessage.contains('wrong password') ||
          (errorMessage.contains('password') &&
              errorMessage.contains('invalid') &&
              !errorMessage.contains('employee') &&
              !errorMessage.contains('email'))) {
        // Only password is wrong
        setState(() {
          _passwordError = 'Password is invalid';
        });
      } else if (errorMessage.contains('email_invalid') ||
          errorMessage.contains('invalid_email') ||
          errorMessage.contains('user_not_found') ||
          errorMessage.contains('employee_not_found') ||
          errorMessage.contains('invalid employee id') ||
          errorMessage.contains('invalid employee') ||
          errorMessage.contains('employee id') ||
          (errorMessage.contains('email') &&
              errorMessage.contains('invalid')) ||
          errorMessage.contains('invalid employee id/email or password')) {
        // Only email/employee ID is wrong - backend says both could be wrong but we'll show email error
        setState(() {
          _emailError = 'Invalid email/employee ID';
        });
      } else if (errorMessage.contains('credentials_invalid') ||
          errorMessage.contains('invalid_credentials') ||
          errorMessage.contains('authentication_failed')) {
        // Both are wrong
        setState(() {
          _emailError = 'Invalid email/employee ID';
          _passwordError = 'Both credentials are invalid';
        });
      } else if (errorMessage.contains('Network timeout') ||
          errorMessage.contains('Network error') ||
          errorMessage.contains('Cannot connect to server') ||
          errorMessage.contains('SocketException') ||
          errorMessage.contains('Failed host lookup') ||
          errorMessage.contains('TimeoutException')) {
        // Network error
        setState(() {
          _emailError =
              'Network error. Please check your internet connection and try again.';
        });
      } else {
        // Generic error - both fields wrong
        setState(() {
          _emailError = 'Invalid email/employee ID';
          _passwordError = 'Both credentials are invalid';
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
}
