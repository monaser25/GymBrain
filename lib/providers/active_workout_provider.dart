import 'package:flutter/foundation.dart';
import '../models/gym_models.dart';
import '../services/database_service.dart';
import 'package:uuid/uuid.dart';

class ActiveWorkoutProvider extends ChangeNotifier {
  final _db = GymDatabase();

  Routine? _currentRoutine;
  List<ExerciseSet> _completedSets = [];
  DateTime? _startTime;
  int _focusedIndex = 0;

  Routine? get currentRoutine => _currentRoutine;
  List<ExerciseSet> get completedSets => _completedSets;
  DateTime? get startTime => _startTime;
  int get focusedIndex => _focusedIndex;

  bool get hasActiveWorkout => _currentRoutine != null;

  ActiveWorkoutProvider() {
    _checkActiveSession();
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

  Future<void> finishWorkout() async {
    if (_startTime == null || _currentRoutine == null) return;

    final session = WorkoutSession(
      id: const Uuid().v4(),
      routineName: _currentRoutine!.name,
      date: DateTime.now(),
      durationInSeconds: DateTime.now().difference(_startTime!).inSeconds,
      sets: _completedSets,
    );

    await _db.saveSession(session);
    await clearData();
  }

  Future<void> clearData() async {
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
