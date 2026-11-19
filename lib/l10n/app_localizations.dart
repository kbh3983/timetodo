import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'TimeTodo'**
  String get appTitle;

  /// No description provided for @tabTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tabTasks;

  /// No description provided for @navTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get navTimeline;

  /// No description provided for @navCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get navCategory;

  /// No description provided for @tabInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get tabInsights;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @tabCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get tabCamera;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @proTitle.
  ///
  /// In en, this message translates to:
  /// **'TimeTodo Pro'**
  String get proTitle;

  /// No description provided for @proSubtitle.
  ///
  /// In en, this message translates to:
  /// **'An ad-free Pro version is coming soon!'**
  String get proSubtitle;

  /// No description provided for @proRemoveAds.
  ///
  /// In en, this message translates to:
  /// **'Remove All Ads'**
  String get proRemoveAds;

  /// No description provided for @proRemoveAdsDesc.
  ///
  /// In en, this message translates to:
  /// **'Enjoy an uninterrupted experience with zero ads.'**
  String get proRemoveAdsDesc;

  /// No description provided for @proComingSoonToast.
  ///
  /// In en, this message translates to:
  /// **'TimeTodo Pro (Ad-free version) will be available soon! 🚀'**
  String get proComingSoonToast;

  /// No description provided for @cheerDeveloperTitle.
  ///
  /// In en, this message translates to:
  /// **'Cheer the Developer'**
  String get cheerDeveloperTitle;

  /// No description provided for @cheerDeveloperSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Watch a short ad to support ongoing development and updates'**
  String get cheerDeveloperSubtitle;

  /// No description provided for @cheerThankYouTitle.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your warm support!'**
  String get cheerThankYouTitle;

  /// No description provided for @cheerThankYouSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your encouragement keeps us building a better app.'**
  String get cheerThankYouSubtitle;

  /// No description provided for @cheerAdLoading.
  ///
  /// In en, this message translates to:
  /// **'Preparing reward ad... Please try again in a moment.'**
  String get cheerAdLoading;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Support & Info'**
  String get settingsSupport;

  /// No description provided for @insightTimeStats.
  ///
  /// In en, this message translates to:
  /// **'Time Usage Stats'**
  String get insightTimeStats;

  /// No description provided for @insightTimeStatsDesc.
  ///
  /// In en, this message translates to:
  /// **'Analyze elapsed time and share by category'**
  String get insightTimeStatsDesc;

  /// No description provided for @insight24hPattern.
  ///
  /// In en, this message translates to:
  /// **'24-Hour Activity Pattern'**
  String get insight24hPattern;

  /// No description provided for @insight24hPatternDesc.
  ///
  /// In en, this message translates to:
  /// **'See when you are most active throughout the day'**
  String get insight24hPatternDesc;

  /// No description provided for @insightWeeklyPattern.
  ///
  /// In en, this message translates to:
  /// **'Weekly Activity Pattern'**
  String get insightWeeklyPattern;

  /// No description provided for @insightWeeklyPatternDesc.
  ///
  /// In en, this message translates to:
  /// **'Compare activity frequency between weekdays and weekends'**
  String get insightWeeklyPatternDesc;

  /// No description provided for @insightTodoCompletion.
  ///
  /// In en, this message translates to:
  /// **'Task Completion Rate'**
  String get insightTodoCompletion;

  /// No description provided for @insightTodoCompletionDesc.
  ///
  /// In en, this message translates to:
  /// **'Track your completion speed and goal achievement'**
  String get insightTodoCompletionDesc;

  /// No description provided for @insightRanking.
  ///
  /// In en, this message translates to:
  /// **'Top Activities'**
  String get insightRanking;

  /// No description provided for @insightRankingDesc.
  ///
  /// In en, this message translates to:
  /// **'Top 5 activities you invested the most time in'**
  String get insightRankingDesc;

  /// No description provided for @insightMonthlyTable.
  ///
  /// In en, this message translates to:
  /// **'Monthly Timeline'**
  String get insightMonthlyTable;

  /// No description provided for @insightMonthlyTableDesc.
  ///
  /// In en, this message translates to:
  /// **'Days (1-31) × 24-hour activity timeline'**
  String get insightMonthlyTableDesc;

  /// No description provided for @insightWeeklyTable.
  ///
  /// In en, this message translates to:
  /// **'Weekly Matrix'**
  String get insightWeeklyTable;

  /// No description provided for @insightWeeklyTableDesc.
  ///
  /// In en, this message translates to:
  /// **'Days of week × time slot activity matrix'**
  String get insightWeeklyTableDesc;

  /// No description provided for @insightCalendar.
  ///
  /// In en, this message translates to:
  /// **'Activity Calendar'**
  String get insightCalendar;

  /// No description provided for @insightCalendarDesc.
  ///
  /// In en, this message translates to:
  /// **'Review monthly consistency and daily detailed logs'**
  String get insightCalendarDesc;

  /// No description provided for @todoInputHint.
  ///
  /// In en, this message translates to:
  /// **'What are you doing right now?'**
  String get todoInputHint;

  /// No description provided for @todoEmptyList.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet. Start by adding one!'**
  String get todoEmptyList;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
