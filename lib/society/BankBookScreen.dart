import 'package:credit_society/service/report_service.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'daybook_pdf.dart'; // reuse pdf
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
class BankBookscreen extends StatefulWidget {
  const BankBookscreen({super.key});

  @override
  State<BankBookscreen> createState() => _BankBookscreenState();
}

class _BankBookscreenState extends State<BankBookscreen> {
  List data = [];
  bool loading = false;

  DateTime fromDate = DateTime(DateTime.now().year, 1, 1);
  DateTime toDate = DateTime.now();

  String formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.year}";
  }

  String apiDate(DateTime d) {
    return d.toIso8601String().split("T")[0];
  }

  Future<void> getData() async {
    setState(() => loading = true);

    try {
      final api = ReportService();
      final res = await api.getBankBook(
        apiDate(fromDate),
        apiDate(toDate),
      );

      setState(() {
        data = res ?? [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Map<String, List<dynamic>> groupByDate(List data) {
    Map<String, List<dynamic>> grouped = {};

    for (var item in data) {
      String date = item["date"].toString().split("T")[0];

      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(item);
    }

    return grouped;
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
        isFrom ? fromDate = picked : toDate = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bank Book")),

      body: Column(
        children: [

          // 🔹 DATE FILTER
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
                  onPressed: getData,
                  child: const Text("Load"),
                ),

                // 📄 FULL PDF
                ElevatedButton(
                  onPressed: () async {
                    final grouped = groupByDate(data);

                    final pdf = await generateBankBookPdf(
                      groupedData: grouped,
                      fromDate: formatDate(fromDate),
                      toDate: formatDate(toDate),
                    );

                    await Printing.sharePdf(
                      bytes: await pdf.save(),
                      filename: "bankbook.pdf",
                    );
                  },
                  child: const Text("PDF"),
                ),
              ],
            ),
          ),

          // 🔹 BODY
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : data.isEmpty
                ? const Center(child: Text("No Records Found"))
                : Builder(
              builder: (context) {
                final grouped = groupByDate(data);
                final dates = grouped.keys.toList();

                return ListView.builder(
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final items = grouped[date]!;

                    double totalDr = 0;
                    double totalCr = 0;

                    for (var i in items) {
                      totalDr += (i["debit"] ?? 0);
                      totalCr += (i["credit"] ?? 0);
                    }

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // 📅 DATE HEADER + PDF
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  date,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                  onPressed: () async {

                                    final singleDay = {date: items}; // ✅ correct

                                    final pdf = await generateBankBookPdf(   // ✅ use BANK PDF
                                      groupedData: singleDay,
                                      fromDate: date,
                                      toDate: date,
                                    );

                                    await Printing.sharePdf(
                                      bytes: await pdf.save(),
                                      filename: "bankbook_$date.pdf",
                                    );
                                  },
                                )
                              ],
                            ),

                            const Divider(),

                            // 📋 ENTRIES
                            ...items.map((item) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(item["bank"] ?? ""), // ✅ FIXED
                                  ),
                                  Text(
                                    (item["debit"] ?? 0) > 0
                                        ? "Dr ${item["debit"]}"
                                        : "Cr ${item["credit"]}",
                                  ),
                                ],
                              );
                            }),

                            const Divider(),

                            // 💰 TOTAL
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Total",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "Dr: $totalDr | Cr: $totalCr",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}