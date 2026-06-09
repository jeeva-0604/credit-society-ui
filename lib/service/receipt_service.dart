import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'apiservice.dart';

class ReceiptService {
  final String _base = ApiService.getBaseUrl().replaceAll(RegExp(r'/+$'), '');

  Future<Map<String, String>> get _headers => ApiService().getAuthHeaders();

  // ── RECEIPTS ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getReceipts() async {
    final url = Uri.parse('$_base/receipts/');
    try {
      final res = await http.get(url, headers: await _headers)
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded.whereType<Map<String, dynamic>>().toList();
        }
        return [];
      }
      _throwDetail(res, 'Failed to load receipts');
    } on TimeoutException {
      throw Exception('Request timed out. Check your connection and try again.');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getReceiptById(int id) async {
    final url = Uri.parse('$_base/receipts/$id/');
    try {
      final res = await http.get(url, headers: await _headers)
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
      _throwDetail(res, 'Receipt not found');
    } on TimeoutException {
      throw Exception('Request timed out. Check your connection and try again.');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> createReceipt(Map<String, dynamic> data) async {
    final url = Uri.parse('$_base/receipts/');
    try {
      final res = await http.post(url, headers: await _headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      _throwDetail(res, 'Failed to create receipt');
    } on TimeoutException {
      throw Exception('Request timed out. Check your connection and try again.');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> updateReceipt(int id, Map<String, dynamic> data) async {
    final url = Uri.parse('$_base/receipts/$id/');
    try {
      final res = await http.put(url, headers: await _headers, body: jsonEncode(data))
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      _throwDetail(res, 'Failed to update receipt');
    } on TimeoutException {
      throw Exception('Request timed out. Check your connection and try again.');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> deleteReceipt(int id) async {
    final url = Uri.parse('$_base/receipts/$id/');
    try {
      final res = await http.delete(url, headers: await _headers)
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200 || res.statusCode == 204) return;
      _throwDetail(res, 'Failed to delete receipt');
    } on TimeoutException {
      throw Exception('Request timed out. Check your connection and try again.');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ── MEMBER SEARCH ─────────────────────────────────────────────────────────
  // Handles both plain list [] and paginated {"page":1,"items":[...]} responses.

  Future<List<Map<String, dynamic>>> searchMembers(String query) async {
    final url = Uri.parse(
        '$_base/members/search/?search=${Uri.encodeQueryComponent(query)}');
    try {
      final res = await http.get(url, headers: await _headers)
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded.whereType<Map<String, dynamic>>().toList();
        }
        if (decoded is Map && decoded.containsKey('items')) {
          return (decoded['items'] as List? ?? [])
              .whereType<Map<String, dynamic>>()
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── MEMBER ACCOUNTS ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMemberAccounts(int memberId) async {
    final url = Uri.parse('$_base/members/$memberId/accounts');
    try {
      final res = await http.get(url, headers: await _headers)
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          return decoded.whereType<Map<String, dynamic>>().toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── LEDGERS (for A/C Description dropdown in receipts) ────────────────────

  Future<List<Map<String, dynamic>>> getLedgers() async {
    final url = Uri.parse('$_base/ledgers/');
    try {
      final res = await http.get(url, headers: await _headers)
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List<dynamic> raw = [];
        if (decoded is List) {
          raw = decoded;
        } else if (decoded is Map && decoded.containsKey('items')) {
          raw = decoded['items'] as List? ?? [];
        }
        return raw.whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ── MEMBER MAX AMOUNT (for Check Member Limit button) ─────────────────────

  Future<double?> getMemberMaxAmount(int memberId) async {
    final url = Uri.parse('$_base/members/$memberId/');
    try {
      final res = await http.get(url, headers: await _headers)
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final raw = data['max_amount'];
        return double.tryParse(raw?.toString() ?? '');
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── REVERSE ───────────────────────────────────────────────────────────────

  Future<void> reverseReceipt(int id) async {
    final url = Uri.parse('$_base/receipts/$id/reverse/');
    try {
      final res = await http.post(url, headers: await _headers)
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200 || res.statusCode == 201) return;
      _throwDetail(res, 'Failed to reverse receipt');
    } on TimeoutException {
      throw Exception('Request timed out. Check your connection and try again.');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  Never _throwDetail(http.Response res, String fallback) {
    try {
      final body = jsonDecode(res.body) as Map;
      throw Exception(body['detail']?.toString() ?? fallback);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('$fallback (HTTP ${res.statusCode})');
    }
  }
}
