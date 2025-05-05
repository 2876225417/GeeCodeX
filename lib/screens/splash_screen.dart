// lib/screens/splash_screen.dart

import 'dart:async'; // Import for Future.delayed
import 'dart:math'; // Import for pi

import 'package:flutter/material.dart';
import 'package:Geecodex/screens/screen_framework.dart'; // Assuming correct path

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _angleAnimation; // Controls the opening angle
  late Animation<double> _textFadeAnimation; // Controls text fade-in

  // Define the delay duration
  final Duration _initialDelay = const Duration(
    milliseconds: 1300,
  ); // 0.5 seconds

  @override
  void initState() {
    super.initState();

    // Keep the total desired visual animation duration (e.g., the book opening + text fade)
    const visualAnimationDuration = Duration(
      milliseconds: 3400,
    ); // e.g., 2.5 seconds for visible animation
    // The controller's duration will be the delay + visual duration
    final totalControllerDuration = _initialDelay + visualAnimationDuration;

    _controller = AnimationController(
      duration: totalControllerDuration,
      vsync: this,
    );

    // --- Calculate Interval Timings ---
    // Convert durations to fractions of the total controller duration
    final double delayFraction =
        _initialDelay.inMilliseconds / totalControllerDuration.inMilliseconds;
    // The book opening should happen *after* the delay.
    // Let's say it takes 70% of the *remaining* time (visualAnimationDuration)
    final double openingStarts = delayFraction; // Start after the delay
    final double openingDurationFraction =
        (visualAnimationDuration.inMilliseconds * 0.7) /
        totalControllerDuration.inMilliseconds;
    final double openingEnds = openingStarts + openingDurationFraction;

    // The text fade should also happen after the delay.
    // Let's say it starts halfway through the visual animation and ends at the total end.
    final double textFadeStarts =
        delayFraction +
        (visualAnimationDuration.inMilliseconds * 0.5) /
            totalControllerDuration.inMilliseconds;
    final double textFadeEnds = 1.0; // End at the very end of the controller

    print("Total Duration: ${totalControllerDuration.inMilliseconds}ms");
    print("Delay Fraction: $delayFraction");
    print("Opening Interval: $openingStarts -> $openingEnds");
    print("Text Fade Interval: $textFadeStarts -> $textFadeEnds");

    // Book Opening Animation - uses the calculated interval
    _angleAnimation = Tween<double>(begin: 0.0, end: -pi * 0.85).animate(
      CurvedAnimation(
        parent: _controller,
        // ***** MODIFIED INTERVAL *****
        curve: Interval(
          openingStarts, // Start after the delay fraction
          openingEnds.clamp(
            0.0,
            1.0,
          ), // End after its duration, ensure it's within [0,1]
          curve: Curves.easeInOutCubic,
        ),
        // ***************************
      ),
    );

    // Text Fade-In Animation - uses the calculated interval
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        // ***** MODIFIED INTERVAL *****
        curve: Interval(
          textFadeStarts.clamp(0.0, 1.0), // Start later, ensure within [0,1]
          textFadeEnds, // End at the controller's end
          curve: Curves.easeIn,
        ),
        // ***************************
      ),
    );

    _startAnimationAndNavigation();
  }

  void _startAnimationAndNavigation() {
    // No need for Future.delayed here, the delay is built into the Intervals

    _controller.forward(); // Start the controller immediately

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          // Navigation happens after the *entire* controller duration (including delay)
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const ScreenFramework(),
              transitionsBuilder:
                  (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final Size screenSize = MediaQuery.of(context).size;
    // Adjust size as needed - maybe slightly wider?
    final double bookWidth = screenSize.width * 0.35;
    final double bookHeight = bookWidth * 1.4; // Keep aspect ratio

    return Scaffold(
      backgroundColor: colorScheme.surface, // Changed background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Animated Book ---
            Padding(
              padding: const EdgeInsets.only(left: 100),
              // padding: EdgeInsets.zero, // Use center alignment
              child: SizedBox(
                width: bookWidth * 2, // We need space for both halves
                height: bookHeight,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Stack(
                      alignment:
                          Alignment.center, // Align stack items centrally
                      children: [
                        // --- Back Page (Static) ---
                        Positioned(
                          left: bookWidth / 2, // Start at the center hinge
                          top: 0,
                          bottom: 0,
                          width: bookWidth, // Width of one page
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.brown[100], // Page color
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                                topLeft: Radius.zero, // Explicitly zero
                                bottomLeft: Radius.zero, // Explicitly zero
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 5,
                                  offset: const Offset(
                                    2,
                                    2,
                                  ), // Shadow to the right
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 15.0,
                              ), // Shift content right
                              child: Icon(
                                Icons.menu_book,
                                color: Colors.brown[300],
                                size: bookHeight * 0.4,
                              ),
                            ),
                          ),
                        ),

                        // --- Front Cover (Animated) ---
                        Positioned(
                          left: bookWidth / 2, // Start at the center hinge
                          top: 0,
                          bottom: 0,
                          width: bookWidth, // Width of one page
                          child: Transform(
                            alignment: Alignment.centerLeft,
                            transform:
                                Matrix4.identity()
                                  ..setEntry(3, 2, 0.001) // Perspective
                                  ..rotateY(
                                    -_angleAnimation.value,
                                  ), // Rotate outwards
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.primary, // Book cover color
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(
                                    10,
                                  ), // Round this corner
                                  bottomRight: Radius.circular(
                                    10,
                                  ), // Round this corner
                                  topLeft: Radius.zero, // Sharp corner (hinge)
                                  bottomLeft:
                                      Radius.zero, // Sharp corner (hinge)
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              alignment: Alignment.center,
                              child: Image.asset(
                                'assets/star.jpg', // **REPLACE with your actual book cover asset**
                                fit:
                                    BoxFit
                                        .cover, // Ensure image covers the container
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback if image fails
                                  return Center(
                                    child: Text(
                                      'CodeX', // Changed fallback text
                                      style: TextStyle(
                                        fontSize: bookHeight * 0.2,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onPrimary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 40), // Adjusted spacing
            // --- Animated Text (Fade In) ---
            FadeTransition(
              opacity: _textFadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Geecodex',
                    style: textTheme.displaySmall?.copyWith(
                      color: colorScheme.primary, // Match cover color
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A Codex for Geeks',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
