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
import 'native/native_wrapper.dart';

void main() {
  native_wrapper().intialize();
  runApp(const books_qwq());
}

class books_qwq extends StatelessWidget {
  const books_qwq({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Native Lib Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true
      ),
      home: const home_page(title: 'Native Lib Demo'),
    );
  }
}

class home_page extends StatefulWidget {
  const home_page({super.key, required this.title});

  final String title;

  @override
  State<home_page> createState() => _home_page_state();
}

class _home_page_state extends State<home_page> {
  final TextEditingController _a_controller = TextEditingController();
  final TextEditingController _b_controller = TextEditingController();

  String _int_result = '';
  String _double_result = '';

  final native_wrapper _native_wrapper = native_wrapper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Native Lib Add Demo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _a_controller,
                    decoration: const InputDecoration(
                       labelText: 'Value A',
                       border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _b_controller,
                    decoration: const InputDecoration(
                      labelText: 'Value B',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _calculate_int_add,
                  child: const Text("Integer Add"),
                ),
                ElevatedButton(
                  onPressed: _calculate_double_add,
                  child: const Text('Double Add'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Integer Result: $_int_result',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              'Double Result: $_double_result',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }

  void _calculate_int_add() {
    try {
      final int a = int.parse(_a_controller.text);
      final int b = int.parse(_b_controller.text);
      final int result = _native_wrapper.add(a, b);
      setState(() {
        _int_result = result.toString();  
      });
    } catch (e) {
      setState(() {
        _int_result = 'Error: ${e.toString()}';
      });
    }
  }

  void _calculate_double_add() {
    try {
      final double a = double.parse(_a_controller.text);
      final double b = double.parse(_b_controller.text);
      final double result = _native_wrapper.add_double(a, b);
      setState(() {
        _double_result = result.toStringAsFixed(2);
      });
    } catch (e) {
      setState(() {
        _double_result = 'Error: ${e.toString()}';        
      });
    }
  }

  @override
  void dispose() {
    _a_controller.dispose();
    _b_controller.dispose();
    super.dispose();
  }
}



