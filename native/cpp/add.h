#ifndef ADD_H
#define ADD_H

#ifdef __cplusplus
extern "C" {
#endif

// 导出函数需要使用 extern "C" 防止名称修饰
int add(int a, int b);

#ifdef __cplusplus
}
#endif

#endif // ADD_H
