import 'package:credit_society/service/pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:credit_society/utils/app_colors.dart';
import 'package:credit_society/screens/splashscreen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'screens/home_screen.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en', null);
  await PdfService.init();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Credit Society",
      navigatorKey: navigatorKey,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.white,
        primaryColor: AppColors.darkBlue,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.darkBlue,
          unselectedItemColor: Colors.grey,
        ),
        cardColor: AppColors.lightBlue,
        iconTheme: const IconThemeData(color: AppColors.darkBlue),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: AppColors.darkBlue),
          titleMedium: TextStyle(color: AppColors.darkBlue),
        ),
      ),
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
      },
      initialRoute: '/',
        builder: (context, child) {
          return child!;
        }
    );
  }
}