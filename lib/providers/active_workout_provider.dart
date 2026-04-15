import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/gym_models.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'package:uuid/uuid.dart';

class ActiveWorkoutProvider extends ChangeNotifier
    with WidgetsBindingObserver {
  final _db = GymDatabase();

  Routine? _currentRoutine;
  List<ExerciseSet> _completedSets = [];
  DateTime? _startTime;
  int _focusedIndex = 0;

  // === Rest Timer State (lives in provider so it survives widget disposal) ===
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  bool _isResting = false;
  DateTime? _restEndTime;

  Routine? get currentRoutine => _currentRoutine;
  List<ExerciseSet> get completedSets => _completedSets;
  DateTime? get startTime => _startTime;
  int get focusedIndex => _focusedIndex;

  // Rest Timer Getters
  bool get isResting => _isResting;
  int get restSecondsRemaining => _restSecondsRemaining;
  DateTime? get restEndTime => _restEndTime;

  bool get hasActiveWorkout => _currentRoutine != null;

  ActiveWorkoutProvider() {
    WidgetsBinding.instance.addObserver(this);
    _checkActiveSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restTimer?.cancel();
    super.dispose();
  }

  // === App Lifecycle: Recover rest timer on resume ===
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isResting && _restEndTime != null) {
        final remaining = _restEndTime!.difference(DateTime.now());
        if (remaining.isNegative) {
          // Rest finished while in background — auto-complete
          _restTimer?.cancel();
          _isResting = false;
          _restSecondsRemaining = 0;
          _restEndTime = null;
          notifyListeners();
        } else {
          // Rest is still ongoing — sync remaining time & restart tick
          _restSecondsRemaining = remaining.inSeconds;
          NotificationService().cancelRestNotification();
          _startRestTimerTick();
          notifyListeners();
        }
      }
    }
  }

  Future<void> _checkActiveSession() async {
    final active = _db.getActiveSession();
    if (active != null) {
      final routineId = active['routineId'];
      try {
        final routines = _db.getRoutines();
        // Check if routine still exists
        final routine = routines.firstWhere(
          (r) => r.id == routineId,
          orElse: () => throw Exception("Routine not found"),
        );

        _currentRoutine = routine;

        if (active['startTime'] != null) {
          _startTime = active['startTime'];
        }
        if (active['completedSets'] != null) {
          _completedSets = (active['completedSets'] as List)
              .cast<ExerciseSet>();
        }
        _focusedIndex = active['focusedIndex'] ?? 0;

        notifyListeners();
      } catch (e) {
        debugPrint("Error restoring active session: $e");
        await _db.clearActiveSession();
        _currentRoutine = null;
        _completedSets = [];
        _startTime = null;
        _focusedIndex = 0;
        notifyListeners();
      }
    }
  }

  void startWorkout(Routine routine) {
    _currentRoutine = routine;
    // Only set start time if not already set (restarting vs resuming not applicable here, start is fresh)
    _startTime = DateTime.now();
    _completedSets = [];
    _focusedIndex = 0;
    _saveProgress();
    notifyListeners();
  }

  void resumeWorkout(
    Routine routine,
    DateTime startTime,
    List<ExerciseSet> sets,
    int focusedIndex,
  ) {
    _currentRoutine = routine;
    _startTime = startTime;
    _completedSets = sets;
    _focusedIndex = focusedIndex;
    notifyListeners();
  }

  void minimizeWorkout() {
    _saveProgress();
    notifyListeners();
  }

  void addSet(ExerciseSet set) {
    _completedSets.add(set);
    _saveProgress();
    notifyListeners();
  }

  void updateSet(int index, ExerciseSet newSet) {
    if (index >= 0 && index < _completedSets.length) {
      _completedSets[index] = newSet;
      _saveProgress();
      notifyListeners();
    }
  }

  void setFocusedIndex(int index) {
    _focusedIndex = index;
    _saveProgress();
    notifyListeners();
  }

  // === Rest Timer Methods ===

  /// Starts a rest timer for the given duration (in seconds).
  /// Called by the active workout screen after each set.
  void startRest(int seconds) {
    _restTimer?.cancel();
    _restEndTime = DateTime.now().add(Duration(seconds: seconds));
    _isResting = true;
    _restSecondsRemaining = seconds;
    _startRestTimerTick();
    notifyListeners();
  }

  /// Internal: starts (or restarts) the periodic UI tick.
  /// Uses _restEndTime as the single source of truth.
  void _startRestTimerTick() {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restEndTime == null) {
        timer.cancel();
        return;
      }
      final remaining = _restEndTime!.difference(DateTime.now()).inSeconds;
      if (remaining > 0) {
        _restSecondsRemaining = remaining;
        notifyListeners();
      } else {
        timer.cancel();
        completeRest();
      }
    });
  }

  /// Called when rest finishes naturally (timer reached zero).
  /// Also callable from outside (screen) to trigger completion feedback.
  void completeRest() {
    _restTimer?.cancel();
    _isResting = false;
    _restSecondsRemaining = 0;
    _restEndTime = null;
    NotificationService().cancelRestNotification();
    notifyListeners();
  }

  /// Skips the rest timer immediately.
  void skipRest() {
    _restTimer?.cancel();
    _isResting = false;
    _restSecondsRemaining = 0;
    _restEndTime = null;
    NotificationService().cancelNotification(0);
    NotificationService().cancelRestNotification();
    notifyListeners();
  }

  /// Adds 30 seconds to the current rest timer.
  void add30Seconds() {
    if (_restEndTime != null) {
      _restEndTime = _restEndTime!.add(const Duration(seconds: 30));
      _restSecondsRemaining = _restEndTime!.difference(DateTime.now()).inSeconds;
      notifyListeners();
    }
  }

  Future<void> finishWorkout() async {
    if (_startTime == null || _currentRoutine == null) return;

    // Clean up rest timer
    skipRest();

    final session = WorkoutSession(
      id: const Uuid().v4(),
      routineName: _currentRoutine!.name,
      date: DateTime.now(),
      durationInSeconds: DateTime.now().difference(_startTime!).inSeconds,
      sets: _completedSets,
    );

    await _db.saveSession(session);

    // Workout Reminder Logic
    final notificationService = NotificationService();
    await notificationService.cancelReminderNotification();

    if (_db.enableWorkoutReminder) {
      final lang = _db.languageCode;
      final title = lang == 'ar' ? 'جيم برين' : 'GymBrain';
      final body = lang == 'ar'
          ? 'عدى وقت طويل يا بطل! وقت تكسير الأوزان. 💪'
          : "It's been a while! Time to crush your next workout. 💪";
      await notificationService.scheduleReminderNotification(
        title: title,
        body: body,
        days: 3,
      );
    }

    await clearData();
  }

  Future<void> clearData() async {
    skipRest();
    await _db.clearActiveSession();
    _currentRoutine = null;
    _completedSets = [];
    _startTime = null;
    _focusedIndex = 0;
    notifyListeners();
  }

  void _saveProgress() {
    if (_currentRoutine != null && _startTime != null) {
      _db.saveActiveSession(
        _currentRoutine!.id,
        _startTime!,
        _completedSets,
        focusedIndex: _focusedIndex,
      );
    }
  }
}

