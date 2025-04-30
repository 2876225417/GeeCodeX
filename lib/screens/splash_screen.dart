


// lib/screens/splash_screen.dart

/*** App Startup Animation
 *   
 *   
 *   
 */

import 'package:flutter/material.dart';
import 'package:Geecodex/screens/screen_framework.dart';
import 'package:Geecodex/constants/index.dart';

class splash_screen extends StatefulWidget {
  const splash_screen({Key? key}) : super(key: key);

  @override
  _splash_screen_state createState() => _splash_screen_state();
}

class _splash_screen_state extends State<splash_screen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Creating animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Fade-in Animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );
    
    // Scale Animation
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );
    
    // Startup Animation
    _controller.forward();
    
    // Navigate to homepage after animation
    Future.delayed(const Duration(milliseconds: 2500), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => screen_framework()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: app_colors.primary, 
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/star.jpg', 
                      width: 120,
                      height: 120,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.menu_book,
                          size: 100,
                          color: Colors.white,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Geecodex',
                      style: app_text_styles.heading.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A Codex for Geek',
                      // style: app_text_styles.body.copyWith(
                      //   color: Colors.white70,
                      //   fontSize: 16,
                      // ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}