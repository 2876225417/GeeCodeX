# 编译依赖脚本

构建平台 **Android** **Linux**

针对 **Android** 平台的 **ABI**:
    * armeabi-v7a
    * arm64-v8a
    * x86
    * x86_64

针对 **Linux** 平台的 **ABI**:
    * x86_64

构建 **Linux** 平台的依赖是因为 **Android** 和 **Linux** 的 **ABI** 不同，编译生成的**Android**的依赖无法在**x86_64**架构的处理器机器上运行，所以需要针对该架构单独编译一个版本，以用于后面的测试。

## OpenCV

## ONNXRuntime

## Boost

## fmt

## Eigen3


