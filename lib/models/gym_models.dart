import 'package:hive/hive.dart';

part 'gym_models.g.dart';

@HiveType(typeId: 0)
class Exercise extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? setupNote;

  @HiveField(3)
  final String? imagePath;

  @HiveField(4)
  final int targetSets;

  Exercise({
    required this.id,
    required this.name,
    this.setupNote,
    this.imagePath,
    this.targetSets = 3,
  });
}

@HiveType(typeId: 1)
class Routine extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<String> exerciseIds;

  Routine({required this.id, required this.name, required this.exerciseIds});
}

@HiveType(typeId: 2)
class ExerciseSet extends HiveObject {
  @HiveField(0)
  final String exerciseName;

  @HiveField(1)
  final double weight;

  @HiveField(2)
  final int reps;

  @HiveField(3)
  final String rpe; // 'Easy', 'Good', 'Hard'

  @HiveField(4)
  final bool isCompleted;

  @HiveField(5) // New field
  final String unit; // 'kg' or 'lb'

  ExerciseSet({
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.rpe,
    required this.isCompleted,
    this.unit = 'kg',
  });
}

@HiveType(typeId: 3)
class WorkoutSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String routineName;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final int durationInSeconds;

  @HiveField(4)
  final List<ExerciseSet> sets;

  WorkoutSession({
    required this.id,
    required this.routineName,
    required this.date,
    required this.durationInSeconds,
    required this.sets,
  });
}

@HiveType(typeId: 4)
class InBodyRecord extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final double weight;

  @HiveField(2)
  final double smm; // Skeletal Muscle Mass

  @HiveField(3)
  final double pbf; // Percent Body Fat

  @HiveField(4)
  final String? imagePath;

  InBodyRecord({
    required this.date,
    required this.weight,
    required this.smm,
    required this.pbf,
    this.imagePath,
  });
}
