// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localization.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Geecodex';

  @override
  String get searchHint => '搜索书籍、作者、类型...';

  @override
  String get favoritesTitle => '收藏';

  @override
  String get notesTitle => '我的笔记';

  @override
  String get profileTitle => '个人资料与设置';

  @override
  String get latestBooks => '最新书籍';

  @override
  String get continueReading => '继续阅读';

  @override
  String get browseAll => '查看全部';

  @override
  String get thisWeeksReading => '本周阅读时长';

  @override
  String get viewHistory => '查看历史';

  @override
  String get noFavoritesYet => '暂无收藏';

  @override
  String get addFavoritesHint => '请在书籍详情页点击心形图标添加收藏。';

  @override
  String get noNotesYet => '暂无笔记';

  @override
  String get notesHint => '您在书籍中的高亮和笔记将会显示在此处。下拉刷新。';

  @override
  String noResultsFound(String query) {
    return '未能找到与 \"$query\" 相关的结果';
  }

  @override
  String get removeFromFavorites => '从收藏中移除';

  @override
  String removeConfirmMsg(String fileName) {
    return '确定要将 \"$fileName\" 从收藏中移除吗？';
  }

  @override
  String get cancel => '取消';

  @override
  String get remove => '移除';

  @override
  String get editNotes => '编辑笔记';

  @override
  String get save => '保存';

  @override
  String page(String pageNumber) {
    return '第 $pageNumber 页';
  }

  @override
  String addedDateLabel(String date) {
    return '添加于: $date';
  }

  @override
  String get fileMissing => '文件丢失';
}
