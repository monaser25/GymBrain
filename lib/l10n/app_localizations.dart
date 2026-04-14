import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
    Locale('en'),
  ];

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'GYM BRAIN'**
  String get appName;

  /// Label for language selection
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Arabic language name
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// Title for language selection screen
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Continue button label
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @toolsAndUtilities.
  ///
  /// In en, this message translates to:
  /// **'Tools & Utilities'**
  String get toolsAndUtilities;

  /// No description provided for @oneRmCalculator.
  ///
  /// In en, this message translates to:
  /// **'1RM Calculator'**
  String get oneRmCalculator;

  /// No description provided for @plateCalculator.
  ///
  /// In en, this message translates to:
  /// **'Plate Calculator'**
  String get plateCalculator;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get version;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @workout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workout;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @noWorkoutsYet.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet'**
  String get noWorkoutsYet;

  /// No description provided for @currentWeight.
  ///
  /// In en, this message translates to:
  /// **'Current Weight'**
  String get currentWeight;

  /// No description provided for @lastWorkout.
  ///
  /// In en, this message translates to:
  /// **'Last Workout'**
  String get lastWorkout;

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'START\nWORKOUT'**
  String get startWorkout;

  /// No description provided for @savedRoutines.
  ///
  /// In en, this message translates to:
  /// **'Saved Routines'**
  String get savedRoutines;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @noRoutinesYet.
  ///
  /// In en, this message translates to:
  /// **'No routines yet. Create one!'**
  String get noRoutinesYet;

  /// No description provided for @exercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercises;

  /// No description provided for @selectRoutine.
  ///
  /// In en, this message translates to:
  /// **'Select Routine'**
  String get selectRoutine;

  /// No description provided for @noRoutinesFound.
  ///
  /// In en, this message translates to:
  /// **'No routines found.\nCreate one in the Workout tab!'**
  String get noRoutinesFound;

  /// No description provided for @resumeWorkout.
  ///
  /// In en, this message translates to:
  /// **'Resume Workout'**
  String get resumeWorkout;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @workoutActive.
  ///
  /// In en, this message translates to:
  /// **'Workout Active'**
  String get workoutActive;

  /// No description provided for @minimizeWorkoutQuery.
  ///
  /// In en, this message translates to:
  /// **'Do you want to minimize the workout (keep running) or end it (discard part)?\nUse \'Finish\' button to save.'**
  String get minimizeWorkoutQuery;

  /// No description provided for @minimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get minimize;

  /// No description provided for @endDiscard.
  ///
  /// In en, this message translates to:
  /// **'End (Discard)'**
  String get endDiscard;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed:'**
  String get completed;

  /// No description provided for @restTimeStr.
  ///
  /// In en, this message translates to:
  /// **'Rest:'**
  String get restTimeStr;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get skip;

  /// No description provided for @finishWorkoutQuest.
  ///
  /// In en, this message translates to:
  /// **'Finish Workout?'**
  String get finishWorkoutQuest;

  /// No description provided for @readyToComplete.
  ///
  /// In en, this message translates to:
  /// **'Are you ready to complete this session?'**
  String get readyToComplete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @finishWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'FINISH WORKOUT'**
  String get finishWorkoutTitle;

  /// No description provided for @loadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Loading history...'**
  String get loadingHistory;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history'**
  String get noHistory;

  /// No description provided for @lastPer.
  ///
  /// In en, this message translates to:
  /// **'Last:'**
  String get lastPer;

  /// No description provided for @weightLabel.
  ///
  /// In en, this message translates to:
  /// **'WEIGHT'**
  String get weightLabel;

  /// No description provided for @repsLabel.
  ///
  /// In en, this message translates to:
  /// **'REPS'**
  String get repsLabel;

  /// No description provided for @rpeEffort.
  ///
  /// In en, this message translates to:
  /// **'RPE (EFFORT 1-10)'**
  String get rpeEffort;

  /// No description provided for @spotterAssisted.
  ///
  /// In en, this message translates to:
  /// **'Spotter Assisted?'**
  String get spotterAssisted;

  /// No description provided for @markIfHelped.
  ///
  /// In en, this message translates to:
  /// **'Mark if someone helped you'**
  String get markIfHelped;

  /// No description provided for @dropSet.
  ///
  /// In en, this message translates to:
  /// **'Drop Set?'**
  String get dropSet;

  /// No description provided for @weightLowered.
  ///
  /// In en, this message translates to:
  /// **'Weight lowered immediately'**
  String get weightLowered;

  /// No description provided for @completeSet.
  ///
  /// In en, this message translates to:
  /// **'COMPLETE SET'**
  String get completeSet;

  /// No description provided for @drop.
  ///
  /// In en, this message translates to:
  /// **'DROP'**
  String get drop;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
