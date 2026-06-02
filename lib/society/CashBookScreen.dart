import 'package:credit_society/service/report_service.dart';
import 'package:flutter/material.dart';

class CashBookscreen extends StatefulWidget {
  const CashBookscreen({super.key});

  @override
  State<CashBookscreen> createState() => _CashBookscreenState();
}

class _CashBookscreenState extends State<CashBookscreen> {

  List data = [];

  getData() async {
    final api = ReportService();
    final res = await api.getCashBook("2026-01-01", "2026-05-31");
    setState(() => data = res);
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cash Book")),
      body: ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, i) {
          final item = data[i];
          return ListTile(
            title: Text(item["description"] ?? ""),
            subtitle: Text(item["ledger"] ?? ""),
            trailing: Column(
              children: [
                Text("Dr: ${item["debit"]}"),
                Text("Cr: ${item["credit"]}"),
              ],
            ),
          );
        },
      ),
    );
  }
}