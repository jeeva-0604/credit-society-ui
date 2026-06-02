import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../service/apiservice.dart';

class TrialBalanceScreen extends StatefulWidget {
  const TrialBalanceScreen({super.key});

  @override
  State<TrialBalanceScreen> createState() => _TrialBalanceScreenState();
}

class _TrialBalanceScreenState extends State<TrialBalanceScreen> {
  List data = [];
  double totalDr = 0;
  double totalCr = 0;
  final String baseUrl = ApiService.getBaseUrl().replaceAll(RegExp(r'/+$'), '');

  @override
  void initState() {
    super.initState();
    fetchTrialBalance();
  }

  Future<void> fetchTrialBalance() async {
    final res = await http.get(
      Uri.parse("$baseUrl/reports/trial-balance"),
    );

    final jsonData = json.decode(res.body);

    setState(() {
      data = jsonData['data'];
      totalDr = jsonData['total_debit'];
      totalCr = jsonData['total_credit'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trial Balance")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final row = data[index];
                return ListTile(
                  title: Text(row['ledger_name']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Dr: ${row['debit']}  "),
                      Text("Cr: ${row['credit']}"),
                    ],
                  ),
                );
              },
            ),
          ),

          // TOTAL
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("TOTAL", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Dr: $totalDr   Cr: $totalCr",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}