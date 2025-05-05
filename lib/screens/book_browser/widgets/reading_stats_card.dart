// lib/screens/book_browser/widgets/reading_stats_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting if needed for goal period

// Import necessary services and screens
import 'package:Geecodex/services/reading_time_service.dart';
import 'package:Geecodex/screens/reading_heatmap/reading_heatmap_screen.dart';

// Helper function to format duration (can be moved to a utility file)
String _formatDuration(Duration duration) {
  if (duration.inMinutes < 1) {
    return "${duration.inSeconds} sec";
  } else if (duration.inHours < 1) {
    return "${duration.inMinutes} min";
  } else {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return "${hours}h ${minutes}m";
  }
}

class ReadingStatsCard extends StatefulWidget {
  // Changed to StatefulWidget to fetch data
  const ReadingStatsCard({super.key});

  @override
  State<ReadingStatsCard> createState() => _ReadingStatsCardState();
}

class _ReadingStatsCardState extends State<ReadingStatsCard> {
  Future<Duration>? _weeklyReadingTimeFuture;

  @override
  void initState() {
    super.initState();
    _weeklyReadingTimeFuture = _fetchWeeklyReadingTime();
  }

  // Fetch reading time for the current week (example implementation)
  Future<Duration> _fetchWeeklyReadingTime() async {
    final now = DateTime.now();
    // Calculate the start of the current week (assuming Sunday is the first day)
    // Adjust `weekday` check if your week starts on Monday (use `now.weekday - 1`)
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final startOfWeekDate = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    ); // Start at 00:00
    final endOfWeekDate = startOfWeekDate.add(
      const Duration(days: 7),
    ); // End just before next week starts

    print("Fetching reading time from $startOfWeekDate to $endOfWeekDate");
    return ReadingTimeService.getTotalReadingTime(
      startOfWeekDate,
      endOfWeekDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get theme data
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    const String weeklyGoalTitle = 'This Week\'s Reading'; // Updated title

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ), // Adjusted padding
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Use theme colors for gradient
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              Color.lerp(
                colorScheme.primary,
                colorScheme.primaryContainer,
                0.4,
              )!, // Blend primary colors
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16), // Slightly more rounded
          boxShadow: [
            BoxShadow(
              // Use theme shadow color
              color: colorScheme.shadow.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon with themed background
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.onPrimary.withOpacity(
                  0.1,
                ), // Subtle background on primary
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.timer_outlined, // Changed icon
                color: colorScheme.onPrimary, // Icon color contrast
                size: 36,
              ),
            ),
            const SizedBox(width: 16),
            // Text content using FutureBuilder
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center vertically
                children: [
                  Text(
                    weeklyGoalTitle,
                    style: textTheme.bodyMedium?.copyWith(
                      // Use theme text style
                      color: colorScheme.onPrimary.withOpacity(
                        0.8,
                      ), // Slightly transparent text
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Use FutureBuilder to display the fetched time
                  FutureBuilder<Duration>(
                    future: _weeklyReadingTimeFuture,
                    builder: (context, snapshot) {
                      String displayTime = "Loading..."; // Default text
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasError) {
                          displayTime = "Error";
                          print(
                            "Error fetching weekly time: ${snapshot.error}",
                          );
                        } else if (snapshot.hasData) {
                          // Format the duration fetched from the service
                          displayTime = _formatDuration(snapshot.data!);
                        } else {
                          displayTime = "0m"; // No data likely means 0 time
                        }
                      }
                      // Display the time (or loading/error state)
                      return Text(
                        displayTime,
                        style: textTheme.headlineSmall?.copyWith(
                          // Use theme text style
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8), // Space before button
            // "View History" Button
            OutlinedButton.icon(
              icon: Icon(
                Icons.calendar_month_outlined,
                size: 16,
                color: colorScheme.onPrimary,
              ),
              label: Text(
                'View History',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.onPrimary, // Text/Icon color
                backgroundColor: colorScheme.onPrimary.withOpacity(
                  0.1,
                ), // Subtle background
                side: BorderSide(
                  color: colorScheme.onPrimary.withOpacity(0.5),
                ), // Border color
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                visualDensity:
                    VisualDensity.compact, // Make button slightly smaller
              ),
              onPressed: () {
                // <<< Navigate to ReadingHeatmapScreen >>>
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReadingHeatmapScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
