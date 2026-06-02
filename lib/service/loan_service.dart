import 'dart:convert';
import 'package:http/http.dart' as http;
import 'apiservice.dart';

class LoanService {
  final String baseUrl = ApiService.getBaseUrl().replaceAll(RegExp(r'/+$'), '');

  Future<Map<String, dynamic>> getMemberPolicy(int memberId) async {
    final url = Uri.parse("$baseUrl/loans/verify/policy/$memberId");

    try {
      final response = await http.get(
        url,
        headers: await ApiService().getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Returns {"max_amount": ..., "max_tenure": ...}
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? "Failed to fetch loan policy");
      }
    } catch (e) {
      throw Exception("Connection Error: $e");
    }
  }

  Future<List<dynamic>> getLoanTypes() async {
    final response = await http.get(
      Uri.parse("$baseUrl/loans/list/loan-types"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  Future<void> applyLoan(Map data) async {
    final res = await http.post(
      Uri.parse("$baseUrl/loans/apply"),
      headers: await ApiService().getAuthHeaders(),
      body: jsonEncode(data),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed");
    }
  }

  Future<List<dynamic>> getLoans() async {
    final response = await http.get(
      Uri.parse("$baseUrl/loans/list"),
      headers: await ApiService().getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  Future<void> approveLoan(int loanId, data) async {
    print(loanId);
    final response = await http.post(
        Uri.parse("$baseUrl/loans/approve/$loanId"),
      headers: await ApiService().getAuthHeaders(),
      body: jsonEncode(data),
    );
    print(jsonDecode(response.body));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return;
    }
  }

  Future<void> disburseLoan(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse("$baseUrl/loans/disburse"),
      headers: await ApiService().getAuthHeaders(),
      body: jsonEncode(data),
    );

    if (res.statusCode != 200) {
      print("Disburse error: ${res.body}");
      throw Exception("Disbursement failed");
    }
  }

  Future<List> getEmiSchedule(int loanId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/loans/emi/$loanId"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load EMI schedule");
    }
  }
}