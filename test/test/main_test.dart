import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';import 'package:credit_society/utils/app_colors.dart';
import 'package:credit_society/main.dart';
import 'package:credit_society/utils/notification_helper.dart';

void main() {
  testWidgets('Shows SnackBar when NotificationHelper is called',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: const Text('Root')),
          ),
        );

// Advance time by 3 seconds to let splash timer finish
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(); // rebuild once


        NotificationHelper.showForegroundNotification(
          tester.element(find.text('Root')),
          'Test Title',
          'Test Body',
          '/home',
          '123',
        );


        await tester.pump(); // let SnackBar render

        expect(find.text('Test Title'), findsOneWidget);
        expect(find.text('Test Body'), findsOneWidget);
        expect(find.text('HomeScreen'), findsOneWidget);

      });
}
