import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/services/auth_service.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen>
    with TickerProviderStateMixin {
  int _selectedTab = 0;
  bool _isSubmitting = false;
  bool _isLoadingHistory = false;

  // Request Leave Form Data
  String _selectedLeaveType = 'ANNUAL_LEAVE';
  String _selectedHalfDayType = 'MORNING_HALF';
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();

  // History Data
  List<Map<String, dynamic>> _leaveHistory = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Leave Types
  final List<Map<String, String>> _leaveTypes = [
    {'value': 'ANNUAL_LEAVE', 'label': 'Annual Leave'},
    {'value': 'SICK_LEAVE', 'label': 'Sick Leave'},
    {'value': 'HALF_DAY', 'label': 'Half Day'},
    {'value': 'WORK_FROM_HOME', 'label': 'Work From Home'},
    {'value': 'PERSONAL_LEAVE', 'label': 'Personal Leave'},
    {'value': 'EMERGENCY_LEAVE', 'label': 'Emergency Leave'},
  ];

  // Half Day Types
  final List<Map<String, String>> _halfDayTypes = [
    {'value': 'MORNING_HALF', 'label': 'Morning Half'},
    {'value': 'AFTERNOON_HALF', 'label': 'Afternoon Half'},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    _loadLeaveHistory();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Tab Bar
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTab(
                        'Request Leave',
                        0,
                        Icons.add_circle_outline,
                      ),
                    ),
                    Expanded(child: _buildTab('History', 1, Icons.history)),
                  ],
                ),
              ),
            ),

            // Tab Content
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildTabContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
        _animationController.reset();
        _animationController.forward();
        if (index == 1) {
          _loadLeaveHistory();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildRequestLeaveTab();
      case 1:
        return _buildHistoryTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRequestLeaveTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Request Form
          Container(
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
                        color: Colors.indigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.event_available_rounded,
                        color: Colors.indigo,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'New Leave Request',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Leave Type
                _buildFormField(
                  label: 'Leave Type',
                  child: DropdownButtonFormField<String>(
                    value: _selectedLeaveType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: _leaveTypes.map((type) {
                      return DropdownMenuItem(
                        value: type['value'],
                        child: Text(
                          type['label']!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedLeaveType = value!;
                        // Reset dates when leave type changes
                        _startDate = null;
                        _endDate = null;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Half Day Type (only show if HALF_DAY is selected)
                if (_selectedLeaveType == 'HALF_DAY') ...[
                  _buildFormField(
                    label: 'Half Day Type',
                    child: DropdownButtonFormField<String>(
                      value: _selectedHalfDayType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: _halfDayTypes.map((type) {
                        return DropdownMenuItem(
                          value: type['value'],
                          child: Text(
                            type['label']!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedHalfDayType = value!),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Date Selection
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        label: 'Start Date',
                        child: InkWell(
                          onTap: _selectStartDate,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade50,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: Colors.indigo,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _startDate == null
                                        ? 'Select Date'
                                        : _formatDate(_startDate!),
                                    style: TextStyle(
                                      color: _startDate == null
                                          ? Colors.grey.shade600
                                          : Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFormField(
                        label: 'End Date',
                        child: InkWell(
                          onTap: _selectedLeaveType == 'HALF_DAY'
                              ? null
                              : _selectEndDate,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _selectedLeaveType == 'HALF_DAY'
                                    ? Colors.grey.shade200
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: _selectedLeaveType == 'HALF_DAY'
                                  ? Colors.grey.shade100
                                  : Colors.grey.shade50,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: _selectedLeaveType == 'HALF_DAY'
                                      ? Colors.grey.shade400
                                      : Colors.indigo,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedLeaveType == 'HALF_DAY'
                                        ? 'Same as Start Date'
                                        : (_endDate == null
                                              ? 'Select Date'
                                              : _formatDate(_endDate!)),
                                    style: TextStyle(
                                      color: _selectedLeaveType == 'HALF_DAY'
                                          ? Colors.grey.shade500
                                          : (_endDate == null
                                                ? Colors.grey.shade600
                                                : Colors.black87),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Reason
                _buildFormField(
                  label: 'Reason',
                  child: TextField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      hintText: 'Enter reason for leave',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 3,
                  ),
                ),

                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitLeaveRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Submit Request',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_leaveHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Leave History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your leave requests will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _leaveHistory.length,
      itemBuilder: (context, index) {
        final leave = _leaveHistory[index];
        return _buildLeaveCard(leave);
      },
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave) {
    // Format leave type for display
    String leaveTypeDisplay = _formatLeaveType(leave['leaveType'] ?? 'Unknown');

    // Format dates for display
    String startDate = _formatDisplayDate(leave['startDate']);
    String endDate = _formatDisplayDate(leave['endDate']);

    // Calculate duration
    String duration = _calculateDurationForHistory(
      leave['startDate'],
      leave['endDate'],
      leave['leaveType'],
    );

    // Get status with proper formatting
    String status = leave['status'] ?? 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with leave type and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      leaveTypeDisplay,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _buildStatusChip(status),
                ],
              ),
              const SizedBox(height: 12),

              // Date range
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Colors.grey.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$startDate - $endDate',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Duration
              if (duration.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.grey.shade600, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Duration: $duration',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Half day type (if applicable)
              if (leave['halfDayType'] != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.grey.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Half Day: ${_formatHalfDayType(leave['halfDayType'])}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Reason
              Text(
                'Reason: ${leave['reason'] ?? 'No reason provided'}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),

              // Additional info (if available)
              if (leave['createdAt'] != null || leave['updatedAt'] != null) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (leave['createdAt'] != null) ...[
                      Icon(
                        Icons.add_circle_outline,
                        color: Colors.grey.shade500,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Requested: ${_formatDisplayDate(leave['createdAt'])}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (leave['createdAt'] != null &&
                        leave['updatedAt'] != null)
                      const SizedBox(width: 16),
                    if (leave['updatedAt'] != null) ...[
                      Icon(Icons.update, color: Colors.grey.shade500, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Updated: ${_formatDisplayDate(leave['updatedAt'])}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Future<void> _selectStartDate() async {
    // Set date restrictions based on leave type
    DateTime firstDate;
    DateTime lastDate;
    DateTime initialDate = DateTime.now();

    if (_selectedLeaveType == 'SICK_LEAVE') {
      // Sick leave: only today (not past, not future)
      firstDate = DateTime.now(); // Only today
      lastDate = DateTime.now(); // Only today
      initialDate = DateTime.now();
    } else if (_selectedLeaveType == 'HALF_DAY') {
      // Half day: only current day
      firstDate = DateTime.now();
      lastDate = DateTime.now();
      initialDate = DateTime.now();
    } else if (_selectedLeaveType == 'EMERGENCY_LEAVE') {
      // Emergency leave: only current day
      firstDate = DateTime.now();
      lastDate = DateTime.now();
      initialDate = DateTime.now();
    } else {
      // Other leave types: current date onwards
      firstDate = DateTime.now();
      lastDate = DateTime.now().add(const Duration(days: 365));
      initialDate = DateTime.now();
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date != null) {
      setState(() {
        _startDate = date;
        // For half day, set end date same as start date
        if (_selectedLeaveType == 'HALF_DAY') {
          _endDate = date;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    // For half day, end date is automatically set to start date
    if (_selectedLeaveType == 'HALF_DAY') {
      _showSnackBar('Half day leave is only for one day', Colors.orange);
      return;
    }

    // Set date restrictions based on leave type
    DateTime firstDate = _startDate ?? DateTime.now();
    DateTime lastDate;
    DateTime initialDate = _startDate ?? DateTime.now();

    if (_selectedLeaveType == 'SICK_LEAVE') {
      // Sick leave: today to 5 days in the future
      lastDate = DateTime.now().add(
        const Duration(days: 5),
      ); // Up to 5 days from today
    } else if (_selectedLeaveType == 'EMERGENCY_LEAVE') {
      // Emergency leave: only current day
      lastDate = DateTime.now();
    } else {
      // Other leave types: current date onwards
      lastDate = DateTime.now().add(const Duration(days: 365));
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submitLeaveRequest() async {
    // Validate inputs
    if (_startDate == null) {
      _showSnackBar('Please select a start date', Colors.red);
      return;
    }

    // For half day, end date is automatically set to start date
    if (_selectedLeaveType != 'HALF_DAY' && _endDate == null) {
      _showSnackBar('Please select an end date', Colors.red);
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      _showSnackBar('Please provide a reason for your leave', Colors.red);
      return;
    }

    // Additional validation for sick leave (not more than 5 days in future)
    if (_selectedLeaveType == 'SICK_LEAVE' &&
        _startDate!.isAfter(DateTime.now().add(const Duration(days: 5)))) {
      _showSnackBar(
        'Sick leave cannot be applied for more than 5 days in the future',
        Colors.red,
      );
      return;
    }

    // Additional validation for sick leave end date (not more than 5 days from start date)
    if (_selectedLeaveType == 'SICK_LEAVE' &&
        _endDate != null &&
        _endDate!.difference(_startDate!).inDays > 5) {
      _showSnackBar(
        'Sick leave cannot be applied for more than 5 days',
        Colors.red,
      );
      return;
    }

    // Additional validation for emergency leave (only current day)
    if (_selectedLeaveType == 'EMERGENCY_LEAVE' &&
        !_isSameDay(_startDate!, DateTime.now())) {
      _showSnackBar(
        'Emergency leave can only be applied for today',
        Colors.red,
      );
      return;
    }

    // Additional validation for emergency leave end date (only current day)
    if (_selectedLeaveType == 'EMERGENCY_LEAVE' &&
        _endDate != null &&
        !_isSameDay(_endDate!, DateTime.now())) {
      _showSnackBar(
        'Emergency leave can only be applied for today',
        Colors.red,
      );
      return;
    }

    // Show loading indicator
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare request body
      final requestBody = {
        'leaveType': _selectedLeaveType,
        'startDate': _formatDate(_startDate!),
        'endDate': _selectedLeaveType == 'HALF_DAY'
            ? _formatDate(_startDate!)
            : _formatDate(_endDate!),
        'reason': _reasonController.text.trim(),
      };

      // Add halfDayType if it's a half day leave
      if (_selectedLeaveType == 'HALF_DAY') {
        requestBody['halfDayType'] = _selectedHalfDayType;
      }

      // Validate request body before sending
      if (requestBody['startDate'] == null || requestBody['endDate'] == null) {
        print('❌ Invalid request body: missing dates');
        _showSnackBar('Invalid date selection', Colors.red);
        return;
      }

      print('🚀 ========== LEAVE REQUEST DEBUG ==========');
      print('🚀 Leave Type: $_selectedLeaveType');
      print('🚀 Start Date: ${_startDate?.toIso8601String()}');
      print('🚀 End Date: ${_endDate?.toIso8601String()}');
      print('🚀 Half Day Type: $_selectedHalfDayType');
      print('🚀 Reason: ${_reasonController.text.trim()}');
      print('🚀 Request Body: $requestBody');
      print(
        '🚀 API URL: ${ApiConstants.baseUrl}${ApiConstants.leaveRequestsEndpoint}',
      );
      print('🚀 Starting authentication check...');

      // Get auth token
      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ No auth token found');
        _showSnackBar('Authentication error. Please login again', Colors.red);
        return;
      }

      print('📝 Submitting leave request...');
      // Make API call
      final response = await http.post(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.leaveRequestsEndpoint}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('🚀 Response Status Code: ${response.statusCode}');
      print('✅ Leave request response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar('Leave request submitted successfully!', Colors.green);

        // Reset form
        _reasonController.clear();
        setState(() {
          _startDate = null;
          _endDate = null;
          _selectedLeaveType = 'ANNUAL_LEAVE';
          _selectedHalfDayType = 'MORNING_HALF';
        });
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');

        // Try to parse error message from response
        String errorMessage = 'Failed to submit leave request';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic>) {
            errorMessage =
                errorData['message'] ?? errorData['error'] ?? errorMessage;
          }
        } catch (e) {
          print('❌ Could not parse error response: $e');
          errorMessage = 'Server error: ${response.statusCode}';
        }

        _showSnackBar(errorMessage, Colors.red);
      }
    } catch (e) {
      print('❌ Exception: $e');
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _loadLeaveHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      print('🚀 ========== LOAD LEAVE HISTORY DEBUG ==========');

      // Get auth token
      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ No auth token found for leave history');
        _showSnackBar('Authentication error. Please login again', Colors.red);
        return;
      }

      // Get employee ID
      final employeeId = await AuthService.getEmployeeId();
      if (employeeId == null) {
        print('❌ No employee ID found for leave history');
        _showSnackBar('Employee ID not found. Please login again', Colors.red);
        return;
      }

      print('🚀 Employee ID: $employeeId');
      print('🚀 Auth token found: ${token.substring(0, 20)}...');
      print('🚀 Making API call to fetch leave history...');

      // Make API call to get leave requests for this employee
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.leaveRequestsEmployeeEndpoint}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📋 Loading leave history...');
      print('✅ Leave history response: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Parse response
        final responseData = json.decode(response.body);
        List<Map<String, dynamic>> leaveHistory = [];

        // Handle different response structures
        if (responseData is List) {
          leaveHistory = List<Map<String, dynamic>>.from(responseData);
        } else if (responseData is Map<String, dynamic>) {
          // Check for common response wrapper fields
          if (responseData.containsKey('data')) {
            final data = responseData['data'];
            if (data is List) {
              leaveHistory = List<Map<String, dynamic>>.from(data);
            }
          } else if (responseData.containsKey('leaveRequests')) {
            final data = responseData['leaveRequests'];
            if (data is List) {
              leaveHistory = List<Map<String, dynamic>>.from(data);
            }
          } else if (responseData.containsKey('leaves')) {
            final data = responseData['leaves'];
            if (data is List) {
              leaveHistory = List<Map<String, dynamic>>.from(data);
            }
          }
        }

        print('🚀 Parsed leave history: ${leaveHistory.length} records');

        setState(() {
          _leaveHistory = leaveHistory;
        });
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');

        // Try to parse error message from response
        String errorMessage = 'Failed to load leave history';
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map<String, dynamic>) {
            errorMessage =
                errorData['message'] ?? errorData['error'] ?? errorMessage;
          }
        } catch (e) {
          print('❌ Could not parse error response: $e');
          errorMessage = 'Server error: ${response.statusCode}';
        }

        _showSnackBar(errorMessage, Colors.red);
      }
    } catch (e) {
      print('❌ Exception loading leave history: $e');
      _showSnackBar('Error loading leave history: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  // Helper methods for formatting leave data
  String _formatLeaveType(String leaveType) {
    print('🔍 Formatting leave type: "$leaveType"');
    final result = switch (leaveType.toUpperCase()) {
      'ANNUAL_LEAVE' || 'AL' || 'Al' => 'Annual Leave',
      'SICK_LEAVE' || 'Sl' || 'SL' => 'Sick Leave',
      'HALF_DAY' || 'HD' || 'Hd' => 'Half Day',
      'WORK_FROM_HOME' || 'WFH' || 'Wfh' => 'Work From Home',
      'PERSONAL_LEAVE' || 'PL' || 'Pl' => 'Personal Leave',
      'EMERGENCY_LEAVE' || 'EL' || 'El' => 'Emergency Leave',
      _ =>
        leaveType
            .replaceAll('_', ' ')
            .toLowerCase()
            .split(' ')
            .map(
              (word) => word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1)
                  : '',
            )
            .join(' '),
    };
    print('🔍 Formatted result: "$result"');
    return result;
  }

  String _formatHalfDayType(String halfDayType) {
    switch (halfDayType.toUpperCase()) {
      case 'MORNING_HALF':
        return 'Morning Half';
      case 'AFTERNOON_HALF':
        return 'Afternoon Half';
      default:
        return halfDayType
            .replaceAll('_', ' ')
            .toLowerCase()
            .split(' ')
            .map(
              (word) => word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1)
                  : '',
            )
            .join(' ');
    }
  }

  String _formatDisplayDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';

    try {
      DateTime date;
      if (dateValue is String) {
        // Try parsing different date formats
        if (dateValue.contains('T')) {
          // ISO format with time
          date = DateTime.parse(dateValue);
        } else if (dateValue.contains('-')) {
          // Date only format (YYYY-MM-DD)
          date = DateTime.parse(dateValue);
        } else {
          return dateValue; // Return as is if can't parse
        }
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return dateValue.toString();
      }

      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      print('❌ Error formatting date: $dateValue - $e');
      return dateValue.toString();
    }
  }

  // Helper method to check if two dates are on the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Calculate duration for history display (takes leave type into account)
  String _calculateDurationForHistory(
    String? startDate,
    String? endDate,
    String? leaveType,
  ) {
    if (startDate == null || endDate == null) return '';

    try {
      DateTime start = DateTime.parse(startDate);
      DateTime end = DateTime.parse(endDate);

      int difference =
          end.difference(start).inDays +
          1; // +1 to include both start and end days

      // Check if this is a half day leave
      if (leaveType == 'HALF_DAY') {
        return '0.5 days';
      } else if (difference == 1) {
        return '1 day';
      } else {
        return '$difference days';
      }
    } catch (e) {
      print(
        '❌ Error calculating duration for history: $startDate - $endDate - $e',
      );
      return '';
    }
  }
}
