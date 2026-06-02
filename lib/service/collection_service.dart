import 'dart:convert';
import 'package:http/http.dart' as http;

import 'apiservice.dart';

class CollectionService {
  final String baseUrl = ApiService.getBaseUrl().replaceAll(RegExp(r'/+$'), '');

  Future<List<dynamic>> fetchPendingDemands(int unitId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/demands/pending?unit_id=$unitId"),
      headers: await ApiService().getAuthHeaders(),
    );

    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> createCollection(Map data) async {
    final res = await http.post(
      Uri.parse("$baseUrl/collections/create"),
      headers: await ApiService().getAuthHeaders(),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> previewCollection(Map data) async {
    final res = await http.post(
      Uri.parse("$baseUrl/collections/preview"),
      headers: await ApiService().getAuthHeaders(),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  Future approve(int id) async {
    await http.post(Uri.parse("$baseUrl/collections/$id/approve"),
        headers: await ApiService().getAuthHeaders());
  }

  Future post(int id) async {
    await http.post(Uri.parse("$baseUrl/collections/$id/post"),
        headers: await ApiService().getAuthHeaders());
  }

  Future reverse(int id) async {
    await http.post(Uri.parse("$baseUrl/collections/$id/reverse"),
        headers: await ApiService().getAuthHeaders());
  }
}