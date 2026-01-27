import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/gym_models.dart';
import '../services/database_service.dart';

class RoutineEditorScreen extends StatefulWidget {
  final String routineId;

  const RoutineEditorScreen({super.key, required this.routineId});

  @override
  State<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends State<RoutineEditorScreen> {
  final _db = GymDatabase();

  // We need to fetch the routine from the box to ensure we have the latest version (reactive)
  // or pass the object. Passing ID is safer for reloading from DB.

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<Routine>>(
      valueListenable: _db.routineListenable,
      builder: (context, routineBox, _) {
        final routine = routineBox.get(widget.routineId);

        if (routine == null) {
          return const Scaffold(body: Center(child: Text("Routine not found")));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(routine.name),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: _buildExerciseList(routine),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddExerciseDialog(context, routine),
            label: const Text("Add Exercise"),
            icon: const Icon(Icons.add),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.black,
          ),
        );
      },
    );
  }

  Widget _buildExerciseList(Routine routine) {
    if (routine.exerciseIds.isEmpty) {
      return Center(
        child: Text(
          "No exercises yet.\nAdd one to start building this routine!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    // Determine the list of exercises
    // We might have IDs that don't exist if not careful, but usually they should exist.
    // We need to look up each ID in the exercise box.

    final exercises = <Exercise>[];
    for (final id in routine.exerciseIds) {
      final ex = _db.getExercise(id);
      if (ex != null) {
        exercises.add(ex);
      }
    }

    // Using a normal list view for now as requested (ReorderableListView mentioned as option)
    return ListView.builder(
      itemCount: exercises.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[800],
              child: Text(
                "${index + 1}",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              exercise.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle:
                exercise.setupNote != null && exercise.setupNote!.isNotEmpty
                ? Text(
                    "Setup: ${exercise.setupNote}",
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  )
                : null,
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _removeExerciseFromRoutine(routine, exercise.id),
            ),
          ),
        );
      },
    );
  }

  void _showAddExerciseDialog(BuildContext context, Routine routine) {
    final nameController = TextEditingController();
    final setupController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            "New Exercise",
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Exercise Name",
                    hintText: "e.g. Incline Bench Press",
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF39FF14)),
                    ),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: setupController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Setup Note (Optional)",
                    hintText: "e.g. Seat 4, Pin 3",
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF39FF14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final newExercise = Exercise(
                    id: const Uuid().v4(),
                    name: nameController.text,
                    setupNote: setupController.text.isNotEmpty
                        ? setupController.text
                        : null,
                  );

                  // 1. Save Exercise
                  await _db.saveExercise(newExercise);

                  // 2. Add to Routine
                  routine.exerciseIds.add(newExercise.id);
                  await routine
                      .save(); // HiveObject save method updates itself in the box

                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14),
                foregroundColor: Colors.black,
              ),
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeExerciseFromRoutine(
    Routine routine,
    String exerciseId,
  ) async {
    routine.exerciseIds.remove(exerciseId);
    await routine.save();
  }
}
