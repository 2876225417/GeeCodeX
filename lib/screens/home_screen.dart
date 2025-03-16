

// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';


import '../pages/home_page.dart';

class home_screen extends StatefulWidget {
    const home_screen({Key? key}) : super(key: key);

    @override 
    State<home_screen> createState() => _home_screen_state();
}

class _home_screen_state extends State<home_screen> {
    int _selected_idx = 0;

    final List<Widget> _pages = [
       const home_page(),
       //const Center(child: Text("HomePage")),
       const Center(child: Text('search')),
       const Center(child: Text('Add')),
       const Center(child: Text('Favorite')),
       const Center(child: Text('Profile')),
    ];

    void _on_item_tapped(int idx) {
        setState(() {
            _selected_idx = idx;
        });
    }

    @override 
    Widget build(BuildContext context) {
        return Scaffold( 
            body: _pages[_selected_idx],
            bottomNavigationBar: convex_bottom_nav_bar( 
                selected_idx: _selected_idx,
                on_item_selected: _on_item_tapped, 
            ),
        );
    }
}
