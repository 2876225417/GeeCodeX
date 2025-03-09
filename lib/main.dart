// import 'package:flutter/material.dart';
// import 'package:curved_navigation_bar/curved_navigation_bar.dart';
//
// void main() => runApp(MyApp());
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Books QWQ',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: HomePage(),
//     );
//   }
// }
//
// class HomePage extends StatefulWidget {
//   @override
//   _HomePageState createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   int _selectedIndex = 0;
//   
//   static List<Widget> _pages = <Widget>[
//     Center(child: Text('首页', style: TextStyle(fontSize: 24))),
//     Center(child: Text('书架', style: TextStyle(fontSize: 24))),
//     Center(child: Text('发现', style: TextStyle(fontSize: 24))),
//     Center(child: Text('我的', style: TextStyle(fontSize: 24))),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Books QWQ'),
//       ),
//       body: _pages[_selectedIndex],
//       bottomNavigationBar: CurvedNavigationBar(
//         backgroundColor: Colors.white,
//         color: Colors.blue,
//         buttonBackgroundColor: Colors.blue,
//         height: 60,
//         animationDuration: Duration(milliseconds: 300),
//         index: _selectedIndex,
//         onTap: (index) {
//           setState(() {
//             _selectedIndex = index;
//           });
//         },
//         items: <Widget>[
//           Icon(Icons.home, size: 30, color: Colors.white),
//           Icon(Icons.book, size: 30, color: Colors.white),
//           Icon(Icons.explore, size: 30, color: Colors.white),
//           Icon(Icons.person, size: 30, color: Colors.white),
//         ],
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'add_lib.dart';
import 'native_bindings.dart';
 
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '直接加载 C++ 库示例',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}




class _MyHomePageState extends State<MyHomePage> {
  final AddLib _addLib = AddLib();
  final TextEditingController _aController = TextEditingController();
  final TextEditingController _bController = TextEditingController();
  int _result = 0;

  void _calculateSum() {
    final int a = int.tryParse(_aController.text) ?? 0;
    final int b = int.tryParse(_bController.text) ?? 0;
    
    setState(() {
      _result = 
      _result = _addLib.add(a, b);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('直接加载 C++ 库示例'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _aController,
              decoration: const InputDecoration(labelText: '输入 a'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _bController,
              decoration: const InputDecoration(labelText: '输入 b'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _calculateSum,
              child: const Text('计算 a + b'),
            ),
            const SizedBox(height: 20),
            Text(
              '结果: $_result',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}
