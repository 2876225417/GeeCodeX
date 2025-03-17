

// lib/native/platform_specific.dart


import 'dart:io';


String get_native_library_name() {
         if (Platform.isAndroid) {
           return '__.so';
         } else if (Platform.isIOS)     return '__';
    else if (Platform.isMacOS)   return '__.dylib';
    else if (Platform.isWindows) return '__.dll';
    else if (Platform.isLinux)   return '__.so';
    
    throw UnsupportedError("Unsupported platform: ${Platform.operatingSystem}");
}
