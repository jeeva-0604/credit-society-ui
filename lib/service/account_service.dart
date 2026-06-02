import 'dart:convert';
import 'package:http/http.dart' as http;

import 'apiservice.dart';

class AccountService {
  final String baseUrl = ApiService.getBaseUrl().replaceAll(RegExp(r'/+$'), '');

  Future<Map<String, dynamic>> createAccount(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/accounts/account");

    try {
      final response = await http.post(
        url,
        headers: await ApiService().getAuthHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to create account: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  Future<Map<String, dynamic>> updateAccount(int id, Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/accounts/account/$id");

    try {
      final response = await http.put(
        url,
        headers: await ApiService().getAuthHeaders(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to create account: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  Future<List<dynamic>> getAccounts() async {
    final url = Uri.parse("$baseUrl/accounts/");

    final response = await http.get(url,headers: await ApiService().getAuthHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load accounts");
    }
  }

  Future<Map<String, dynamic>> getAccountById(int id) async {
    final url = Uri.parse("$baseUrl/accounts/$id");

    final response = await http.get(url, headers: await ApiService().getAuthHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load account");
    }
  }
}