import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../service/apiservice.dart';
import 'LedgerStatementScreen.dart';

class LedgerListScreen extends StatefulWidget {
  const LedgerListScreen({super.key});

  @override
  _LedgerListScreenState createState() => _LedgerListScreenState();
}

class _LedgerListScreenState extends State<LedgerListScreen> {
  List ledgers = [];
  List filtered = [];
  final String baseUrl = ApiService.getBaseUrl().replaceAll(RegExp(r'/+$'), '');

  @override
  void initState() {
    super.initState();
    loadLedgers();
  }

  void loadLedgers() async {
    final res = await http.get(Uri.parse("$baseUrl/reports/ledgers"));
    final data = jsonDecode(res.body);

    setState(() {
      ledgers = data;
      filtered = data;
    });
  }

  void search(String value) {
    setState(() {
      filtered = ledgers
          .where((l) =>
      l['name'].toLowerCase().contains(value.toLowerCase()) ||
          l['code'].contains(value))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ledger List")),
      body: Column(
        children: [
          TextField(
            onChanged: search,
            decoration: InputDecoration(hintText: "Search ledger..."),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final l = filtered[index];

                return ListTile(
                  title: Text(l['name']),
                  subtitle: Text("Code: ${l['code']}"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LedgerStatementScreen(
                          ledgerId: l['id']
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}