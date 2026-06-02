import 'dart:convert';
import 'package:http/http.dart' as http;

import 'apiservice.dart';

class ReceiptService {
  final String baseUrl = ApiService.getBaseUrl().replaceAll(RegExp(r'/+$'), '');

  Future<Map<String, dynamic>> createReceipt(Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/receipts/");
    try {
      final response = await http.post(
        url,
        headers: await ApiService().getAuthHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      final body = jsonDecode(response.body);
      throw Exception(body["detail"] ?? "Failed to create receipt");
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }

  Future<Map<String, dynamic>> updateReceipt(int id, Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/receipts/$id");
    try {
      final response = await http.put(
        url,
        headers: await ApiService().getAuthHeaders(),
        body: jsonEncode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      final body = jsonDecode(response.body);
      throw Exception(body["detail"] ?? "Failed to update receipt");
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }

  Future<List<dynamic>> getReceipts() async {
    final url = Uri.parse("$baseUrl/receipts/");
    try {
      final response = await http.get(url, headers: await ApiService().getAuthHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception("Failed to load receipts (HTTP ${response.statusCode})");
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }

  Future<Map<String, dynamic>> getReceiptById(int id) async {
    final url = Uri.parse("$baseUrl/receipts/$id");
    try {
      final response = await http.get(url, headers: await ApiService().getAuthHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception("Receipt #$id not found");
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }
}
