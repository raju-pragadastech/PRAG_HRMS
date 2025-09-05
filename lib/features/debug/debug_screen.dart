import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  List<String> _logs = [];
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _startLogCapture();
  }

  void _startLogCapture() {
    setState(() {
      _isCapturing = true;
    });

    // Capture logs every second
    _captureLogs();
  }

  void _captureLogs() {
    if (!_isCapturing) return;

    // This is a simplified approach - in a real app you'd use a proper logging service
    setState(() {
      _logs.add('${DateTime.now().toString()}: Log capture active');
    });

    Future.delayed(const Duration(seconds: 1), _captureLogs);
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  void _copyLogs() {
    final logText = _logs.join('\n');
    Clipboard.setData(ClipboardData(text: logText));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logs copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Logs'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLogs,
            tooltip: 'Copy Logs',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearLogs,
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Icon(
                  _isCapturing
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: _isCapturing ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _isCapturing ? 'Capturing logs...' : 'Log capture stopped',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isCapturing = !_isCapturing;
                    });
                    if (_isCapturing) {
                      _captureLogs();
                    }
                  },
                  child: Text(_isCapturing ? 'Stop' : 'Start'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'No logs captured yet.\nTry logging in to see debug information.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: SelectableText(
                          log,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add a test log entry
          setState(() {
            _logs.add('${DateTime.now().toString()}: Test log entry added');
          });
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Test Log',
      ),
    );
  }
}
