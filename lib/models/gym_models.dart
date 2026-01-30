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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'setupNote': setupNote,
    'imagePath': imagePath,
    'targetSets': targetSets,
  };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as String,
    name: json['name'] as String,
    setupNote: json['setupNote'] as String?,
    imagePath: json['imagePath'] as String?,
    targetSets: json['targetSets'] as int? ?? 3,
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'exerciseIds': exerciseIds,
  };

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
    id: json['id'] as String,
    name: json['name'] as String,
    exerciseIds: List<String>.from(json['exerciseIds'] as List),
  );
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
  final String rpe; // 'Easy', 'Good', 'Hard' (legacy)

  @HiveField(4)
  final bool isCompleted;

  @HiveField(5)
  final String unit; // 'kg' or 'lb'

  @HiveField(6) // Numeric RPE for Gym Brain Intelligence
  final int rpeValue; // Range 1-10

  @HiveField(7) // Spotter/Assisted flag
  final bool isAssisted;

  ExerciseSet({
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.rpe,
    required this.isCompleted,
    this.unit = 'kg',
    this.rpeValue = 8, // Default to 8 (good effort)
    this.isAssisted = false,
  });

  Map<String, dynamic> toJson() => {
    'exerciseName': exerciseName,
    'weight': weight,
    'reps': reps,
    'rpe': rpe,
    'isCompleted': isCompleted,
    'unit': unit,
    'rpeValue': rpeValue,
    'isAssisted': isAssisted,
  };

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => ExerciseSet(
    exerciseName: json['exerciseName'] as String,
    weight: (json['weight'] as num).toDouble(),
    reps: json['reps'] as int,
    rpe: json['rpe'] as String,
    isCompleted: json['isCompleted'] as bool,
    unit: json['unit'] as String? ?? 'kg',
    rpeValue: json['rpeValue'] as int? ?? 8,
    isAssisted: json['isAssisted'] as bool? ?? false,
  );
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'routineName': routineName,
    'date': date.toIso8601String(),
    'durationInSeconds': durationInSeconds,
    'sets': sets.map((s) => s.toJson()).toList(),
  };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
    id: json['id'] as String,
    routineName: json['routineName'] as String,
    date: DateTime.parse(json['date'] as String),
    durationInSeconds: json['durationInSeconds'] as int,
    sets: (json['sets'] as List)
        .map((s) => ExerciseSet.fromJson(s as Map<String, dynamic>))
        .toList(),
  );
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

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'weight': weight,
    'smm': smm,
    'pbf': pbf,
    'imagePath': imagePath,
  };

  factory InBodyRecord.fromJson(Map<String, dynamic> json) => InBodyRecord(
    date: DateTime.parse(json['date'] as String),
    weight: (json['weight'] as num).toDouble(),
    smm: (json['smm'] as num).toDouble(),
    pbf: (json['pbf'] as num).toDouble(),
    imagePath: json['imagePath'] as String?,
  );
}
