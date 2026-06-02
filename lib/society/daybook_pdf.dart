import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

import '../service/pdf_service.dart';


Future<pw.Document> generateDayBookPdf(
    double openingBalance,
    Map<String, List<dynamic>> groupedData,
    ) async {

  final pdf = pw.Document();
  final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
  final ttf = pw.Font.ttf(fontData);

  pdf.addPage(
    pw.MultiPage(
      theme: PdfService.theme,
      pageFormat: PdfPageFormat.a4,
      build: (context) {

        List<pw.Widget> content = [];

        // 🔹 Opening Balance
        content.add(
          pw.Text(
            "Opening Balance: ₹ $openingBalance",
            style: pw.TextStyle(font: PdfService.bold, fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        );

        content.add(pw.SizedBox(height: 10));

        // 🔹 Each Date
        groupedData.forEach((date, items) {

          double totalDr = 0;
          double totalCr = 0;

          for (var i in items) {
            totalDr += (i["debit"] ?? 0);
            totalCr += (i["credit"] ?? 0);
          }

          content.add(
            pw.Text(
              date,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          );

          content.add(pw.Divider());

          for (var item in items) {
            content.add(
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(item["ledger"] ?? ""),
                  pw.Text(
                    (item["debit"] ?? 0) > 0
                        ? "Dr ${item["debit"]}"
                        : "Cr ${item["credit"]}",
                  ),
                ],
              ),
            );
          }

          content.add(pw.Divider());

          content.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("Total"),
                pw.Text("Dr: $totalDr | Cr: $totalCr"),
              ],
            ),
          );

          content.add(pw.SizedBox(height: 15));
        });

        return content;
      },
    ),
  );

  return pdf;
}

Future<pw.Document> generateProfessionalDayBookPdf({
  required double openingBalance,
  required Map<String, List<dynamic>> groupedData,
  required String fromDate,
  required String toDate,
}) async {

  final pdf = pw.Document();
  final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
  final ttf = pw.Font.ttf(fontData);

  // ✅ Load Logo
  final logoBytes = await rootBundle.load('assets/icon.png');
  final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

  double runningBalance = openingBalance;

  pdf.addPage(
    pw.MultiPage(
      theme: PdfService.theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (context) {

        List<pw.Widget> content = [];

        // ================= HEADER =================
        content.add(
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Image(logo, width: 40, height: 40),
                  pw.SizedBox(width: 10),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Your Credit Society",
                          style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text("Day Book Report"),
                    ],
                  )
                ],
              ),
              pw.Text("From: $fromDate\nTo: $toDate"),
            ],
          ),
        );

        content.add(pw.Divider());

        // ================= OPENING BAL =================
        content.add(
          pw.Text(
            "Opening Balance: ₹ $openingBalance",
            style: pw.TextStyle(font: PdfService.bold, fontWeight: pw.FontWeight.bold),
          ),
        );

        content.add(pw.SizedBox(height: 10));

        // ================= TABLE HEADER =================
        content.add(
          pw.Container(
            color: PdfColors.grey300,
            padding: const pw.EdgeInsets.all(5),
            child: pw.Row(
              children: [
                pw.Expanded(flex: 2, child: pw.Text("Date")),
                pw.Expanded(flex: 4, child: pw.Text("Ledger")),
                pw.Expanded(flex: 2, child: pw.Text("Dr")),
                pw.Expanded(flex: 2, child: pw.Text("Cr")),
                pw.Expanded(flex: 2, child: pw.Text("Balance")),
              ],
            ),
          ),
        );

        // ================= DATA =================
        groupedData.forEach((date, items) {

          content.add(
            pw.Container(
              color: PdfColors.grey200,
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(date,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          );

          double totalDr = 0;
          double totalCr = 0;

          for (var item in items) {
            double dr = (item["debit"] ?? 0).toDouble();
            double cr = (item["credit"] ?? 0).toDouble();

            totalDr += dr;
            totalCr += cr;

            runningBalance += dr;
            runningBalance -= cr;

            content.add(
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 2, child: pw.Text(date)),
                    pw.Expanded(flex: 4, child: pw.Text(item["ledger"] ?? "")),
                    pw.Expanded(flex: 2, child: pw.Text(dr > 0 ? dr.toString() : "")),
                    pw.Expanded(flex: 2, child: pw.Text(cr > 0 ? cr.toString() : "")),
                    pw.Expanded(flex: 2, child: pw.Text(runningBalance.toStringAsFixed(2))),
                  ],
                ),
              ),
            );
          }

          // 🔹 Daily Total
          content.add(
            pw.Container(
              color: PdfColors.grey100,
              padding: const pw.EdgeInsets.all(5),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Daily Total"),
                  pw.Text("Dr: $totalDr | Cr: $totalCr"),
                ],
              ),
            ),
          );

          content.add(pw.SizedBox(height: 10));
        });

        return content;
      },
    ),
  );

  return pdf;
}


Future<pw.Document> generateBankBookPdf({
  required Map<String, List<dynamic>> groupedData,
  required String fromDate,
  required String toDate,
}) async {

  final pdf = pw.Document();
  final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
  final ttf = pw.Font.ttf(fontData);

  double runningBalance = 0;

  pdf.addPage(
    pw.MultiPage(
      theme: PdfService.theme,
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (context) {

        List<pw.Widget> content = [];

        // ================= HEADER =================
        content.add(
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "Bank Book Report",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text("From: $fromDate\nTo: $toDate"),
            ],
          ),
        );

        content.add(pw.Divider());

        // ================= TABLE HEADER =================
        content.add(
          pw.Container(
            color: PdfColors.grey300,
            padding: const pw.EdgeInsets.all(5),
            child: pw.Row(
              children: [
                pw.Expanded(flex: 2, child: pw.Text("Date")),
                pw.Expanded(flex: 4, child: pw.Text("Bank")),
                pw.Expanded(flex: 2, child: pw.Text("Dr")),
                pw.Expanded(flex: 2, child: pw.Text("Cr")),
                pw.Expanded(flex: 2, child: pw.Text("Balance")),
              ],
            ),
          ),
        );

        // ================= DATA =================
        groupedData.forEach((date, items) {

          content.add(
            pw.Container(
              color: PdfColors.grey200,
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                date,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          );

          double totalDr = 0;
          double totalCr = 0;

          for (var item in items) {
            double dr = (item["debit"] ?? 0).toDouble();
            double cr = (item["credit"] ?? 0).toDouble();

            totalDr += dr;
            totalCr += cr;

            runningBalance += dr;
            runningBalance -= cr;

            content.add(
              pw.Row(
                children: [
                  pw.Expanded(flex: 2, child: pw.Text(date)),
                  pw.Expanded(flex: 4, child: pw.Text(item["bank"] ?? "")), // ✅ changed
                  pw.Expanded(flex: 2, child: pw.Text(dr > 0 ? dr.toString() : "")),
                  pw.Expanded(flex: 2, child: pw.Text(cr > 0 ? cr.toString() : "")),
                  pw.Expanded(flex: 2, child: pw.Text(runningBalance.toStringAsFixed(2))),
                ],
              ),
            );
          }

          // 🔹 Daily Total
          content.add(
            pw.Container(
              color: PdfColors.grey100,
              padding: const pw.EdgeInsets.all(5),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Daily Total"),
                  pw.Text("Dr: $totalDr | Cr: $totalCr"),
                ],
              ),
            ),
          );

          content.add(pw.SizedBox(height: 10));
        });

        return content;
      },
    ),
  );

  return pdf;
}