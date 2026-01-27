import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/gym_models.dart';

class GymDatabase {
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
    _inBodyBox = await Hive.openBox<InBodyRecord>('inbody');
  }

  // Exercises
  Future<void> saveExercise(Exercise exercise) async {
    await _exerciseBox.put(exercise.id, exercise);
  }

  List<Exercise> getExercises() {
    return _exerciseBox.values.toList();
  }

  Exercise? getExercise(String id) {
    return _exerciseBox.get(id);
  }

  // Routines
  Future<void> saveRoutine(Routine routine) async {
    await _routineBox.put(routine.id, routine);
  }

  Future<void> deleteRoutine(String id) async {
    await _routineBox.delete(id);
  }

  List<Routine> getRoutines() {
    return _routineBox.values.toList();
  }

  // Listenables
  ValueListenable<Box<Routine>> get routineListenable =>
      _routineBox.listenable();

  // Sessions
  Future<void> saveSession(WorkoutSession session) async {
    await _sessionBox.put(session.id, session);
  }

  List<WorkoutSession> getSessions() {
    final sessions = _sessionBox.values.toList();
    sessions.sort((a, b) => b.date.compareTo(a.date));
    return sessions;
  }

  // InBody
  Future<void> addInBodyRecord(InBodyRecord record) async {
    await _inBodyBox.add(record);
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
}
