// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localization.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Geecodex';

  @override
  String get searchHint => 'Search books, authors, genres...';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get notesTitle => 'My Notes';

  @override
  String get profileTitle => 'Profile & Settings';

  @override
  String get latestBooks => 'Latest Books';

  @override
  String get continueReading => 'Continue Reading';

  @override
  String get browseAll => 'Browse All';

  @override
  String get thisWeeksReading => 'This Week\'s Reading';

  @override
  String get viewHistory => 'View History';

  @override
  String get noFavoritesYet => 'No Favorites Yet';

  @override
  String get addFavoritesHint =>
      'Add books to your favorites from the details screen using the heart icon.';

  @override
  String get noNotesYet => 'No Notes Yet';

  @override
  String get notesHint =>
      'Your highlights and notes from books will appear here. Pull down to refresh.';

  @override
  String noResultsFound(String query) {
    return 'No results found for \"$query\"';
  }

  @override
  String get removeFromFavorites => 'Remove from Favorites';

  @override
  String removeConfirmMsg(String fileName) {
    return 'Remove \"$fileName\" from favorites?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String get editNotes => 'Edit Notes';

  @override
  String get save => 'Save';

  @override
  String page(String pageNumber) {
    return 'Page $pageNumber';
  }

  @override
  String addedDateLabel(String date) {
    return 'Added: $date';
  }

  @override
  String get fileMissing => 'File missing';
}
