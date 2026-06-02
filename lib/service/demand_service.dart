import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'apiservice.dart';

class DemandService {
  final String baseUrl = ApiService.getBaseUrl().replaceAll(RegExp(r'/+$'), '');

  Future<Map<String, dynamic>> generateDemand(DateTime selectedDate, selectedUnit) async {
    final url = Uri.parse("$baseUrl/demands/generate");
    String formattedDate = DateFormat('yyyy-MM-01').format(selectedDate);

    try {
      final response = await http.post(
        url,
          headers: await ApiService().getAuthHeaders(),
        body: jsonEncode({
          "target_date": formattedDate,
          "user_id": 1,
          "unit_id": selectedUnit
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? "Failed to generate demand");
      }
    } catch (e) {
      throw Exception("Connection Error: $e");
    }
  }

  Future<List<dynamic>> getDemandDetails(int demandId) async {
    final url = Uri.parse("$baseUrl/demands/$demandId/details");
    final response = await http.get(url, headers: await ApiService().getAuthHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load demand details");
    }
  }

  Future<List<dynamic>> getDemandReport(String? unit) async {
    // If unit is "All" or null, we might want a different endpoint or handle it in the path
    final pathUnit = (unit == null || unit == "All") ? "All" : unit;

    final url = Uri.parse("$baseUrl/demands/$pathUnit/units");
    final response = await http.get(url, headers: await ApiService().getAuthHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load unit report");
    }
  }
}