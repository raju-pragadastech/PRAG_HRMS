import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiTestService {
  static Future<void> testApiConnection() async {
    try {
      print('🧪 Testing API connection...');

      // Test 1: Basic connectivity
      print('1️⃣ Testing basic connectivity...');
      final response = await http
          .get(Uri.parse('https://api-hrms.pragva.in/api'))
          .timeout(const Duration(seconds: 10));

      print('✅ Basic connectivity: ${response.statusCode}');
      print('📥 Response: ${response.body}');

      // Test 2: Login endpoint
      print('2️⃣ Testing login endpoint...');
      final loginResponse = await http
          .post(
            Uri.parse('https://api-hrms.pragva.in/api/employee/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'employeeIdOrEmail': 'PRAG012',
              'password': 'Raju@5380',
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('✅ Login endpoint: ${loginResponse.statusCode}');
      print('📥 Response: ${loginResponse.body}');
    } catch (e) {
      print('❌ API Test failed: $e');
    }
  }
}
