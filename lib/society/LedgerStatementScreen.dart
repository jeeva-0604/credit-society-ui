import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../service/apiservice.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../utils/app_colors.dart';
class LedgerStatementScreen extends StatefulWidget {
  final int ledgerId;

  const LedgerStatementScreen({super.key, required this.ledgerId});

  @override
  State<LedgerStatementScreen> createState() => _LedgerStatementScreenState();
}

class _LedgerStatementScreenState extends State<LedgerStatementScreen> {
  List<dynamic> _data = [];
  bool _loading = false;
  final String baseUrl = ApiService.getBaseUrl().replaceAll(RegExp(r'/+$'), '');
  DateTime fromDate = DateTime(DateTime.now().year, 1, 1);
  DateTime toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchLedgerStatement();
  }

  Future<pw.Document> generateLedgerPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Ledger Statement",
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),

              pw.Table.fromTextArray(
                headers: ["Date", "Particulars", "Debit", "Credit", "Balance"],
                data: _data.map((item) {
                  return [
                    item["date"].toString(),
                    item["particulars"] ?? "",
                    item["debit"].toString(),
                    item["credit"].toString(),
                    item["balance"].toString(),
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<void> fetchLedgerStatement() async {
    setState(() => _loading = true);

    try {
      final from = fromDate.toIso8601String().split("T")[0];
      final to = toDate.toIso8601String().split("T")[0];

      final url =
          "$baseUrl/reports/ledger-statement"
          "?ledger_id=${widget.ledgerId}&from_date=$from&to_date=$to";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          _data = jsonDecode(response.body);
        });
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _loading = false);
  }

  Future<void> pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? fromDate : toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });

      print("Selected Date: $picked"); // debug
    }
  }

  String formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ledger Statement"),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // ================= DATE FILTER =================
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => pickDate(true),
                    child: Text("From: ${formatDate(fromDate)}"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => pickDate(false),
                    child: Text("To: ${formatDate(toDate)}"),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: fetchLedgerStatement,
                  child: const Text("Load"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final pdf = await generateLedgerPdf();

                    await Printing.sharePdf(
                      bytes: await pdf.save(),
                      filename: "ledger_statement.pdf",
                    );
                  },
                  child: const Text("PDF"),
                ),
              ],
            ),
          ),

          // ================= BODY =================
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _data.isEmpty
                ? const Center(child: Text("No Records Found"))
                : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(AppColors.primaryDark),
                columns: const [
                  DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white))),
                  DataColumn(label: Text("Particulars", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white))),
                  DataColumn(label: Text("Debit", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white))),
                  DataColumn(label: Text("Credit", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white))),
                  DataColumn(label: Text("Balance", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white))),
                ],
                rows: _data.map((item) {
                  return DataRow(cells: [
                    DataCell(Text(item["date"].toString())),
                    DataCell(Text(item["particulars"] ?? "")),
                    DataCell(Text(item["debit"].toString())),
                    DataCell(Text(item["credit"].toString())),
                    DataCell(
                      Text(
                        item["balance"].toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}