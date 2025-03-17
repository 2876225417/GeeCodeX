

// lib/widgets/bottom_nav.dart

import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import '../constants/app_colors.dart';

class convex_bottom_nav_bar extends StatelessWidget {
  final int selected_idx;
  final Function(int) on_item_selected;

  const convex_bottom_nav_bar({
    super.key,
    required this.selected_idx,
    required this.on_item_selected,
  });

  @override 
  Widget build(BuildContext buildCtx) {
    return ConvexAppBar(
      style: TabStyle.reactCircle,
      backgroundColor: app_colors.primary,
      activeColor: app_colors.accent,
      color: Colors.white,
      items: const [
        TabItem(icon: Icons.search, title: 'Search'),
        TabItem(icon: Icons.favorite, title: 'Favorite'),
        TabItem(icon: Icons.book, title: 'Read'),
        TabItem(icon: Icons.note, title: 'Note'),
        TabItem(icon: Icons.person, title: 'Profile'),
      ],
      initialActiveIndex: selected_idx,
      onTap: on_item_selected,
    );
  }


}



