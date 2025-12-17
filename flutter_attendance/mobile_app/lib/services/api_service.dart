import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/attendance_record.dart';
import '../models/project.dart';
import '../models/employee.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  ApiService._internal();

  static final ApiService _singleton = ApiService._internal();

  factory ApiService() => _singleton;

  static const String _tokenKey = 'auth_token';
  static const String _userEmailKey = 'user_email';
  static const String _adminTokenKey = 'admin_auth_token';
  static const String _adminEmailKey = 'admin_email';
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000/api',
  );

  final http.Client _client = http.Client();
  String? _token;
  String? _userEmail;
  String? _adminToken;
  String? _adminEmail;

  String? get token => _token;

  String? get userEmail => _userEmail;

  String? get adminToken => _adminToken;

  String? get adminEmail => _adminEmail;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString(_tokenKey);
    final storedEmail = prefs.getString(_userEmailKey);
    final storedAdminToken = prefs.getString(_adminTokenKey);
    final storedAdminEmail = prefs.getString(_adminEmailKey);

    _token = storedToken?.trim().isEmpty ?? true
        ? null
        : storedToken!.replaceAll(RegExp(r'\s'), '');
    _userEmail = storedEmail;
    _adminToken = storedAdminToken?.trim().isEmpty ?? true
        ? null
        : storedAdminToken!.replaceAll(RegExp(r'\s'), '');
    _adminEmail = storedAdminEmail;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userEmailKey);
    _token = null;
    _userEmail = null;
  }

  Future<void> clearAdminSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adminTokenKey);
    await prefs.remove(_adminEmailKey);
    _adminToken = null;
    _adminEmail = null;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('$_baseUrl/auth/login');
    final response = await _client.post(
      uri,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.acceptHeader: 'application/json',
      },
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );

    final data = _decodeResponse(response);
    await _persistAuthSession(data);
    return data;
  }

  Future<Map<String, dynamic>> adminLogin(String email, String password) async {
    final uri = Uri.parse('$_baseUrl/admin/auth/login');
    final response = await _client.post(
      uri,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.acceptHeader: 'application/json',
      },
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );

    final data = _decodeResponse(response);
    await _persistAdminSession(data);
    return data;
  }

  Future<Map<String, dynamic>> signup(String email, String password) async {
    final uri = Uri.parse('$_baseUrl/auth/signup');
    final response = await _client.post(
      uri,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.acceptHeader: 'application/json',
      },
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );

    final data = _decodeResponse(response);
    await _persistAuthSession(data);
    return data;
  }

  Future<Map<String, dynamic>> checkIn({
    required File imageFile,
    required double latitude,
    required double longitude,
  }) async {
    final token = _requireToken();
    final uri = Uri.parse('$_baseUrl/attendance/check-in');

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_authHeaders(token))
      ..fields['latitude'] = latitude.toString()
      ..fields['longitude'] = longitude.toString()
      ..files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: imageFile.uri.pathSegments.last,
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> checkOut({
    double? latitude,
    double? longitude,
  }) async {
    final token = _requireToken();
    final uri = Uri.parse('$_baseUrl/attendance/check-out');
    final body = <String, dynamic>{};
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    
    final response = await _client.post(
      uri,
      headers: {
        ..._authHeaders(token),
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: jsonEncode(body),
    );

    return _decodeResponse(response);
  }

  Future<List<dynamic>> fetchMyAttendance() async {
    final token = _requireToken();
    final uri = Uri.parse('$_baseUrl/attendance/me');
    final response = await _client.get(uri, headers: _authHeaders(token));

    final data = _decodeResponse(response);
    final records = data['records'];
    if (records is List) {
      return records;
    }
    return const [];
  }

  Future<List<AttendanceRecord>> fetchAdminAttendance({
    String? userEmail,
    DateTime? date,
    int? month,
    int? year,
    String sortBy = 'date',
    bool sortDescending = true,
  }) async {
    final token = _requireAdminToken();

    final queryParameters = <String, String>{};
    if (userEmail != null && userEmail.trim().isNotEmpty) {
      queryParameters['user'] = userEmail.trim();
    }
    if (date != null) {
      queryParameters['date'] = date.toIso8601String();
    }
    if (month != null && month >= 1 && month <= 12) {
      queryParameters['month'] = month.toString();
    }
    if (year != null && year > 0) {
      queryParameters['year'] = year.toString();
    }
    if (sortBy.isNotEmpty) {
      queryParameters['sortBy'] = sortBy;
    }
    queryParameters['sortOrder'] = sortDescending ? 'desc' : 'asc';

    final uri = Uri.parse('$_baseUrl/attendance/admin/all').replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    final response = await _client.get(uri, headers: _authHeaders(token));
    final data = _decodeResponse(response);
    final records = data['records'] ?? data['data'];

    if (records is List) {
      return records
          .whereType<Map<String, dynamic>>()
          .map(AttendanceRecord.fromJson)
          .toList();
    }
    return const [];
  }

  // Projects CRUD
  Future<List<Project>> fetchProjects() async {
    final token = _requireAdminToken();
    final uri = Uri.parse('$_baseUrl/admin/projects');
    final response = await _client.get(uri, headers: _authHeaders(token));
    final data = _decodeResponse(response);
    final projects = data['projects'] ?? data['data'] ?? [];

    if (projects is List) {
      return projects
          .whereType<Map<String, dynamic>>()
          .map(Project.fromJson)
          .toList();
    }
    return const [];
  }

  Future<Project> createProject({
    required String name,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    double? budget,
  }) async {
    final token = _requireAdminToken();
    final uri = Uri.parse('$_baseUrl/admin/projects');
    final body = <String, dynamic>{
      'name': name,
      if (location != null && location.isNotEmpty) 'location': location,
      if (startDate != null) 'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      if (description != null && description.isNotEmpty) 'description': description,
      if (budget != null) 'budget': budget,
    };
    final response = await _client.post(
      uri,
      headers: {
        ..._authHeaders(token),
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: jsonEncode(body),
    );

    final data = _decodeResponse(response);
    final projectData = data['project'] ?? data;
    return Project.fromJson(projectData as Map<String, dynamic>);
  }

  Future<Project> updateProject({
    required String id,
    String? name,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    double? budget,
  }) async {
    final token = _requireAdminToken();
    final uri = Uri.parse('$_baseUrl/admin/projects/$id');
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (location != null) body['location'] = location;
    if (startDate != null) body['start_date'] = startDate.toIso8601String();
    if (endDate != null) body['end_date'] = endDate.toIso8601String();
    if (description != null) body['description'] = description;
    if (budget != null) body['budget'] = budget;

    final response = await _client.put(
      uri,
      headers: {
        ..._authHeaders(token),
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: jsonEncode(body),
    );

    final data = _decodeResponse(response);
    final projectData = data['project'] ?? data;
    return Project.fromJson(projectData as Map<String, dynamic>);
  }

  Future<void> deleteProject(String id) async {
    final token = _requireAdminToken();
    final uri = Uri.parse('$_baseUrl/admin/projects/$id');
    final response = await _client.delete(uri, headers: _authHeaders(token));
    _decodeResponse(response);
  }

  // Employees CRUD
  Future<List<Employee>> fetchEmployees() async {
    final token = _requireAdminToken();
    final uri = Uri.parse('$_baseUrl/admin/employees');
    final response = await _client.get(uri, headers: _authHeaders(token));
    final data = _decodeResponse(response);
    final employees = data['employees'] ?? data['data'] ?? [];

    if (employees is List) {
      return employees
          .whereType<Map<String, dynamic>>()
          .map(Employee.fromJson)
          .toList();
    }
    return const [];
  }

  Future<Employee> createEmployee({
    required String name,
    String? email,
    String? phone,
    String? role,
    String? projectId,
  }) async {
    final token = _requireAdminToken();
    final uri = Uri.parse('$_baseUrl/admin/employees');
    final response = await _client.post(
      uri,
      headers: {
        ..._authHeaders(token),
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'project_id': projectId,
      }),
    );

    final data = _decodeResponse(response);
    final employeeData = data['employee'] ?? data;
    return Employee.fromJson(employeeData as Map<String, dynamic>);
  }

  Future<Employee> updateEmployee({
    required String id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? projectId,
  }) async {
    final token = _requireAdminToken();
    final uri = Uri.parse('$_baseUrl/admin/employees/$id');
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (role != null) body['role'] = role;
    if (projectId != null) body['project_id'] = projectId;

    final response = await _client.put(
      uri,
      headers: {
        ..._authHeaders(token),
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: jsonEncode(body),
    );

    final data = _decodeResponse(response);
    final employeeData = data['employee'] ?? data;
    return Employee.fromJson(employeeData as Map<String, dynamic>);
  }

  Future<void> deleteEmployee(String id) async {
    final token = _requireAdminToken();
    final uri = Uri.parse('$_baseUrl/admin/employees/$id');
    final response = await _client.delete(uri, headers: _authHeaders(token));
    _decodeResponse(response);
  }

  Map<String, String> _authHeaders(String token) => {
    HttpHeaders.authorizationHeader: 'Bearer $token',
    HttpHeaders.acceptHeader: 'application/json',
  };

  Future<void> _persistAuthSession(Map<String, dynamic> data) async {
    final rawToken = data['token']?.toString() ?? '';
    if (rawToken.isEmpty) {
      throw ApiException('Missing token in server response');
    }

    final cleanToken = rawToken.replaceAll(RegExp(r'\s'), '');
    final user = data['user'] as Map<String, dynamic>? ?? {};
    final emailValue = (user['email'] as String?)?.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, cleanToken);

    if (emailValue != null && emailValue.isNotEmpty) {
      await prefs.setString(_userEmailKey, emailValue);
    }

    _token = cleanToken;
    _userEmail = emailValue;
  }

  Future<void> _persistAdminSession(Map<String, dynamic> data) async {
    final rawToken = data['token']?.toString() ?? '';
    if (rawToken.isEmpty) {
      throw ApiException('Missing token in server response');
    }

    final cleanToken = rawToken.replaceAll(RegExp(r'\s'), '');
    final user = data['user'] as Map<String, dynamic>? ?? {};
    final emailValue =
        (user['email'] as String?)?.trim() ?? data['email']?.toString();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminTokenKey, cleanToken);
    if (emailValue != null && emailValue.isNotEmpty) {
      await prefs.setString(_adminEmailKey, emailValue);
    }

    _adminToken = cleanToken;
    _adminEmail = emailValue;
  }

  String _requireToken() {
    final currentToken = _token;
    if (currentToken == null || currentToken.trim().isEmpty) {
      throw ApiException(
        'Authentication token is missing. Please log in again.',
      );
    }
    return currentToken;
  }

  String _requireAdminToken() {
    final currentToken = _adminToken;
    if (currentToken == null || currentToken.trim().isEmpty) {
      throw ApiException(
        'Admin authentication token is missing. Please log in again.',
      );
    }
    return currentToken;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body.isEmpty ? '{}' : response.body;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException(
        'Invalid response from server',
        statusCode: statusCode,
      );
    }

    if (statusCode < 200 || statusCode >= 300) {
      final message = data['message']?.toString() ?? 'Request failed';
      throw ApiException(message, statusCode: statusCode);
    }

    return data;
  }
}
