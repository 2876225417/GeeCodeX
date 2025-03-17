

// main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'constants/app_colors.dart';




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
     home: const home_screen(),
    );
  }
}
