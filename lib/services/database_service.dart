import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/gym_models.dart';

class GymDatabase extends ChangeNotifier {
  static final GymDatabase _instance = GymDatabase._internal();

  factory GymDatabase() {
    return _instance;
  }

  GymDatabase._internal();

  late Box<Exercise> _exerciseBox;
  late Box<Routine> _routineBox;
  late Box<WorkoutSession> _sessionBox;
  late Box<InBodyRecord> _inBodyBox;

  Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(ExerciseAdapter());
    Hive.registerAdapter(RoutineAdapter());
    Hive.registerAdapter(ExerciseSetAdapter());
    Hive.registerAdapter(WorkoutSessionAdapter());
    Hive.registerAdapter(InBodyRecordAdapter());

    _exerciseBox = await Hive.openBox<Exercise>('exercises');
    _routineBox = await Hive.openBox<Routine>('routines');
    _sessionBox = await Hive.openBox<WorkoutSession>('sessions');
    _sessionBox = await Hive.openBox<WorkoutSession>('sessions');
    _inBodyBox = await Hive.openBox<InBodyRecord>('inbody');
    _activeSessionBox = await Hive.openBox('active_session');
    _settingsBox = await Hive.openBox('settings');
  }

  // Active Session Persistence
  late Box _activeSessionBox;
  late Box _settingsBox;

  // Public getter for settings box (used by ProfileScreen)
  Box get settingsBox => _settingsBox;

  // Settings
  int get defaultRestSeconds =>
      _settingsBox.get('default_rest_seconds', defaultValue: 90);
  Future<void> setDefaultRestSeconds(int seconds) async =>
      _settingsBox.put('default_rest_seconds', seconds);

  bool get enableSound => _settingsBox.get('enable_sound', defaultValue: true);
  Future<void> setEnableSound(bool enable) async =>
      _settingsBox.put('enable_sound', enable);

  bool get enableNotifications =>
      _settingsBox.get('enable_notifications', defaultValue: true);
  Future<void> setEnableNotifications(bool enable) async =>
      _settingsBox.put('enable_notifications', enable);

  bool get enableAiFeedback =>
      _settingsBox.get('enable_ai_feedback', defaultValue: true);
  Future<void> setEnableAiFeedback(bool enable) async =>
      _settingsBox.put('enable_ai_feedback', enable);

  // Plate Calculator Inventory Settings
  static const List<double> defaultPlatesKg = [
    25.0,
    20.0,
    15.0,
    10.0,
    5.0,
    2.5,
    1.25,
    0.5,
  ];
  static const List<double> defaultPlatesLb = [
    45.0,
    35.0,
    25.0,
    10.0,
    5.0,
    2.5,
    1.25,
  ];

  List<double> get availablePlatesKg {
    final stored = _settingsBox.get('available_plates_kg');
    if (stored == null) return defaultPlatesKg;
    return (stored as List).cast<double>();
  }

  Future<void> setAvailablePlatesKg(List<double> plates) async =>
      _settingsBox.put('available_plates_kg', plates);

  List<double> get availablePlatesLb {
    final stored = _settingsBox.get('available_plates_lb');
    if (stored == null) return defaultPlatesLb;
    return (stored as List).cast<double>();
  }

  Future<void> setAvailablePlatesLb(List<double> plates) async =>
      _settingsBox.put('available_plates_lb', plates);

  Future<void> saveActiveSession(
    String routineId,
    DateTime startTime,
    List<ExerciseSet> completedSets, {
    int? focusedIndex,
  }) async {
    await _activeSessionBox.put('routineId', routineId);
    await _activeSessionBox.put('startTime', startTime.millisecondsSinceEpoch);
    // Hive can store Lists of HiveObjects if adapter is registered
    await _activeSessionBox.put('completedSets', completedSets);
    if (focusedIndex != null) {
      await _activeSessionBox.put('focusedIndex', focusedIndex);
    }
  }

  Map<String, dynamic>? getActiveSession() {
    if (_activeSessionBox.isEmpty) return null;
    final routineId = _activeSessionBox.get('routineId') as String?;
    if (routineId == null) return null;

    final startTimeMs = _activeSessionBox.get('startTime') as int?;
    final startTime = startTimeMs != null
        ? DateTime.fromMillisecondsSinceEpoch(startTimeMs)
        : null;

    final setsDynamic = _activeSessionBox.get('completedSets');
    List<ExerciseSet> completedSets = [];
    if (setsDynamic is List) {
      completedSets = setsDynamic.cast<ExerciseSet>().toList();
    }

    final focusedIndex = _activeSessionBox.get('focusedIndex') as int? ?? 0;

    return {
      'routineId': routineId,
      'startTime': startTime,
      'completedSets': completedSets,
      'focusedIndex': focusedIndex,
    };
  }

  Future<void> clearActiveSession() async {
    await _activeSessionBox.clear();
  }

  // Exercises
  Future<void> saveExercise(Exercise exercise) async {
    await _exerciseBox.put(exercise.id, exercise);
    notifyListeners();
  }

  List<Exercise> getExercises() {
    return _exerciseBox.values.toList();
  }

  Exercise? getExercise(String id) {
    return _exerciseBox.get(id);
  }

  String? findExerciseIdByName(String name) {
    try {
      final exercise = _exerciseBox.values.firstWhere(
        (e) => e.name.toLowerCase() == name.toLowerCase(),
      );
      return exercise.id;
    } catch (e) {
      return null;
    }
  }

  // Phase 4: Library Logic
  List<String> getUniqueExerciseNames() {
    final names = <String>{};
    for (var ex in _exerciseBox.values) {
      names.add(ex.name);
    }
    return names.toList()..sort();
  }

  // Routines
  Future<void> saveRoutine(Routine routine) async {
    await _routineBox.put(routine.id, routine);
    notifyListeners();
  }

  Future<void> deleteRoutine(String id) async {
    await _routineBox.delete(id);
    notifyListeners();
  }

  List<Routine> getRoutines() {
    return _routineBox.values.toList();
  }

  // Listenables
  ValueListenable<Box<Routine>> get routineListenable =>
      _routineBox.listenable();
  ValueListenable<Box<Exercise>> get exerciseListenable =>
      _exerciseBox.listenable();

  // Sessions
  Future<void> saveSession(WorkoutSession session) async {
    await _sessionBox.put(session.id, session);
    notifyListeners();
  }

  List<WorkoutSession> getSessions() {
    final sessions = _sessionBox.values.toList();
    sessions.sort((a, b) => b.date.compareTo(a.date));
    return sessions;
  }

  // InBody
  Future<void> addInBodyRecord(InBodyRecord record) async {
    await _inBodyBox.add(record);
    notifyListeners();
  }

  Future<void> updateInBodyRecord(dynamic key, InBodyRecord record) async {
    await _inBodyBox.put(key, record);
    notifyListeners();
  }

  Future<void> deleteInBodyRecord(dynamic key) async {
    await _inBodyBox.delete(key);
    notifyListeners();
  }

  InBodyRecord? getLatestInBody() {
    if (_inBodyBox.isEmpty) return null;
    final records = _inBodyBox.values.toList();
    records.sort((a, b) => b.date.compareTo(a.date));
    return records.first;
  }

  List<InBodyRecord> getAllInBodyRecords() {
    final records = _inBodyBox.values.toList();
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  // History / Ghost Logic
  ExerciseSet? getLastPerformance(String exerciseId) {
    final exercise = getExercise(exerciseId);
    if (exercise == null) return null;

    final sessions = getSessions(); // Already sorted by date desc
    for (final session in sessions) {
      for (final set in session.sets) {
        if (set.exerciseName == exercise.name) {
          return set;
        }
      }
    }
    return null;
  }

  // Exercise History for Charts (returns history with sets for counting)
  List<Map<String, dynamic>> getExerciseHistory(String exerciseId) {
    final exercise = getExercise(exerciseId);
    if (exercise == null) {
      debugPrint('getExerciseHistory: Exercise ID $exerciseId not found');
      return [];
    }

    final history = <Map<String, dynamic>>[];
    final sessions = getSessions().reversed.toList(); // Oldest first for charts

    for (final session in sessions) {
      // Find all sets for this exercise
      final exerciseSets = <ExerciseSet>[];
      double maxWeight = 0;

      for (final set in session.sets) {
        if (set.exerciseName == exercise.name) {
          exerciseSets.add(set);
          if (set.weight > maxWeight) {
            maxWeight = set.weight;
          }
        }
      }

      if (exerciseSets.isNotEmpty) {
        history.add({
          'date': session.date,
          'weight': maxWeight,
          'sets': exerciseSets, // Include sets for counting
        });
      }
    }

    debugPrint(
      'getExerciseHistory for ID $exerciseId (${exercise.name}): found ${history.length} sessions',
    );
    return history;
  }

  // Delete all history for an exercise (deep delete)
  Future<void> deleteExerciseHistory(String exerciseName) async {
    final sessions = getSessions();

    for (final session in sessions) {
      // Remove sets matching this exercise
      final originalLength = session.sets.length;
      session.sets.removeWhere((set) => set.exerciseName == exerciseName);

      if (session.sets.length != originalLength) {
        // Session was modified, save it
        if (session.sets.isEmpty) {
          // Delete the entire session if no sets remain
          await _sessionBox.delete(session.id);
        } else {
          await session.save();
        }
      }
    }

    notifyListeners();
    debugPrint('Deleted all history for exercise: $exerciseName');
  }

  // Phase 3: Robust Name-Based History
  List<String> getExerciseNamesFromHistory() {
    final Set<String> names = {};
    for (final session in getSessions()) {
      for (final set in session.sets) {
        names.add(set.exerciseName);
      }
    }
    return names.toList()..sort();
  }

  List<Map<String, dynamic>> getHistoryForExerciseName(String exerciseName) {
    final history = <Map<String, dynamic>>[];
    final sessions = getSessions().reversed.toList(); // Oldest first for charts

    for (final session in sessions) {
      double maxWeight = 0;
      double totalVolume = 0;
      String maxWeightUnit = 'kg'; // Default for legacy data
      bool found = false;

      for (final set in session.sets) {
        if (set.exerciseName == exerciseName) {
          found = true;
          // Max Weight (track the unit of the heaviest set)
          if (set.weight > maxWeight) {
            maxWeight = set.weight;
            maxWeightUnit = set.unit;
          }
          // Volume = Weight * Reps (converted to kg for consistency)
          double weightInKg = set.unit == 'lb'
              ? set.weight * 0.453592
              : set.weight;
          totalVolume += (weightInKg * set.reps);
        }
      }

      if (found) {
        history.add({
          'date': session.date,
          'weight': maxWeight,
          'volume': totalVolume,
          'unit': maxWeightUnit,
        });
      }
    }
    return history;
  }

  // Routine History Logic
  List<String> getRoutineNamesFromHistory() {
    final Set<String> names = {};
    for (final session in getSessions()) {
      names.add(session.routineName);
    }
    return names.toList()..sort();
  }

  List<Map<String, dynamic>> getHistoryForRoutine(String routineName) {
    final history = <Map<String, dynamic>>[];
    final sessions = getSessions().reversed.toList();

    for (final session in sessions) {
      if (session.routineName == routineName) {
        double totalVolume = 0;
        for (final set in session.sets) {
          totalVolume += (set.weight * set.reps);
        }
        history.add({
          'date': session.date,
          'volume': totalVolume,
          'weight': 0.0,
        });
      }
    }
    return history;
  }
}
