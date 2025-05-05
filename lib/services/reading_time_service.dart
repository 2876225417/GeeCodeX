// lib/services/reading_time_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ReadingTimeService {
  static const String _prefix = 'reading_time_'; // Prefix for keys

  // Gets the storage key for a specific date
  static String _getKeyForDate(DateTime date) {
    // Format date as YYYY-MM-DD for consistent keys
    final formatter = DateFormat('yyyy-MM-dd');
    return '$_prefix${formatter.format(date)}';
  }

  // Adds reading duration for the current day
  static Future<void> addReadingDuration(Duration duration) async {
    if (duration.inSeconds <= 0) return; // Don't save zero/negative time

    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final key = _getKeyForDate(today);

      // Get existing duration for today (or 0)
      final int existingSeconds = prefs.getInt(key) ?? 0;
      final int newTotalSeconds = existingSeconds + duration.inSeconds;

      // Save the updated total seconds
      await prefs.setInt(key, newTotalSeconds);
      print(
        "ReadingTimeService: Added ${duration.inSeconds}s for $key. New total: $newTotalSeconds",
      );
    } catch (e) {
      print("Error saving reading duration: $e");
      // Handle error appropriately
    }
  }

  // Gets reading data formatted for the heatmap package
  // Returns a map where DateTime is the date and int is the intensity (e.g., 1-5) or total seconds.
  // Let's return total seconds for now, the heatmap can often handle ranges.
  static Future<Map<DateTime, int>> getReadingDataForHeatmap() async {
    final Map<DateTime, int> datasets = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      final dateKeys = keys.where((key) => key.startsWith(_prefix));

      for (final key in dateKeys) {
        final dateString = key.substring(_prefix.length);
        try {
          final date = DateFormat('yyyy-MM-dd').parseStrict(dateString);
          final seconds = prefs.getInt(key) ?? 0;
          if (seconds > 0) {
            // You might want to convert seconds to an intensity level (1-5) here
            // Example mapping (adjust thresholds as needed):
            // int intensity = seconds > 3600 ? 5 : (seconds > 1800 ? 4 : (seconds > 900 ? 3 : (seconds > 300 ? 2 : 1)));
            // datasets[date] = intensity;

            // For simplicity, let's pass raw seconds (heatmap might handle this)
            datasets[date] = seconds;
          }
        } catch (e) {
          print("Error parsing date or value for key $key: $e");
          // Skip invalid keys/dates
        }
      }
      print(
        "ReadingTimeService: Fetched ${datasets.length} data points for heatmap.",
      );
      return datasets;
    } catch (e) {
      print("Error getting reading data: $e");
      return {}; // Return empty map on error
    }
  }

  // --- Optional: Helper to get total reading time for a period ---
  static Future<Duration> getTotalReadingTime(
    DateTime start,
    DateTime end,
  ) async {
    int totalSeconds = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final dateKeys = keys.where((key) => key.startsWith(_prefix));
      final formatter = DateFormat('yyyy-MM-dd');

      for (final key in dateKeys) {
        final dateString = key.substring(_prefix.length);
        try {
          final date = formatter.parseStrict(dateString);
          // Check if the date falls within the specified range (inclusive)
          if (!date.isBefore(start) && !date.isAfter(end)) {
            totalSeconds += prefs.getInt(key) ?? 0;
          }
        } catch (e) {
          /* Skip invalid keys */
        }
      }
    } catch (e) {
      print("Error getting total reading time: $e");
    }
    return Duration(seconds: totalSeconds);
  }
}
