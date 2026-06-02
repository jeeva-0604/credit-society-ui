import 'package:flutter/material.dart';import 'package:credit_society/utils/app_colors.dart';
import '../main.dart'; // for navigatorKey

class NotificationHelper {
  static void showForegroundNotification(
      BuildContext context,
      String title,
      String body,
      String route,
      String itemId,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
            Text(body, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.deepPurple.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () {
            if (itemId.isNotEmpty) {
              navigatorKey.currentState?.pushNamed(route, arguments: itemId);
            } else {
              navigatorKey.currentState?.pushNamed(route);
            }
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
