import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

/// API Service for connecting to the backend.
class ApiService {
  // Using your computer's local IP since you're testing on a physical device
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.7:8000/v1',
  );
  static String _authToken = '';

  static void setToken(String token) {
    _authToken = token;
  }

  static Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['detail'] ?? 'Login failed';
      throw Exception(error);
    }
  }

  static Future<Map<String, dynamic>> register(
    String username,
    String password,
    String fullName,
    String email,
    String? inviteCode,
  ) async {
    final body = {
      'username': username,
      'password': password,
      'full_name': fullName,
      'email': email,
    };
    if (inviteCode != null && inviteCode.trim().isNotEmpty) {
      body['invite_code'] = inviteCode.trim();
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['detail'] ?? 'Registration failed';
      throw Exception(error);
    }
  }

  static Future<Map<String, dynamic>> refreshTokens(String refreshToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Session expired');
    }
  }

  static Future<Map<String, dynamic>> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch profile');
    }
  }

  static Future<List<dynamic>> getInviteCodes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/invite-codes'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch invite codes');
    }
  }

  static Future<Map<String, dynamic>> createInviteCode(String role, String? district) async {
    final body = {'role': role};
    if (district != null && district.trim().isNotEmpty) {
      body['district'] = district.trim();
    }
    
    final response = await http.post(
      Uri.parse('$baseUrl/auth/invite-codes'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['detail'] ?? 'Failed to create code';
      throw Exception(error);
    }
  }

  static Future<void> revokeInviteCode(String code) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/auth/invite-codes/$code'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['detail'] ?? 'Failed to revoke code';
      throw Exception(error);
    }
  }

  static Future<List<dynamic>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/users'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  static Future<void> patchUserStatus(String userId, bool isActive) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/auth/users/$userId/status'),
      headers: _headers,
      body: jsonEncode({'is_active': isActive}),
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['detail'] ?? 'Failed to update user status';
      throw Exception(error);
    }
  }

  static Future<void> patchUserRole(String userId, String role, String? district) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/auth/users/$userId/role'),
      headers: _headers,
      body: jsonEncode({
        'role': role,
        'district': (district != null && district.trim().isNotEmpty) ? district.trim() : null
      }),
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['detail'] ?? 'Failed to update user role';
      throw Exception(error);
    }
  }

  static Future<List<dynamic>> getAuditLog({String? action, String? dateSince}) async {
    final queryParams = <String, String>{};
    if (action != null && action.isNotEmpty) queryParams['action'] = action;
    if (dateSince != null && dateSince.isNotEmpty) queryParams['since'] = dateSince;
    
    final uri = Uri.parse('$baseUrl/auth/audit-log').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
    
    final response = await http.get(
      uri,
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch audit log');
    }
  }

  static Future<Map<String, dynamic>> getRulesVersion() async {
    final response = await http.get(
      Uri.parse('$baseUrl/rules/version'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch rules version');
    }
  }

  static Future<Map<String, dynamic>> getAdminOverview() async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/admin-overview'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch admin overview');
    }
  }

  // ─── SCAN ENDPOINTS ───────────────────────────────────────────────────────

  /// Upload a label image. Returns {'task_id': 'xxxx', 'scan_id': 'yyyy'}
  static Future<Map<String, dynamic>> uploadScan(File imageFile) async {
    final uri = Uri.parse('$baseUrl/scans/upload');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll({'Authorization': 'Bearer $_authToken'});
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      imageFile.path,
      contentType: MediaType('image', 'jpeg'),
    ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final detail = jsonDecode(response.body)['detail'] ?? 'Upload failed';
      throw Exception(detail);
    }
  }

  /// Poll processing status. Returns {'status': 'processing'|'done'|'error', 'step': 0-5}
  static Future<Map<String, dynamic>> getScanStatus(String taskId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/scans/$taskId/status'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Status check failed');
    }
  }

  /// Get full result of a completed scan.
  static Future<Map<String, dynamic>> getScanResult(String taskId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/scans/$taskId/result'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch result');
    }
  }

  /// Get all scans for the current user.
  static Future<List<dynamic>> getScans({int page = 1, int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/scans?page=$page&limit=$limit'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch scan history');
    }
  }

  /// Download PDF report for a scan.
  static Future<Uint8List> getScanReport(String scanId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/$scanId/pdf'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to download report');
    }
  }

  static Future<Map<String, dynamic>> submitScan(File imageFile) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/check/label'));
    request.headers.addAll(_headers);
    request.headers.remove('Content-Type'); // Let http client set boundary
    
    request.files.add(await http.MultipartFile.fromPath('images', imageFile.path));
    request.fields['rule_version'] = '2024.01';

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to submit scan: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> pollScanStatus(String scanId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/check/label/status/$scanId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to poll status');
    }
  }

  static Future<Map<String, dynamic>> getLabelScanResult(String scanId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/check/label/result/$scanId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch scan result');
    }
  }

  static Future<File> downloadPdfReport(String scanId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/report/$scanId/pdf'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/labellens_report_$scanId.pdf');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } else {
      throw Exception('Failed to download PDF report');
    }
  }
}
