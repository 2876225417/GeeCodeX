
import 'dart:ffi';
import 'dart:io';

class native_bindings {
    static final native_bindings _instance = native_bindings._internal();

    factory native_bindings() { return _instance; }

    native_bindings._internal();

    late final DynamicLibrary _native_lib;
    
    late final int Function(int a, int b) add_int;

    late final double Function(double a, double b) add_double;
    
    void initialize() {
        _native_lib = _load_library();
        
        add_int = _native_lib
                        .lookup<NativeFunction<Int32 Function(Int32, Int32)>>('qwq_add_int')
                        .asFunction();

        add_double = _native_lib
                        .lookup<NativeFunction<Double Function(Double, Double)>>('qwq_add_double')
                        .asFunction();
    }

    DynamicLibrary _load_library() {
                 if (Platform.isAndroid) { return DynamicLibrary.open("libadd.so"); }
            else if (Platform.isIOS)     { return DynamicLibrary.process(); }
            else if (Platform.isWindows) { return DynamicLibrary.open("libadd.dll"); }
            else if (Platform.isMacOS)   { return DynamicLibrary.open("libadd.dylib"); }
            else if (Platform.isLinux)   { return DynamicLibrary.open('libadd.so'); }
       throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}'); 
    }


}
