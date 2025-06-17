// lib/main.dart

/*** |------------ Geecodex ------------|
 *   |      Author: @ppqwqqq            |
 *   |      Created At: 3 8 2025        |
 *   |    Hubei Engineering University  |
 *   |----------------------------------|
 */

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'package:Geecodex/constants/index.dart';

import 'package:Geecodex/screens/splash_screen.dart';
import 'package:Geecodex/screens/screen_framework.dart';
import 'package:Geecodex/screens/book_reader/index.dart';
import 'package:Geecodex/screens/book_reader/test_http_screen.dart';
import 'package:Geecodex/screens/book_reader/pdf_details_screen.dart';
import 'package:Geecodex/screens/book_details/book_details_screen.dart';
import 'package:Geecodex/screens/book_reader/widgets/pdf_viewer_wrapper.dart';

import 'package:Geecodex/models/book.dart';
import 'package:Geecodex/native/native_wrapper.dart';

void main() {
  // test native libs
  // final wrapper = native_wrapper();
  // wrapper.intialize();
  // double sum = wrapper.add_double(10, 10);
  // String test_opencv = wrapper.test_opencv();
  // print("Sum of 10 and 10: $sum");
  // print(test_opencv);
  // String test_onnxruntime = wrapper.test_onnxruntime();
  // print(test_onnxruntime);

  WidgetsFlutterBinding.ensureInitialized();

  final brightness =
      SchedulerBinding.instance.platformDispatcher.platformBrightness;
  final isDarkMode = brightness == Brightness.dark;

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeeCodeX',
      debugShowCheckedModeBanner: false, // Hide debug banner
      // --- Theme Config ---
      theme: ThemeData(
        // Light Theme
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          background: AppColors.background,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        // Dark Theme
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          background: Colors.grey[900]!,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.grey[900]!,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[850]!, // Darker AppBar
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // Respect system setting
      // --- Routing ---
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/framework': (context) => const ScreenFramework(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/reader':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder:
                  (context) => ReaderScreen(
                    // Use correct argument names, provide defaults
                    source: args?['source'] as String?,
                    sourceType:
                        args?['sourceType'] as PdfSourceType? ??
                        PdfSourceType.none,
                  ),
            );

          case '/pdf_details':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder:
                  (context) => PdfDetailsScreen(
                    pdfTitle: args?['title'] as String? ?? 'PDF Details',
                    pdfPath: args?['path'] as String?,
                  ),
            );

          case '/book_details':
            final book = settings.arguments as Book?;
            if (book != null) {
              return MaterialPageRoute(
                builder: (context) => BookDetailsScreen(book: book),
              );
            }

            return MaterialPageRoute(
              builder:
                  (context) => Scaffold(
                    body: Center(child: Text('Error: Book data missing')),
                  ),
            );

          default:
            return MaterialPageRoute(
              builder:
                  (context) => Scaffold(
                    appBar: AppBar(title: const Text('Error')),
                    body: const Center(child: Text('Page not found')),
                  ),
            );
        }
      },
    );
  }
}
