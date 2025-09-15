import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

class ExpensesService {
  static Future<String?> uploadReceiptImage({
    required String employeeId,
    required File imageFile,
  }) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/files/expense-receipts/'),
      );
      request.headers['Authorization'] = '${ApiConstants.bearerPrefix}$token';
      request.files.add(
        await http.MultipartFile.fromPath(
          'receipt',
          imageFile.path,
          filename:
              'expense_${employeeId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      request.fields['employeeId'] = employeeId;

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = json.decode(response.body);
          final url = data['url'] ?? data['imageUrl'] ?? data['path'];
          if (url is String && url.isNotEmpty) return url;
        } catch (_) {}

        return '${ApiConstants.baseUrl}/files/expense-receipts/${request.files.first.filename}';
      }
      throw Exception(
        'Failed to upload receipt: ${response.statusCode} ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> submitExpense({
    required String itemName,
    required DateTime purchaseDate,
    required double cost,
    required String? imageUrl,
    required String employeeId,
  }) async {
    final url = '${ApiConstants.baseUrl}${ApiConstants.expensesEndpoint}';
    final headers = await _authJsonHeaders();
    final body = json.encode({
      'item_name': itemName,
      'purchase_date': purchaseDate.toIso8601String().split('T')[0],
      'cost': cost,
      'image_url': imageUrl,
      'employee_id': employeeId,
    });

    final response = await ApiService.httpClient
        .post(Uri.parse(url), headers: headers, body: body)
        .timeout(const Duration(seconds: 30));

    return _handleJson(response);
  }

  static Future<List<Map<String, dynamic>>> listMyExpenses({
    required String employeeId,
  }) async {
    final url =
        '${ApiConstants.baseUrl}${ApiConstants.expensesEmployeeEndpoint}/$employeeId';
    final headers = await _authJsonHeaders();
    final response = await ApiService.httpClient
        .get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 30));
    final data = _handleJson(response);
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  static Future<Map<String, String>> _authJsonHeaders() async {
    final token = await StorageService.getToken();
    final headers = {'Content-Type': ApiConstants.contentTypeJson};
    if (token != null) {
      headers[ApiConstants.authorizationHeader] =
          '${ApiConstants.bearerPrefix}$token';
    }
    return headers;
  }

  static dynamic _handleJson(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return json.decode(response.body);
      } catch (_) {
        return {'success': true};
      }
    }
    throw Exception('API Error ${response.statusCode}: ${response.body}');
  }
}
