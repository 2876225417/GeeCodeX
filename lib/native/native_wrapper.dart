import 'native_bindings.dart';

class native_wrapper {
  static final native_wrapper _instance = native_wrapper._internal();

  final native_bindings _bindings = native_bindings();

  bool _initialized = false;

  factory native_wrapper() {
    return _instance;
  }

  native_wrapper._internal();

  void intialize() {
    if (!_initialized) {
      _bindings.initialize();
      _initialized = true;
    }
  }

  int add(int a, int b) {
    _ensure_intialized();
    return _bindings.add_int(a, b);
  }

  double add_double(double a, double b) {
    _ensure_intialized();
    return _bindings.add_double(a, b);
  }

  String test_opencv() {
    _ensure_intialized();
    return _bindings.qwq_opencv();
  }

  String test_onnxruntime() {
    _ensure_intialized();
    return _bindings.testOnnxruntimeApiVersion();
  }

  void _ensure_intialized() {
    if (!_initialized) {
      throw StateError(
        'Native libs are not initialized. Call initialze() first.',
      );
    }
  }
}
