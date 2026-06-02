import 'package:flutter/material.dart';import 'package:credit_society/utils/app_colors.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CommonScannerScreen extends StatelessWidget {
  final String title;
  const CommonScannerScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              // ✅ Return the scanned code immediately
              Navigator.pop(context, barcode.rawValue);
              break;
            }
          }
        },
      ),
    );
  }
}