// lib/widgets/bottom_nav.dart

import 'package:Geecodex/constants/index.dart';

import 'package:flutter/material.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

class ConvexBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const ConvexBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext buildCtx) {
    return ConvexAppBar(
      style: TabStyle.reactCircle,
      backgroundColor: AppColors.primary,
      activeColor: AppColors.accent,
      color: Colors.white,
      items: const [
        TabItem(icon: Icons.search, title: 'Search'),
        TabItem(icon: Icons.favorite, title: 'Favorite'),
        TabItem(icon: Icons.book, title: 'Read'),
        TabItem(icon: Icons.note, title: 'Note'),
        TabItem(icon: Icons.person, title: 'Profile'),
      ],
      initialActiveIndex: selectedIndex,
      onTap: onItemSelected,
    );
  }
}
