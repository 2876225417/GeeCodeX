

import 'dart:ffi';
import 'dart:io';


final DynamicLibrary native_lib = Platform.isAndroid
    ? DynamicLibrary.open("libadd.so")
    : DynamicLibrary.process();


typedef add_int = int Function(int a, int b);
typedef add_int_native = Int32 Function(Int32 a, Int32 b);

typedef add_double = double Function(double a, double b);
typedef add_double_native = Double Function(Double a, Double b);

final add_int add_Int = native_lib
    .lookup<NativeFunction<add_int_native>>('qwq_add_int')
    .asFunction<add_int>();


final add_double add_Double = native_lib
    .lookup<NativeFunction<add_double_native>>('qwq_add_double')

    .asFunction<add_double>();

