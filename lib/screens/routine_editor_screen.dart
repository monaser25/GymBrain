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
            onPressed: () => _showExerciseDialog(context, routine),
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

    final exercises = <Exercise>[];
    for (final id in routine.exerciseIds) {
      final ex = _db.getExercise(id);
      if (ex != null) {
        exercises.add(ex);
      }
    }

    return ReorderableListView.builder(
      itemCount: exercises.length,
      padding: const EdgeInsets.all(16),
      onReorder: (oldIndex, newIndex) =>
          _onReorder(routine, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return Card(
          key: ValueKey(exercise.id),
          margin: const EdgeInsets.symmetric(vertical: 6),
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            onTap: () => _showExerciseDialog(
              context,
              routine,
              existingExercise: exercise,
            ),
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (exercise.setupNote != null &&
                    exercise.setupNote!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "Setup: ${exercise.setupNote}",
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "Target: ${exercise.targetSets} Sets",
                    style: const TextStyle(
                      color: Color(0xFF39FF14),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () =>
                      _removeExerciseFromRoutine(routine, exercise.id),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.drag_handle, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onReorder(Routine routine, int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = routine.exerciseIds.removeAt(oldIndex);
    routine.exerciseIds.insert(newIndex, item);
    await routine.save();
  }

  void _showExerciseDialog(
    BuildContext context,
    Routine routine, {
    Exercise? existingExercise,
  }) {
    final nameController = TextEditingController(
      text: existingExercise?.name ?? "",
    );
    final setupController = TextEditingController(
      text: existingExercise?.setupNote ?? "",
    );
    final targetSetsController = TextEditingController(
      text: existingExercise?.targetSets.toString() ?? "3",
    );
    final isEditing = existingExercise != null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            isEditing ? "Edit Exercise" : "New Exercise",
            style: const TextStyle(color: Colors.white),
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
                  controller: targetSetsController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Target Sets",
                    hintText: "3",
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF39FF14)),
                    ),
                  ),
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
                  final targetSets =
                      int.tryParse(targetSetsController.text) ?? 3;
                  final setupNote = setupController.text.isNotEmpty
                      ? setupController.text
                      : null;

                  if (isEditing) {
                    // Update existing (this might need database helper if not hive object directly modified)
                    // But Exercise extends HiveObject, so we can save it directly?
                    // Wait, GymDatabase puts them in box.
                    // Let's create a copy or modify fields?
                    // Hive objects are mutable.

                    // We need to modify the objects properties, but they are final in model?
                    // The model has final fields. Standard practice is to overwrite in box.
                    final updatedExercise = Exercise(
                      id: existingExercise.id,
                      name: nameController.text,
                      targetSets: targetSets,
                      setupNote: setupNote,
                      imagePath: existingExercise.imagePath,
                    );
                    await _db.saveExercise(updatedExercise);
                  } else {
                    // Create New
                    final newExercise = Exercise(
                      id: const Uuid().v4(),
                      name: nameController.text,
                      targetSets: targetSets,
                      setupNote: setupNote,
                    );
                    await _db.saveExercise(newExercise);
                    routine.exerciseIds.add(newExercise.id);
                    await routine.save();
                  }

                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14),
                foregroundColor: Colors.black,
              ),
              child: Text(isEditing ? "Save" : "Add"),
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
