import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {
  // Static variables to hold the loaded fonts
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;
  static pw.ThemeData? _theme;

  // Call this once in your main.dart or during app initialization
  static Future<void> init() async {
    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final fontBoldData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");

    _regularFont = pw.Font.ttf(fontData);
    _boldFont = pw.Font.ttf(fontBoldData);

    _theme = pw.ThemeData.withFont(
      base: _regularFont,
      bold: _boldFont,
    );
  }

  // Getters to use in your generation functions
  static pw.ThemeData get theme => _theme ?? pw.ThemeData();
  static pw.Font get regular => _regularFont!;
  static pw.Font get bold => _boldFont!;
}