// import 'package:flutter/material.dart';import 'package:credit_society/utils/app_colors.dart';
//
// class AppColors {
//   // 🎨 IHMGAHS CORE BRANDING
//   static const Color primary = Color(0xFF6A1B9A);   // Deep Royal Blue
//   static const Color accent = Color(0xFFFFF200);    // Golden Yellow
//   static const Color surface = Color(0xFFE1F5FE);   // Sky Blue Background
//   static const Color darkBlue = Color(0xFF10134F);  // Deep Navy
//   static const Color lightBlue = Color(0xFFB3E5FC); // Highlight Blue
//
//   // 🎨 EMBOSSED & NEUMORPHIC ADDITIONS
//   static const Color splashBackground = Color(0xFFE6C5E1);
//   static const Color splashLightPurple = Color(0xFFE2C7F1);
//   static const Color shimmerHighlight = Color(0xFF4A0170);
//
//   // Custom shades if you don't want to use .withOpacity()
//   static const Color primaryLight = Color(0xFF8A28BD);
//   static final Color shadowGrey = Colors.grey.shade300;
//
//   // ⚪ NEUTRALS & TEXT
//   static const Color white = Color(0xFFFFFFFF);
//   static const Color greenAccent = Colors.greenAccent;
//   static const Color white70 = Colors.white70;
//   static const Color white54 = Colors.white54;
//   static const Color redAccent = Colors.redAccent;
//   static const Color blueAccent = Colors.blueAccent;
//   static const Color orangeAccent = Colors.orangeAccent;
//   static const Color offWhite = Color(0xFFF8F9FA);
//   static const Color textDark = Color(0xFF1A1C54);
//   static const Color black = Colors.black;
//   static const Color black87 = Colors.black87;
//   static const Color black12 = Colors.black12;
//   static const Color grey = Colors.grey;
//   static final Color grey_300 = Colors.grey[300]!;
//   static final Color grey_100 = Colors.grey[100]!;
//   static const Color textLight = Color(0xFF757575); // This is exactly what .shade600 is!
//   static const Color lightBlueAccent = Colors.lightBlueAccent;
//   static const Color pinkAccent = Colors.pinkAccent;
//
//   // 🚦 STATUS COLORS
//   static const Color success = Color(0xFF2E7D32);   // Green
//   static const Color warning = Color(0xFFFFA000);   // Orange/Amber
//   static const Color error = Color(0xFFC62828);     // Red
//   static const Color info = Color(0xFF1976D2);
//
//   static const Color green = Color(0xFF2E7D32);   // ✅ Green (Attendance/Pass)
//   static const Color orange = Color(0xFFF57C00);   // 🟠 Orange (Pending/Late)
//   static const Color red = Color(0xFFD32F2F);     // ❌ Red (Failed/Absent)
//   static const Color blue = Color(0xFF1976D2);      // 🔵 Blue (Notice/Update)
//
//   // 💡 TINTED SHADOWS
//   static List<BoxShadow> primaryShadow = [
//     BoxShadow(
//       color: primary.withOpacity(0.15),
//       blurRadius: 10,
//       offset: const Offset(0, 5),
//     )
//   ];
//
//   // 🌈 1. DYNAMIC GRID PALETTE (16 Colors)
//   static Color getFeatureColor(int index) {
//     const colors = [
//       Color(0xFF4FC3F7), Color(0xFF9575CD), Color(0xFFFF8A65), Color(0xFF4DB6AC),
//       Color(0xFF7986CB), Color(0xFF81C784), Color(0xFFF06292), Color(0xFFFFD54F),
//       Color(0xFF4DD0E1), Color(0xFFAED581), Color(0xFFFFB74D), Color(0xFF90A4AE),
//       Color(0xFFD4E157), Color(0xFFBA68C8), Color(0xFF4DB6AC), Color(0xFF64B5F6),
//     ];
//     return colors[index % colors.length];
//   }
//
//   // 🌑 2. DYNAMIC DEEP SHADOWS (Matching the 16 colors)
//   static Color getFeatureShadow(int index) {
//     const shadows = [
//       Color(0xFF0288D1), Color(0xFF5E35B1), Color(0xFFE64A19), Color(0xFF00796B),
//       Color(0xFF303F9F), Color(0xFF388E3C), Color(0xFFC2185B), Color(0xFFFFA000),
//       Color(0xFF0097A7), Color(0xFF689F38), Color(0xFFF57C00), Color(0xFF455A64),
//       Color(0xFFAFB42B), Color(0xFF7B1FA2), Color(0xFF00897B), Color(0xFF1976D2),
//     ];
//     return shadows[index % shadows.length];
//   }
// }


import 'package:flutter/material.dart';import 'package:credit_society/utils/app_colors.dart';

class AppColors {

  // 🎨 CORE BRANDING (Updated to your preferred Blue)
  static const Color primary = Color(0xFF00789B);       // Main Theme Blue
  static const Color primaryDark = Color(0xFF005670);   // Darker shade for Headers/Cards
  static const Color accent = Color(0xFFC5A359);        // Fiona Antique Gold

  static const Color surface = Color(0xFFF0F4F8);
  static const Color background = Color(0xFFEEEEEE);    // Light Grey for App Background

  // ⚪ NEUTRALS
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color textDark = Color(0xFF0D1B35);
  static final Color grey_200 = Colors.grey[200]!;
  static final Color grey_300 = Colors.grey[300]!;
  static final Color grey_400 = Colors.grey[400]!;

  // 🚦 STATUS
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF57C00);

  // 🎨 FIONA GLOBAL CORE BRANDING (Extracted from Logo)
  static const Color accentDark = Color(0xFFC8921A);    // Fiona Antique Gold
  static const Color accentLight = Color(0xFFC6B796);    // Fiona Antique Gold
  static const Color darkBlue = Color(0xFF0D1B35);  // Extra Dark Navy for Text
  static const Color lightBlue = Color(0xFFD1D9E6); // Muted Highlight Blue
  static const Color primaryBottom = Color(0xFFD1DAE8);   // Soft Professional Grey-Blue

  // 🎨 EMBOSSED & NEUMORPHIC ADDITIONS (Updated for Navy Theme)
  static const Color splashBackground = Color(0xFFE6EBF2); // Match Surface
  static const Color splashLightPurple = Color(0xFFD9E1EC); // Soft Blue-Grey
  static const Color shimmerHighlight = Color(0xFF2C5294); // Lighter Navy for Shimmer

  // Custom shades for the embossed effect
  static const Color primaryLight = Color(0xFF264B8A); // Mid-tone Navy
  static final Color shadowGrey = Colors.grey.shade400;

  // ⚪ NEUTRALS & TEXT

  static const Color white70 = Colors.white70;
  static const Color white54 = Colors.white54;
  static const Color white24 = Colors.white24;
  static const Color offWhite = Color(0xFFF8F9FA);
  static const Color textLight = Color(0xFF607D8B);
  static const Color grey = Colors.grey;
  static const Color teal = Colors.teal;
  static const Color indigo = Colors.indigo;
  static const Color deepPurple = Colors.deepPurple;
  static const Color green = Color(0xFF2E7D32);   // ✅ Green (Attendance/Pass)
  static const Color orange = Color(0xFFF57C00);   // 🟠 Orange (Pending/Late)
  static const Color red = Color(0xFFD32F2F);     // ❌ Red (Failed/Absent)
  static const Color blue = Color(0xFF1976D2);      // 🔵 Blue (Notice/Update)
  static const Color yellow = Color(0xFFFBC02D);
  static const Color info = Color(0xFF1976D2);

  // 💡 TINTED SHADOWS
  static List<BoxShadow> primaryShadow = [
    BoxShadow(
      color: primary.withOpacity(0.2),
      blurRadius: 10,
      offset: const Offset(0, 5),
    )
  ];

  // 🌈 DYNAMIC FEATURE PALETTE (Keeping your existing logic but updated to match Navy/Gold)
  static Color getFeatureColor(int index) {
    const colors = [
      Color(0xFF1A3668), Color(0xFFC5A359), Color(0xFF455A64), Color(0xFF2E7D32),
      Color(0xFF1565C0), Color(0xFF00838F), Color(0xFFAD1457), Color(0xFF6A1B9A),
    ];
    return colors[index % colors.length];
  }

  static Color getFeatureShadow(int index) {
    const shadows = [
      Color(0xFF0D1B35), Color(0xFFA68A48), Color(0xFF263238), Color(0xFF1B5E20),
      Color(0xFF0D47A1), Color(0xFF006064), Color(0xFF880E4F), Color(0xFF4A148C),
    ];
    return shadows[index % shadows.length];
  }

  static const Color greenAccent = Colors.greenAccent;
  static const Color redAccent = Colors.redAccent;
  static const Color blueAccent = Colors.blueAccent;
  static const Color orangeAccent = Colors.orangeAccent;
  static const Color deepOrange = Colors.deepOrange;
  static const Color black87 = Colors.black87;
  static const Color black54 = Colors.black54;
  static const Color black12 = Colors.black12;
  static const Color transparent = Colors.transparent;
  static final Color grey_50 = Colors.grey[50]!;
  static final Color grey_600 = Colors.grey[600]!;
  static final Color grey_100 = Colors.grey[100]!;
  static final Color grey_700 = Colors.grey[700]!;
  static const Color lightBlueAccent = Colors.lightBlueAccent;
  static const Color pinkAccent = Colors.pinkAccent;
  static final Color redShade100 = Colors.red[100]!;
  static final Color redShade700 = Colors.red[700]!;
  static final Color redShade900 = Colors.red[900]!;
  static final Color redShade200 = Colors.red[200]!;
  static final Color redShade300 = Colors.red[300]!;
  static final Color redShade400 = Colors.red[400]!;
  static final Color redShade50 = Colors.red[50]!;
  static final Color orangeShade900 = Colors.orange[900]!;
  static final Color orangeShade800 = Colors.orange[800]!;
  static final Color orangeShade200 = Colors.orange[200]!;
  static final Color orangeShade100 = Colors.orange[100]!;
  static final Color orangeShade50 = Colors.orange[50]!;
  static final Color greenShade900 = Colors.green[900]!;
  static final Color greenShade700 = Colors.green[700]!;
  static final Color greenShade300 = Colors.green[300]!;
  static final Color greenShade200 = Colors.green[200]!;
  static final Color greenShade100 = Colors.green[100]!;
  static final Color greenShade50 = Colors.green[50]!;
  static final Color amberShade700 = Colors.amber[700]!;
  static final Color purpleShade50 = Colors.purple[50]!;
  static final Color purpleShade700 = Colors.purple[700]!;
  static final Color blueShade300 = Colors.blue[300]!;
  static final Color blueShade100 = Colors.blue[100]!;
  static final Color blueShade700 = Colors.blue[700]!;
  static final Color blueShade900 = Colors.blue[900]!;
  static final Color tealShade700 = Colors.teal[700]!;
  static final Color indigoShade700 = Colors.indigo[700]!;

  static Color getMediumDarkPaletteColor(int index) {
    final colors = [
      const Color(0xFF9AACCC), // Deeper Muted Blue
      const Color(0xFFD1B77E), // Aged Gold (Tarnished)
      const Color(0xFF90A4AE), // Slate Steel Grey
      const Color(0xFFA1887F), // Muted Cocoa
      const Color(0xFF81C784), // Heritage Green
      const Color(0xFF78909C), // Darker Surface Blue
    ];
    return colors[index % colors.length];
  }

  static Color getSoftPaletteColor(int index) {
    const colors = [
      Color(0xFF9AACCC), // Muted Fiona Navy (Mid-tone)
      Color(0xFFD1B77E), // Muted Antique Gold (Mid-tone)
      Color(0xFF90A4AE), // Cool Slate (Mid-tone)
      Color(0xFFA1887F), // Earthy Taupe (Mid-tone)
      Color(0xFF81C784), // Professional Sage (Mid-tone)
      Color(0xFF78909C), // Steel Blue (Mid-tone)
    ];
    return colors[index % colors.length];
  }

  static Color getLightPaletteColor(int index) {
    final colors = [
      const Color(0xFFD1D9E6), // Muted Fiona Blue
      const Color(0xFFE8E2D2), // Soft Champagne Gold
      const Color(0xFFCFD8DC), // Cool Blue Grey
      const Color(0xFFD7CCC8), // Warm Taupe
      const Color(0xFFC8E6C9), // Muted Sage Green
      const Color(0xFFF0F4F8), // Professional Surface Grey
    ];
    return colors[index % colors.length];
  }

  static Color getDeepPaletteColor(int index) {
    final colors = [
      const Color(0xFF1A3668), // Fiona Navy
      const Color(0xFFC5A359), // Fiona Antique Gold
      const Color(0xFF455A64), // Slate Dark
      const Color(0xFF5D4037), // Deep Earth Brown
      const Color(0xFF2E7D32), // School Green
      const Color(0xFF0D47A1), // Royal Academic Blue
    ];
    return colors[index % colors.length];
  }
}