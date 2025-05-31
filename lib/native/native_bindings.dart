import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:ffi/ffi.dart';

typedef _QwQOpenCVNativeSignature = Pointer<Utf8> Function();
typedef _QwQOpenCVDartPointerFunction = Pointer<Utf8> Function();

// --- 【新增】为 ONNXRuntime 测试函数定义的类型别名 ---
typedef _TestONNXRuntimeApiVersionNativeSignature = Pointer<Utf8> Function();
typedef _TestONNXRuntimeApiVersionDartPointerFunction =
    Pointer<Utf8> Function();

class native_bindings {
  static final native_bindings _instance = native_bindings._internal();

  factory native_bindings() {
    return _instance;
  }

  native_bindings._internal();

  late final DynamicLibrary _native_lib;

  late final int Function(int a, int b) add_int;

  late final double Function(double a, double b) add_double;

  late final _QwQOpenCVDartPointerFunction _qwq_opencv_native_call;

  late final String Function() qwq_opencv;

  late final _TestONNXRuntimeApiVersionDartPointerFunction
  _test_onnxruntime_native_call;
  late final String Function() testOnnxruntimeApiVersion; // 与 C++ 函数名对应

  void initialize() {
    _native_lib = _load_library();

    add_int =
        _native_lib
            .lookup<NativeFunction<Int32 Function(Int32, Int32)>>('qwq_add_int')
            .asFunction();

    add_double =
        _native_lib
            .lookup<NativeFunction<Double Function(Double, Double)>>(
              'qwq_add_double',
            )
            .asFunction();

    _qwq_opencv_native_call =
        _native_lib
            .lookup<NativeFunction<_QwQOpenCVNativeSignature>>('qwq_opencv')
            .asFunction<_QwQOpenCVDartPointerFunction>();

    qwq_opencv = () {
      final Pointer<Utf8> resultPointer = _qwq_opencv_native_call();
      if (resultPointer.address == nullptr) {
        return "Error: Native function 'qwq_opencv' returned a null pointer.";
      }
      return resultPointer.toDartString();
    };

    // --- 【新增】初始化 testOnnxruntimeApiVersion ---
    _test_onnxruntime_native_call =
        _native_lib
            .lookup<NativeFunction<_TestONNXRuntimeApiVersionNativeSignature>>(
              'qwq_onnxruntime',
            ) // C++ 中导出的函数名
            .asFunction<_TestONNXRuntimeApiVersionDartPointerFunction>();

    testOnnxruntimeApiVersion = () {
      final Pointer<Utf8> resultPointer = _test_onnxruntime_native_call();
      if (resultPointer.address == nullptr) {
        return "错误: 原生函数 'test_onnxruntime_api_version' 返回了空指针。";
      }
      return resultPointer.toDartString();
    };
  }

  DynamicLibrary _load_library() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open("libqwq_books_native.so");
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    } else if (Platform.isWindows) {
      return DynamicLibrary.open("libqwq_books_native.dll");
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open("libqwq_books_native.dylib");
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libqwq_books_native.so');
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }
}
