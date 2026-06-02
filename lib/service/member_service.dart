import 'dart:convert';
import 'package:http/http.dart' as http;
import 'apiservice.dart';

class MemberService {
  final String baseUrl = ApiService.getBaseUrl().replaceAll(RegExp(r'/+$'), '');

  Future<Map<String, dynamic>> getBalances(int memberId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/members/get_member_balances/$memberId"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load balances");
    }
  }

  Future<Map<String, dynamic>> uploadMemberCSV(file) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("$baseUrl/members/bulk-upload"),
    );

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path!,
    ));

    var response = await request.send();

    // ✅ READ ACTUAL RESPONSE BODY
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      throw Exception("Upload failed: $responseBody");
    }
  }

    Future<List<dynamic>> getUniqueUnits() async {
    final response = await http.get(
      Uri.parse("$baseUrl/accounts/branches/"),
      headers: await ApiService().getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body); // This returns a List<dynamic>
    } else {
      return ["All"];
    }
  }

  Future<List<dynamic>> getAccounts(int memberId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/members/$memberId/accounts"),
        headers: await ApiService().getAuthHeaders()
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  Future<List> getMembersSearch(String search) async {
    final res = await http.get(
      Uri.parse("$baseUrl/members/search/?search=$search"),
        headers: await ApiService().getAuthHeaders()
    );

    return jsonDecode(res.body);
  }

  Future<List> getMembers(String search) async {
    final res = await http.get(Uri.parse("$baseUrl/members/search/?search=$search"),
      headers: await ApiService().getAuthHeaders());
    return jsonDecode(res.body);
  }

  Future<void> createMember(Map data) async {
    await http.post(
      Uri.parse("$baseUrl/members/"),
      headers: await ApiService().getAuthHeaders(),
      body: jsonEncode(data),
    );
  }

  Future updateMember(int id, Map data) async {
    await http.put(
      Uri.parse("$baseUrl/members/$id"),
        headers: await ApiService().getAuthHeaders(),
      body: jsonEncode(data),
    );
  }

  Future approveMember(int id) async { 
    await http.post(
      Uri.parse("$baseUrl/members/$id/approve"),
        headers: await ApiService().getAuthHeaders()
    );
  }

  Future rejectMember(int id, Map data) async {
    await http.put(
      Uri.parse("$baseUrl/members/reject/$id"),
      headers: await ApiService().getAuthHeaders(),
      body: jsonEncode(data),
    );
  }
}