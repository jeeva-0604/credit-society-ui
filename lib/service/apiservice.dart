import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static final ApiService _singleton = ApiService._internal();

  static String getBaseUrl() {
    if (kIsWeb) {
      return "http://127.0.0.1:9000/credit_society/api/v1/";
    } else if (Platform.isAndroid) {
      return "http://192.168.29.88:8080/credit_society/api/v1/";////"http://10.0.2.2:8080/credit_society/api/v1/";//"
    } else if (Platform.isWindows) {
      return "http://127.0.0.1:9000/credit_society/api/v1/";
    } else {
      return "http://example.com";
    }
  }
  static String getOnlyUrl() {
    if (kIsWeb) {
      return "http://127.0.0.1:9000/";
    } else if (Platform.isAndroid) {
      return "http://127.0.0.1:9000/";
    } else if (Platform.isWindows) {
      return "http://127.0.0.1:9000/";
    } else {
      return "http://127.0.0.1:9000/";
    }
  }

  // static String getOnlyUrl() {
  //   if (kIsWeb) {
  //     return "https://cloud-hospital.com/";
  //   } else if (Platform.isAndroid) {
  //     return "https://cloud-hospital.com/";
  //   } else if (Platform.isWindows) {
  //     return "https://cloud-hospital.com/";
  //   } else {
  //     return "https://cloud-hospital.com/";
  //   }
  // }
  //
  // static String getBaseUrl() {
  //   if (kIsWeb) {
  //     return "https://cloud-hospital.com/school_sas_uat";
  //   } else if (Platform.isAndroid) {
  //     return "https://cloud-hospital.com/school_sas_uat";
  //   } else if (Platform.isWindows) {
  //     return "https://cloud-hospital.com/school_sas_uat";
  //   } else {
  //     return "https://cloud-hospital.com/school_sas_uat";
  //   }
  // }

  // static String getBaseUrl() {
  //   if (kIsWeb) {
  //     return "https://cloud-hospital.com/school_sas_c1";//"http://127.0.0.1:9000"; //
  //   } else if (Platform.isAndroid) {
  //     return "https://cloud-hospital.com/school_sas_c1";//"http://10.0.2.2:8080"; //
  //   } else if (Platform.isWindows) {
  //     return "https://cloud-hospital.com/school_sas_c1"; //
  //   } else {
  //     return "https://cloud-hospital.com/school_sas_c1"; //
  //   }
  // }

  // static String getBaseUrl() {
  //   if (kIsWeb) {
  //     return "https://oliomarket.in/school";
  //   } else if (Platform.isAndroid) {
  //     return "https://oliomarket.in/school";
  //   } else if (Platform.isWindows) {
  //     return "https://oliomarket.in/school";
  //   } else {
  //     return "https://oliomarket.in/school";
  //   }
  // }

  // static String getBaseUrl() {
  //   if (kIsWeb) {
  //     return "http://18.60.37.198/school_sas_c1";
  //   } else if (Platform.isAndroid) {
  //     return "http://18.60.37.198/school_sas_c1";
  //   } else if (Platform.isWindows) {
  //     return "http://18.60.37.198/school_sas_c1";
  //   } else {
  //     return "http://18.60.37.198/school_sas_c1";
  //   }
  // }

  static String getApkUrl() {
    const apkUrl = '/download-apk/olio.apk';
    return getBaseUrl() + apkUrl;
  }

  static String getApiUrl(String method) {
    String baseUrl = getBaseUrl();
    return "$baseUrl/$method";
  }

  static String getApiUrlForImage(dynamic method) {
    if (method == null || (method is String && method.trim().isEmpty)) {
      return '';
    }

    final methodStr = method.toString().trim();
    if (methodStr.startsWith('http://') || methodStr.startsWith('https://')) {
      return methodStr;
    }

    final baseUrl = getBaseUrl();
    return '$baseUrl/$methodStr';
  }


  factory ApiService() {
    return _singleton;
  }

  ApiService._internal();

  String? _accessToken;

  void setAccessToken(String token) {
    _accessToken = token;
  }

  Future<http.Response> get(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    return response;
  }

  Future<http.Response> post(String url, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: body,
    );
    return response;
  }

  Future<http.Response> postdynamic(
      String url, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: body,
    );
    return response;
  }

  Future<http.Response> post1(String url, String body) async {
    final response = await http.post(
      Uri.parse(url),
      headers: _headers1,
      body: body,
    );
    return response;
  }

  Future<Map<String, String>> getAuthHeaders() async {
    return _headers1;
  }

  Future<http.Response> postWithOutBody(String url,) async {
    final response = await http.post(
      Uri.parse(url),
      headers: _headers1,
    );
    return response;
  }

  Future<http.Response> put(String url, String body) async {
    final response = await http.put(
      Uri.parse(url),
      headers: _headers1,
      body: body,
    );
    return response;
  }

  Future<http.Response> put1(String url) async {
    final response = await http.put(
      Uri.parse(url),
      headers: _headers1,
    );
    return response;
  }

  Future<http.Response> patch(String url, String jsonBody) async {
    return await http.patch(
      Uri.parse(url),
      headers: _headers1,
      body: jsonBody,
    );
  }

  Future<http.Response> delete(String url) async {
    final response = await http.delete(
      Uri.parse(url),
      headers: _headers1,
    );
    return response;
  }

  String? _impersonateId;
  bool _isTeacherImpersonation = false;

  void setImpersonateId(String? id, {required bool isTeacher}) {
    _impersonateId = id;
    _isTeacherImpersonation = isTeacher;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/x-www-form-urlencoded',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    if (_isTeacherImpersonation && _impersonateId != null)
      'x-impersonate-id': _impersonateId!,
  };

  Map<String, String> get _headers1 => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    if (_isTeacherImpersonation && _impersonateId != null)
      'x-impersonate-id': _impersonateId!,
  };

  String extractUserData(String token) {
    try {
      final jwt = JWT.decode(token);
      final Map<String, dynamic> payload = jwt.payload as Map<String, dynamic>;
      final username = payload['sub'];
      final userId = payload['id'];
      final roleId = payload['roleid'];
      return "Username: $username, User ID: $userId, Role ID: $roleId";
    } catch (e) {
      return "Error decoding token";
    }
  }
}
