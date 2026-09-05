import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// API Service for connecting to the backend.
class ApiService {
  // Note: If you are testing on a physical device, you must use your computer's local IP (e.g. 192.168.X.X)
  static String? _customBaseUrl;
  static void setBaseUrl(String url) => _customBaseUrl = url;

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) return _customBaseUrl!;
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    try {
      if (Platform.isAndroid) return 'https://anointer-stupor-parchment.ngrok-free.dev/v1'; // Change this to your computer's actual Wi-Fi IPv4 address!
    } catch (e) {
      // Platform throws on Web
    }
    return 'http://localhost:8000/v1';
  }
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
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final decoded = jsonDecode(response.body);
        final error = decoded['detail'] ?? 'Login failed';
        throw Exception(error);
      }
    } on SocketException catch (e) {
      throw Exception('Cannot reach backend at $baseUrl ($e). Check Wi-Fi connection.');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timed out connecting to $baseUrl');
      }
      rethrow;
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

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final decoded = jsonDecode(response.body);
        final error = decoded['detail'] ?? 'Registration failed';
        throw Exception(error);
      }
    } on SocketException catch (e) {
      throw Exception('Cannot reach backend at $baseUrl ($e)');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timed out connecting to $baseUrl');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> refreshTokens(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Session expired');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch profile');
      }
    } on SocketException catch (e) {
      throw Exception('Cannot reach backend at $baseUrl ($e)');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Connection timed out connecting to $baseUrl');
      }
      rethrow;
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

  static Future<Map<String, dynamic>> getAnalyticsOverview({bool mine = false}) async {
    final uri = Uri.parse('$baseUrl/analytics/overview').replace(
      queryParameters: mine ? {'mine': 'true'} : null,
    );
    final response = await http.get(
      uri,
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch analytics overview');
    }
  }

  static Future<List<dynamic>> getTopViolations({bool mine = false}) async {
    final uri = Uri.parse('$baseUrl/analytics/top-violations').replace(
      queryParameters: mine ? {'mine': 'true'} : null,
    );
    final response = await http.get(
      uri,
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch top violations');
    }
  }

  static Future<Map<String, dynamic>> getComplianceTrend({int days = 30, bool mine = false}) async {
    final params = {'days': days.toString()};
    if (mine) params['mine'] = 'true';
    final uri = Uri.parse('$baseUrl/analytics/compliance-trend').replace(
      queryParameters: params,
    );
    final response = await http.get(
      uri,
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch compliance trend');
    }
  }

  static Future<Map<String, dynamic>> getEcomOverview() async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/ecom-overview'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch ecom overview');
    }
  }

  static Future<Map<String, dynamic>> checkListingUrl(String listingUrl) async {
    final response = await http.post(
      Uri.parse('$baseUrl/batch/listings/check'),
      headers: _headers,
      body: jsonEncode({'listing_url': listingUrl}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body)['detail'] ?? 'Failed to check listing URL';
      throw Exception(error);
    }
  }

  static Future<Map<String, dynamic>> submitCitizenReport({
    required File image,
    required String problemType,
    String? description,
    double? latitude,
    double? longitude,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/citizens/report'));
    request.files.add(await http.MultipartFile.fromPath('image', image.path));
    request.fields['problem_type'] = problemType;
    if (description != null && description.isNotEmpty) {
      request.fields['description'] = description;
    }
    if (latitude != null) {
      request.fields['latitude'] = latitude.toString();
    }
    if (longitude != null) {
      request.fields['longitude'] = longitude.toString();
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body)['detail'] ?? 'Failed to submit report';
      throw Exception(err);
    }
  }

  static Future<List<dynamic>> getByCategory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/by-category'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch category data');
    }
  }

  static Future<List<dynamic>> getBatchListings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/batch/listings'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch batch listings');
    }
  }

  static Future<List<dynamic>> getCitizenReports() async {
    final response = await http.get(
      Uri.parse('$baseUrl/citizens/reports'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch citizen reports');
    }
  }

  // ─── SCAN ENDPOINTS ───────────────────────────────────────────────────────

  /// Get all scans for the current user.
  static Future<List<dynamic>> getScans({int page = 1, int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/check/scans?page=$page&limit=$limit'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch scan history');
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
