// main.dart

/*** |------------ Geecodex ------------|
 *   |      Author: @ppqwqqq            |
 *   |      Created At: 3 8 2025        |
 *   |    Hubei Engineering University  |
 *   |----------------------------------|
 */ 



import 'package:Geecodex/screens/book_browser/index.dart';
import 'package:Geecodex/screens/book_reader/index.dart';
import 'package:Geecodex/screens/book_reader/pdf_details_screen.dart';
import 'package:Geecodex/screens/book_reader/test_http_screen.dart';
import 'package:Geecodex/widgets/book_reader_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Geecodex/constants/index.dart';
import 'package:Geecodex/screens/splash_screen.dart';



void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle( 
    const SystemUiOverlayStyle( 
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const my_app());
}

class my_app extends StatelessWidget {
  const my_app({super.key});
  @override 
  Widget build(BuildContext build_ctx) {
    return MaterialApp( 
      title: 'Geecodex',
      debugShowMaterialGrid: false,
      theme: ThemeData( 
        colorScheme: ColorScheme.fromSeed(
          seedColor: app_colors.primary,
          primary: app_colors.primary,
          secondary: app_colors.accent,
          ),
          scaffoldBackgroundColor: app_colors.background,
          appBarTheme: const AppBarTheme( 
            backgroundColor: app_colors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (build_ctx) => const splash_screen(),
        '/home': (build_ctx) => const book_browser_screen(),
        '/reader': (build_ctx) => const reader_screen(),
        '/test_http': (build_ctx) => const TestHttpScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/pdf_details') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (build_ctx) => pdf_detail_screen(
            pdf_title: args?['title'],
            pdf_path:  args?['path'],
          ),
        );
      }
      return null;
     },
     // Startup Animation Screen
     // home: const splash_screen(),
    );
  }
}
