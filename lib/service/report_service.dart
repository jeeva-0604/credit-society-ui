import 'dart:convert';
import 'package:http/http.dart' as http;
import 'apiservice.dart';

class ReportService {
  final String baseUrl = ApiService.getBaseUrl().replaceAll(RegExp(r'/+$'), '');

  Future getDayBook(String from, String to) async {
    final res = await http.get(Uri.parse(
        "$baseUrl/reports/day-book?from_date=$from&to_date=$to"
    ));
    return jsonDecode(res.body);
  }

  Future getCashBook(String from, String to) async {
    final res = await http.get(Uri.parse(
        "$baseUrl/reports/cash-book?from_date=$from&to_date=$to"
    ));
    return jsonDecode(res.body);
  }

  Future getBankBook(String from, String to) async {
    final res = await http.get(Uri.parse(
        "$baseUrl/reports/bank-book?from_date=$from&to_date=$to"
    ));
    return jsonDecode(res.body);
  }

  Future getLedger(int id, String from, String to) async {
    final res = await http.get(Uri.parse(
        "$baseUrl/reports/ledger/$id?from_date=$from&to_date=$to"
    ));
    return jsonDecode(res.body);
  }
}