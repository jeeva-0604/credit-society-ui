import 'package:flutter/material.dart';import 'package:credit_society/utils/app_colors.dart';

class AppStyle {
  // 🎨 IHMGAHS BRAND PALETTE
  static const Color primaryBlue = AppColors.primary;   // Royal Blue
  static const Color accentYellow = Color(0xFFFFF200);  // Golden Yellow
  static const Color surfaceSky = Color(0xFFE1F5FE);    // Sky Blue Background
  static const Color white = Colors.white;

  static List<BoxShadow> primaryShadow = [
    BoxShadow(
      color: primaryBlue.withOpacity(0.12), // Subtle Blue tint
      blurRadius: 12,
      spreadRadius: 2,
      offset: const Offset(0, 6), // Gives the 'Elevated' 3D look
    ),
  ];

  // 💡 Common SnackBar Style
  static SnackBar commonSnackBar({
    required String title,
    required String body,
    VoidCallback? onAction
  }) {
    return SnackBar(
      backgroundColor: primaryBlue,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: white)),
          Text(body, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
      action: onAction != null
          ? SnackBarAction(label: 'VIEW', textColor: accentYellow, onPressed: onAction)
          : null,
    );
  }
}