import 'package:flutter/material.dart';

class EnhancedLeaveScreen extends StatefulWidget {
  final bool isHR;

  const EnhancedLeaveScreen({super.key, this.isHR = false});

  @override
  State<EnhancedLeaveScreen> createState() => _EnhancedLeaveScreenState();
}

class _EnhancedLeaveScreenState extends State<EnhancedLeaveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _currentEmployeeId = 'EMP001'; // Simulated current user

  // Sample data
  final List<Map<String, dynamic>> _leaveRequests = [
    {
      'id': '1',
      'employeeId': 'EMP001',
      'employeeName': 'John Doe',
      'leaveType': 'Annual Leave',
      'startDate': '2024-12-25',
      'endDate': '2024-12-27',
      'days': 3,
      'reason': 'Family vacation',
      'status': 'pending',
      'appliedDate': '2024-12-20',
      'approvedBy': null,
      'approvedOn': null,
    },
    {
      'id': '2',
      'employeeId': 'EMP002',
      'employeeName': 'Jane Smith',
      'leaveType': 'Sick Leave',
      'startDate': '2024-12-22',
      'endDate': '2024-12-22',
      'days': 1,
      'reason': 'Medical appointment',
      'status': 'approved',
      'appliedDate': '2024-12-21',
      'approvedBy': 'HR Manager',
      'approvedOn': '2024-12-21',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.isHR ? 3 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isHR ? 'Leave Management (HR)' : 'My Leave Requests',
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: widget.isHR
              ? const [
                  Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
                  Tab(text: 'Approved', icon: Icon(Icons.check_circle)),
                  Tab(text: 'Rejected', icon: Icon(Icons.cancel)),
                ]
              : const [
                  Tab(text: 'My Requests', icon: Icon(Icons.person)),
                  Tab(text: 'Apply Leave', icon: Icon(Icons.add)),
                ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.withOpacity(0.1), Colors.white],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: widget.isHR
              ? [
                  _buildPendingRequestsTab(),
                  _buildApprovedRequestsTab(),
                  _buildRejectedRequestsTab(),
                ]
              : [_buildMyRequestsTab(), _buildApplyLeaveTab()],
        ),
      ),
    );
  }

  Widget _buildPendingRequestsTab() {
    final pendingRequests = _leaveRequests
        .where((request) => request['status'] == 'pending')
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingRequests.length,
      itemBuilder: (context, index) {
        return _buildLeaveRequestCard(
          pendingRequests[index],
          showActions: true,
        );
      },
    );
  }

  Widget _buildApprovedRequestsTab() {
    final approvedRequests = _leaveRequests
        .where((request) => request['status'] == 'approved')
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: approvedRequests.length,
      itemBuilder: (context, index) {
        return _buildLeaveRequestCard(
          approvedRequests[index],
          showActions: false,
        );
      },
    );
  }

  Widget _buildRejectedRequestsTab() {
    final rejectedRequests = _leaveRequests
        .where((request) => request['status'] == 'rejected')
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rejectedRequests.length,
      itemBuilder: (context, index) {
        return _buildLeaveRequestCard(
          rejectedRequests[index],
          showActions: false,
        );
      },
    );
  }

  Widget _buildMyRequestsTab() {
    final myRequests = _leaveRequests
        .where((request) => request['employeeId'] == _currentEmployeeId)
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: myRequests.length,
      itemBuilder: (context, index) {
        return _buildLeaveRequestCard(myRequests[index], showActions: false);
      },
    );
  }

  Widget _buildApplyLeaveTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apply for Leave',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildLeaveTypeDropdown(),
              const SizedBox(height: 16),
              _buildDateRangePicker(),
              const SizedBox(height: 16),
              _buildReasonTextField(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitLeaveRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Submit Leave Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveRequestCard(
    Map<String, dynamic> request, {
    required bool showActions,
  }) {
    Color statusColor;
    String statusText;

    switch (request['status']) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.indigo,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['leaveType'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${request['startDate']} - ${request['endDate']} (${request['days']} days)',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Reason: ${request['reason']}',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'Applied on: ${request['appliedDate']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (request['status'] != 'pending' &&
                request['approvedBy'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    request['status'] == 'approved'
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: request['status'] == 'approved'
                        ? Colors.green
                        : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${request['status'] == 'approved' ? 'Approved' : 'Rejected'} by ${request['approvedBy']} on ${request['approvedOn']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (showActions && request['status'] == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showApproveDialog(request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showRejectDialog(request),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveTypeDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Leave Type',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.category),
      ),
      items: const [
        DropdownMenuItem(value: 'Annual Leave', child: Text('Annual Leave')),
        DropdownMenuItem(value: 'Sick Leave', child: Text('Sick Leave')),
        DropdownMenuItem(
          value: 'Personal Leave',
          child: Text('Personal Leave'),
        ),
        DropdownMenuItem(
          value: 'Emergency Leave',
          child: Text('Emergency Leave'),
        ),
      ],
      onChanged: (value) {
        // Handle leave type selection
      },
    );
  }

  Widget _buildDateRangePicker() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: 'Start Date',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: () {
              // Handle date picker
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: 'End Date',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: () {
              // Handle date picker
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReasonTextField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Reason',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.note),
      ),
      maxLines: 3,
    );
  }

  void _submitLeaveRequest() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Leave request submitted successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showApproveDialog(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Leave Request'),
        content: Text(
          'Are you sure you want to approve ${request['employeeName']}\'s leave request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Leave request approved!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Leave Request'),
        content: Text(
          'Are you sure you want to reject ${request['employeeName']}\'s leave request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Leave request rejected!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
