// main.dart

/*** |------------ Geecodex ------------|
 *   |      Author: @ppqwqqq            |
 *   |      Created At: 3 8 2025        |
 *   |    Hubei Engineering University  |
 *   |----------------------------------|
 */ 



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
  Widget build(BuildContext buildCtx) {
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
     // Startup Animation Screen
     home: const splash_screen(),
    );
  }
}
