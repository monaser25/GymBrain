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

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @kgUnit.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kgUnit;

  /// No description provided for @lbUnit.
  ///
  /// In en, this message translates to:
  /// **'lb'**
  String get lbUnit;

  /// No description provided for @exerciseLibrary.
  ///
  /// In en, this message translates to:
  /// **'Exercise Library'**
  String get exerciseLibrary;

  /// No description provided for @weightName.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightName;

  /// No description provided for @smmLabel.
  ///
  /// In en, this message translates to:
  /// **'Skeletal Muscle Mass (SMM)'**
  String get smmLabel;

  /// No description provided for @pfmLabel.
  ///
  /// In en, this message translates to:
  /// **'Percent Body Fat (PFM)'**
  String get pfmLabel;

  /// No description provided for @historyText.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyText;

  /// No description provided for @progressText.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressText;

  /// No description provided for @chartAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get chartAll;

  /// No description provided for @chart1m.
  ///
  /// In en, this message translates to:
  /// **'1m'**
  String get chart1m;

  /// No description provided for @chart3m.
  ///
  /// In en, this message translates to:
  /// **'3m'**
  String get chart3m;

  /// No description provided for @chart1y.
  ///
  /// In en, this message translates to:
  /// **'1y'**
  String get chart1y;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @maxWeight.
  ///
  /// In en, this message translates to:
  /// **'Max Weight'**
  String get maxWeight;

  /// No description provided for @estimated1RM.
  ///
  /// In en, this message translates to:
  /// **'Estimated 1RM'**
  String get estimated1RM;

  /// No description provided for @bodyWeight.
  ///
  /// In en, this message translates to:
  /// **'Body Weight'**
  String get bodyWeight;

  /// No description provided for @deleteWorkout.
  ///
  /// In en, this message translates to:
  /// **'Delete Workout?'**
  String get deleteWorkout;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @welcomeToGymBrain.
  ///
  /// In en, this message translates to:
  /// **'Welcome to GymBrain'**
  String get welcomeToGymBrain;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @addStarterPack.
  ///
  /// In en, this message translates to:
  /// **'Add Starter Pack?'**
  String get addStarterPack;

  /// No description provided for @addExerciseBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Exercise'**
  String get addExerciseBtn;

  /// No description provided for @timeFeedback.
  ///
  /// In en, this message translates to:
  /// **'Time Feedback'**
  String get timeFeedback;

  /// No description provided for @defaultRestTimer.
  ///
  /// In en, this message translates to:
  /// **'Default Rest Timer'**
  String get defaultRestTimer;

  /// No description provided for @timerSoundEffect.
  ///
  /// In en, this message translates to:
  /// **'Timer Sound Effect'**
  String get timerSoundEffect;

  /// No description provided for @resetTimer.
  ///
  /// In en, this message translates to:
  /// **'Reset Timer'**
  String get resetTimer;

  /// No description provided for @backgroundAlerts.
  ///
  /// In en, this message translates to:
  /// **'Background Alerts'**
  String get backgroundAlerts;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'PERSONAL INFO'**
  String get personalInfo;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @activityLevel.
  ///
  /// In en, this message translates to:
  /// **'Activity Level'**
  String get activityLevel;

  /// No description provided for @bodyStats.
  ///
  /// In en, this message translates to:
  /// **'BODY STATS'**
  String get bodyStats;

  /// No description provided for @smartMetrics.
  ///
  /// In en, this message translates to:
  /// **'SMART METRICS'**
  String get smartMetrics;

  /// No description provided for @bodyMassIndex.
  ///
  /// In en, this message translates to:
  /// **'Body Mass Index'**
  String get bodyMassIndex;

  /// No description provided for @dailyCalories.
  ///
  /// In en, this message translates to:
  /// **'Daily Calories (TDEE)'**
  String get dailyCalories;

  /// No description provided for @editNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get editNameTitle;

  /// No description provided for @editAgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Age'**
  String get editAgeTitle;

  /// No description provided for @editHeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Height'**
  String get editHeightTitle;

  /// No description provided for @selectGenderTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Gender'**
  String get selectGenderTitle;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @activityLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity Level'**
  String get activityLevelTitle;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelBtn;

  /// No description provided for @oneRepMaxCalc.
  ///
  /// In en, this message translates to:
  /// **'One Rep Max Calculator'**
  String get oneRepMaxCalc;

  /// No description provided for @calculate1RM.
  ///
  /// In en, this message translates to:
  /// **'CALCULATE 1RM'**
  String get calculate1RM;

  /// No description provided for @liftedWeight.
  ///
  /// In en, this message translates to:
  /// **'LIFTED WEIGHT'**
  String get liftedWeight;

  /// No description provided for @repsPerformed.
  ///
  /// In en, this message translates to:
  /// **'REPS PERFORMED'**
  String get repsPerformed;

  /// No description provided for @exerciseNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Exercise Name'**
  String get exerciseNameLabel;

  /// No description provided for @targetSetsLabel.
  ///
  /// In en, this message translates to:
  /// **'Target Sets'**
  String get targetSetsLabel;

  /// No description provided for @setupNoteOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Setup Note (Optional)'**
  String get setupNoteOptionalLabel;

  /// No description provided for @secUnit.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get secUnit;

  /// No description provided for @minUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minUnit;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportBackup;

  /// No description provided for @exportBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Save all data as a JSON file'**
  String get exportBackupDesc;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get restoreBackup;

  /// No description provided for @restoreBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Import data from a backup file'**
  String get restoreBackupDesc;

  /// No description provided for @defaultWeightUnit.
  ///
  /// In en, this message translates to:
  /// **'Default Weight Unit'**
  String get defaultWeightUnit;

  /// No description provided for @starterPackDesc.
  ///
  /// In en, this message translates to:
  /// **'Includes basic exercises & Push/Pull/Legs routine.'**
  String get starterPackDesc;

  /// No description provided for @factoryResetApp.
  ///
  /// In en, this message translates to:
  /// **'Factory Reset App'**
  String get factoryResetApp;

  /// No description provided for @factoryResetAppDesc.
  ///
  /// In en, this message translates to:
  /// **'Wipe all data and restart fresh'**
  String get factoryResetAppDesc;

  /// No description provided for @factoryResetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Factory Reset?'**
  String get factoryResetConfirmTitle;

  /// No description provided for @factoryResetConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'This will PERMANENTLY DELETE all data:\n\n• All Exercises\n• All Routines\n• Entire Workout History\n• InBody Records\n• All Settings\n\nThis action CANNOT be undone!'**
  String get factoryResetConfirmDesc;

  /// No description provided for @factoryResetBtn.
  ///
  /// In en, this message translates to:
  /// **'Reset Everything'**
  String get factoryResetBtn;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup?'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'This will REPLACE all current data:\n\n• Exercises\n• Routines\n• Workout History\n• InBody Records\n• Settings\n\nThis action CANNOT be undone!'**
  String get restoreConfirmDesc;

  /// No description provided for @editExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Exercise'**
  String get editExerciseTitle;

  /// No description provided for @addNewExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Exercise'**
  String get addNewExerciseTitle;

  /// No description provided for @trend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get trend;

  /// No description provided for @exerciseProgram.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exerciseProgram;

  /// No description provided for @addLabel.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addLabel;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// No description provided for @libraryLabel.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryLabel;

  /// No description provided for @setupLabel.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get setupLabel;

  /// No description provided for @targetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get targetLabel;

  /// No description provided for @kgLabel.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kgLabel;

  /// No description provided for @lbLabel.
  ///
  /// In en, this message translates to:
  /// **'lb'**
  String get lbLabel;

  /// No description provided for @effortMax.
  ///
  /// In en, this message translates to:
  /// **'Max Effort'**
  String get effortMax;

  /// No description provided for @effortNearMax.
  ///
  /// In en, this message translates to:
  /// **'Near Max'**
  String get effortNearMax;

  /// No description provided for @effortHeavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy'**
  String get effortHeavy;

  /// No description provided for @effortHypertrophy.
  ///
  /// In en, this message translates to:
  /// **'Hypertrophy'**
  String get effortHypertrophy;

  /// No description provided for @effortEndurance.
  ///
  /// In en, this message translates to:
  /// **'Strength-Endurance'**
  String get effortEndurance;

  /// No description provided for @effortWarmup.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get effortWarmup;

  /// No description provided for @yearsOld.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get yearsOld;

  /// No description provided for @restFinishedTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest Finished! 🔔'**
  String get restFinishedTitle;

  /// No description provided for @timeToCrush.
  ///
  /// In en, this message translates to:
  /// **'Time to crush your next set of'**
  String get timeToCrush;

  /// No description provided for @yearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}y ago'**
  String yearsAgo(int count);

  /// No description provided for @monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}mo ago'**
  String monthsAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(int count);

  /// No description provided for @minsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minsAgo(int count);

  /// No description provided for @setOf.
  ///
  /// In en, this message translates to:
  /// **'set {current} of {total}'**
  String setOf(int current, int total);

  /// No description provided for @myRoutines.
  ///
  /// In en, this message translates to:
  /// **'My Routines'**
  String get myRoutines;

  /// No description provided for @newRoutine.
  ///
  /// In en, this message translates to:
  /// **'new routine'**
  String get newRoutine;

  /// No description provided for @addedLabel.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get addedLabel;

  /// No description provided for @calculateEstimated1rm.
  ///
  /// In en, this message translates to:
  /// **'Calculate your estimated 1RM using the Epley formula'**
  String get calculateEstimated1rm;

  /// No description provided for @plateInventory.
  ///
  /// In en, this message translates to:
  /// **'Plate Inventory'**
  String get plateInventory;

  /// No description provided for @timerDesc.
  ///
  /// In en, this message translates to:
  /// **'Play a beep when the timer ends'**
  String get timerDesc;

  /// No description provided for @alertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Send a notification if app is in background'**
  String get alertsDesc;

  /// No description provided for @feedbackDesc.
  ///
  /// In en, this message translates to:
  /// **'Display performance tips after each set'**
  String get feedbackDesc;

  /// No description provided for @dataManDesc.
  ///
  /// In en, this message translates to:
  /// **'Backup your data to keep it safe or transfer to another device.'**
  String get dataManDesc;

  /// No description provided for @egPushDay.
  ///
  /// In en, this message translates to:
  /// **'e.g., Push Day'**
  String get egPushDay;

  /// No description provided for @standardPrefix.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get standardPrefix;

  /// No description provided for @olympicStandard.
  ///
  /// In en, this message translates to:
  /// **'Olympic Standard'**
  String get olympicStandard;

  /// No description provided for @womensPrefix.
  ///
  /// In en, this message translates to:
  /// **'Women\'s'**
  String get womensPrefix;

  /// No description provided for @trainingPrefix.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get trainingPrefix;

  /// No description provided for @bmiUnderweight.
  ///
  /// In en, this message translates to:
  /// **'Underweight'**
  String get bmiUnderweight;

  /// No description provided for @bmiNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get bmiNormal;

  /// No description provided for @bmiOverweight.
  ///
  /// In en, this message translates to:
  /// **'Overweight'**
  String get bmiOverweight;

  /// No description provided for @bmiObese.
  ///
  /// In en, this message translates to:
  /// **'Obese'**
  String get bmiObese;

  /// No description provided for @plateInventoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Uncheck plates you don\'t have at your gym.'**
  String get plateInventoryDesc;

  /// No description provided for @noBodyStats.
  ///
  /// In en, this message translates to:
  /// **'No stats yet. Add your data with the + button!'**
  String get noBodyStats;

  /// No description provided for @addDataToSeeChart.
  ///
  /// In en, this message translates to:
  /// **'Add data to see chart'**
  String get addDataToSeeChart;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @selectExOrRoutine.
  ///
  /// In en, this message translates to:
  /// **'Select Exercise or Routine'**
  String get selectExOrRoutine;

  /// No description provided for @languageDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get languageDesc;

  /// No description provided for @workoutHistory.
  ///
  /// In en, this message translates to:
  /// **'Workout History'**
  String get workoutHistory;

  /// No description provided for @noWorkouts.
  ///
  /// In en, this message translates to:
  /// **'No workouts recorded yet.'**
  String get noWorkouts;

  /// No description provided for @deleteUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteUndone;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @volumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volumeLabel;

  /// No description provided for @setsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get setsLabel;

  /// No description provided for @workoutDeleted.
  ///
  /// In en, this message translates to:
  /// **'Workout deleted'**
  String get workoutDeleted;

  /// No description provided for @noExercisesFound.
  ///
  /// In en, this message translates to:
  /// **'No exercises found'**
  String get noExercisesFound;

  /// No description provided for @activitySedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary (little or no exercise)'**
  String get activitySedentary;

  /// No description provided for @activityLightly.
  ///
  /// In en, this message translates to:
  /// **'Lightly active (1-3 days/week)'**
  String get activityLightly;

  /// No description provided for @activityModerately.
  ///
  /// In en, this message translates to:
  /// **'Moderately active (3-5 days/week)'**
  String get activityModerately;

  /// No description provided for @activityVery.
  ///
  /// In en, this message translates to:
  /// **'Very active (6-7 days/week)'**
  String get activityVery;

  /// No description provided for @activityExtra.
  ///
  /// In en, this message translates to:
  /// **'Extra active (very hard exercise)'**
  String get activityExtra;

  /// No description provided for @cmLabel.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get cmLabel;

  /// No description provided for @kcalLabel.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get kcalLabel;

  /// No description provided for @sessionBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Session Breakdown'**
  String get sessionBreakdown;

  /// No description provided for @rpeDesc1.
  ///
  /// In en, this message translates to:
  /// **'Very easy - could do 9+ more reps'**
  String get rpeDesc1;

  /// No description provided for @rpeDesc2.
  ///
  /// In en, this message translates to:
  /// **'Easy - could do 8+ more reps'**
  String get rpeDesc2;

  /// No description provided for @rpeDesc3.
  ///
  /// In en, this message translates to:
  /// **'Light - could do 7+ more reps'**
  String get rpeDesc3;

  /// No description provided for @rpeDesc4.
  ///
  /// In en, this message translates to:
  /// **'Light-moderate - could do 6+ more reps'**
  String get rpeDesc4;

  /// No description provided for @rpeDesc5.
  ///
  /// In en, this message translates to:
  /// **'Moderate - could do 5+ more reps'**
  String get rpeDesc5;

  /// No description provided for @rpeDesc6.
  ///
  /// In en, this message translates to:
  /// **'Moderate - could do 4+ more reps'**
  String get rpeDesc6;

  /// No description provided for @rpeDesc7.
  ///
  /// In en, this message translates to:
  /// **'Somewhat hard - could do 3 more reps'**
  String get rpeDesc7;

  /// No description provided for @rpeDesc8.
  ///
  /// In en, this message translates to:
  /// **'Hard - could do 2 more reps'**
  String get rpeDesc8;

  /// No description provided for @rpeDesc9.
  ///
  /// In en, this message translates to:
  /// **'Very hard - could do 1 more rep'**
  String get rpeDesc9;

  /// No description provided for @rpeDesc10.
  ///
  /// In en, this message translates to:
  /// **'Max effort - couldn\'t do more'**
  String get rpeDesc10;

  /// No description provided for @rpeRateEffort.
  ///
  /// In en, this message translates to:
  /// **'Rate your effort'**
  String get rpeRateEffort;

  /// No description provided for @rpeEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get rpeEasy;

  /// No description provided for @rpeGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get rpeGood;

  /// No description provided for @rpeHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get rpeHard;

  /// No description provided for @workoutReminders.
  ///
  /// In en, this message translates to:
  /// **'Workout Reminders'**
  String get workoutReminders;

  /// No description provided for @workoutRemindersDesc.
  ///
  /// In en, this message translates to:
  /// **'Get a reminder if you haven\'t trained in a while'**
  String get workoutRemindersDesc;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'GymBrain'**
  String get reminderTitle;

  /// No description provided for @reminderBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s been a while! Time to crush your next workout. 💪'**
  String get reminderBody;
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
