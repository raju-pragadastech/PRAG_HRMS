import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';

class ForgotPasswordDialog extends StatefulWidget {
  final Function(String)? onSuccess;

  const ForgotPasswordDialog({super.key, this.onSuccess});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 350,
        height: 280,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reset Password',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Enter your email or employee ID to receive reset instructions',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Email/Employee ID Field
            TextField(
              controller: _emailController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Email or Employee ID',
                hintText: 'Enter your email or employee ID',
                prefixIcon: const Icon(Icons.person_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: _error,
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleSubmit(),
            ),
            const Spacer(),
            const SizedBox(height: 12),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Reset Password',
                            style: TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter your email or employee ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await AuthService.forgotPassword(
        _emailController.text.trim(),
      );

      if (mounted) {
        // Check if the response indicates email was sent successfully
        final message = response['message'] ?? '';
        print('🔐 Forgot Password Dialog - Response message: $message');
        print('🔐 Forgot Password Dialog - Full response: $response');

        if (message.toLowerCase().contains('email sent') ||
            message.toLowerCase().contains('reset email') ||
            message.toLowerCase().contains('successfully')) {
          print('🔐 Showing success dialog...');

          // Close the reset email card first
          Navigator.of(context).pop();

          // Add a small delay to ensure the first dialog closes
          Future.delayed(Duration(milliseconds: 100), () {
            if (mounted) {
              // Show success dialog
              print('🔐 Creating success dialog...');
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  print('🔐 Building success dialog widget...');
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Green approval icon
                        Icon(Icons.check_circle, color: Colors.green, size: 64),
                        const SizedBox(height: 16),
                        // Success message
                        Text(
                          'Password reset link has been sent successfully to your email.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // OK button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              print(
                                '🔐 OK button pressed - navigating to login...',
                              );
                              Navigator.of(
                                context,
                              ).pop(); // Close success dialog
                              // Navigate to login page
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login',
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'OK',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          });

          // Call callback if provided
          if (widget.onSuccess != null) {
            widget.onSuccess!('email_sent');
          }
        } else {
          // If no success message, show error
          setState(() {
            _error =
                'Failed to send reset email. Please try again or contact support.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');

        // Handle specific API errors
        if (errorMessage.contains('credentials_invalid') ||
            errorMessage.contains('No account found')) {
          errorMessage =
              'No account found with this email or employee ID. Please check your details and try again.';
        } else if (errorMessage.contains('Invalid or expired token') ||
            errorMessage.contains('404') ||
            errorMessage.contains('Not Found')) {
          errorMessage =
              'Password reset feature is not available yet. Please contact your administrator for password assistance.';
        } else if (errorMessage.contains('500') ||
            errorMessage.contains('Internal Server Error')) {
          errorMessage =
              'Server error. Please try again later or contact support.';
        } else if (errorMessage.contains('timeout') ||
            errorMessage.contains('TimeoutException')) {
          errorMessage =
              'Request timed out. Please check your internet connection and try again.';
        } else if (errorMessage.contains('SocketException') ||
            errorMessage.contains('NetworkException')) {
          errorMessage =
              'Network error. Please check your internet connection and try again.';
        } else {
          errorMessage =
              'An error occurred. Please try again or contact support.';
        }

        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
      }
    }
  }
}
