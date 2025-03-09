import 'dart:ffi';
import 'dart:io';

// 定义 C 函数类型
typedef AddFunc = Int32 Function(Int32 a, Int32 b);
// 定义对应的 Dart 函数类型
typedef AddFuncDart = int Function(int a, int b);

class AddLib {
  static final AddLib _instance = AddLib._internal();
  late AddFuncDart _add;

  factory AddLib() {
    return _instance;
  }

  AddLib._internal() {
    // 加载动态库
    final DynamicLibrary lib = _loadLibrary();
    
    // 查找并链接 add 函数
    _add = lib
        .lookupFunction<AddFunc, AddFuncDart>('add');
  }

  DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libadd.so');
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libadd.so');
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('add.dll');
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('libadd.dylib');
    } else {
      throw UnsupportedError('不支持的平台: ${Platform.operatingSystem}');
    }
  }

  // 暴露给 Dart 的函数
  int add(int a, int b) {
    return _add(a, b);
  }
}
