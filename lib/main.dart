// lib/main.dart

/*** |------------ Geecodex ------------|
 *   |      Author: @ppqwqqq            |
 *   |      Created At: 3 8 2025        |
 *   |    Hubei Engineering University  |
 *   |----------------------------------|
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import constants using the index file
import 'package:Geecodex/constants/index.dart';

// Import screens using index files where available
import 'package:Geecodex/screens/splash_screen.dart';
import 'package:Geecodex/screens/screen_framework.dart'; // Assuming this is your main layout screen
import 'package:Geecodex/screens/book_reader/index.dart'; // Imports ReaderScreen
import 'package:Geecodex/screens/book_reader/pdf_details_screen.dart';
import 'package:Geecodex/screens/book_reader/test_http_screen.dart';
// Import ReaderScreen specific widgets if needed globally (unlikely)
// import 'package:Geecodex/widgets/book_reader_builder.dart'; // This seems unused here

import 'package:Geecodex/screens/book_reader/widgets/pdf_viewer_wrapper.dart';
import 'package:Geecodex/models/book.dart';
import 'package:Geecodex/screens/book_details/book_details_screen.dart';

import 'package:Geecodex/native/native_wrapper.dart';

void main() {
  final wrapper = native_wrapper();
  wrapper.intialize();
  double sum = wrapper.add_double(10, 10);
  String test = wrapper.test_opencv();
  print("Sum of 10 and 10: $sum");
  print(test);
  WidgetsFlutterBinding.ensureInitialized();
  // Setting system UI overlay style is good practice
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Make status bar transparent
      statusBarIconBrightness:
          Brightness.dark, // Icons dark on light background
      // For dark mode, you might want Brightness.light here, potentially set dynamically
    ),
  );
  runApp(const MyApp()); // Use UpperCamelCase
}

// Renamed class to UpperCamelCase
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Renamed parameter
    return MaterialApp(
      title: 'Geecodex',
      // debugShowMaterialGrid: false, // Keep false for production
      debugShowCheckedModeBanner: false, // Hide debug banner
      // --- Theme Setup ---
      theme: ThemeData(
        // Light Theme
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary, // Use constant from index
          primary: AppColors.primary,
          secondary: AppColors.accent,
          background: AppColors.background, // Define background in scheme
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white, // Color for icons and text
          elevation: 0, // Flat AppBar
          systemOverlayStyle:
              SystemUiOverlayStyle.light, // Icons light on dark AppBar
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        // Dark Theme (Optional but recommended)
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary, // Or a darker shade if preferred
          secondary: AppColors.accent,
          background: Colors.grey[900]!, // Example dark background
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.grey[900]!,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[850]!, // Darker AppBar
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle:
              SystemUiOverlayStyle.light, // Icons light on dark AppBar
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // Respect system setting
      // --- Routing ---
      initialRoute: '/', // Start with splash screen
      routes: {
        // Static routes (those without arguments or simple ones)
        '/': (context) => const SplashScreen(),
        // '/home': (context) => const BookBrowserScreen(), // Example if needed
        '/framework':
            (context) =>
                const ScreenFramework(), // Your main screen after splash
        '/test_http': (context) => const TestHttpScreen(),
        // '/reader' is removed - navigate using Navigator.pushNamed with arguments
      },
      onGenerateRoute: (settings) {
        // Handle routes that need arguments or complex logic
        switch (settings.name) {
          case '/reader':
            // Arguments should be passed via Navigator.pushNamed
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
                    // Use correct class name
                    // Use correct argument names, provide defaults
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

          // Add other dynamic routes here if necessary
          // case '/some_other_screen':
          //    ...

          default:
            // Handle unknown routes, e.g., show a 404 page
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
