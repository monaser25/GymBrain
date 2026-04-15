import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/gym_models.dart';
import '../services/database_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/workout_helper.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final _db = GymDatabase();
  final _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.exerciseLibrary ?? "Exercise Library",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              cursorColor: const Color(0xFF39FF14),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)?.searchExercises ?? "Search exercises...",
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF39FF14)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1C1C1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF39FF14),
                    width: 1,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // Exercise List
          Expanded(
            child: ValueListenableBuilder<Box<Exercise>>(
              valueListenable: _db.exerciseListenable,
              builder: (context, box, _) {
                final allExercises = _db.getExercises();

                // Filter by search
                final filteredExercises = allExercises.where((e) {
                  return e.name.toLowerCase().contains(_searchQuery);
                }).toList();

                // Sort alphabetically
                filteredExercises.sort((a, b) => a.name.compareTo(b.name));

                if (filteredExercises.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? "Library is empty.\nAdd exercises in your routines!"
                          : "No exercises match '$_searchQuery'",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredExercises.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, index) {
                    final exercise = filteredExercises[index];
                    final historyCount = _getHistoryCount(exercise.id);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1C1C1E),
                        child: Text(
                          exercise.name.isNotEmpty
                              ? exercise.name.substring(0, 1).toUpperCase()
                              : "?",
                          style: const TextStyle(
                            color: Color(0xFF39FF14),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        getLocalizedExerciseName(context, exercise.name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        AppLocalizations.of(context)?.totalSetsPerformed(historyCount) ?? "Total Sets Performed: $historyCount",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        color: const Color(0xFF2C2C2E),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditDialog(exercise);
                          } else if (value == 'delete') {
                            _showDeleteConfirmation(exercise);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.edit,
                                  color: Color(0xFF39FF14),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppLocalizations.of(context)?.renameLabel ?? "Rename",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete_forever,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  AppLocalizations.of(context)?.deleteLabel ?? "Delete",
                                  style: const TextStyle(color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // FAB for adding new exercise
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF39FF14),
        foregroundColor: Colors.black,
        onPressed: _showAddExerciseDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Add new exercise dialog
  void _showAddExerciseDialog() {
    final nameController = TextEditingController();
    final setsController = TextEditingController(text: "3");
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: Text(
            AppLocalizations.of(context)?.addExerciseBtn ?? "Add New Exercise",
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: const Color(0xFF39FF14),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.exerciseNameLabel ?? "Exercise Name",
                    hintText: AppLocalizations.of(context)?.egBenchPress ?? "e.g. Bench Press",
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF39FF14)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: setsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: const Color(0xFF39FF14),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.targetSetsLabel ?? "Target Sets",
                    hintText: "3",
                    labelStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF39FF14)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: const Color(0xFF39FF14),
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.setupNoteOptionalLabel ?? "Setup Note (Optional)",
                    hintText: AppLocalizations.of(context)?.egSeatPin ?? "e.g. Seat 4, Pin 3",
                    labelStyle: const TextStyle(color: Colors.grey),
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
              child: Text(AppLocalizations.of(context)?.cancelBtn ?? "Cancel", style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter an exercise name"),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                // Check if exercise already exists
                final existingId = _db.findExerciseIdByName(name);
                if (existingId != null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("'$name' already exists"),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  return;
                }

                // Create new exercise
                final newExercise = Exercise(
                  id: const Uuid().v4(),
                  name: name,
                  targetSets: int.tryParse(setsController.text) ?? 3,
                  setupNote: noteController.text.trim().isNotEmpty
                      ? noteController.text.trim()
                      : null,
                );
                await _db.saveExercise(newExercise);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("'$name' added to library!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14),
                foregroundColor: Colors.black,
              ),
              child: Text(AppLocalizations.of(context)?.addExerciseBtn ?? "Add"),
            ),
          ],
        );
      },
    );
  }

  int _getHistoryCount(String exerciseId) {
    // Count total sets performed for this exercise
    try {
      final history = _db.getExerciseHistory(exerciseId);
      int totalSets = 0;
      for (final entry in history) {
        // entry is Map<String, dynamic> with 'sets' as a List
        final sets = entry['sets'] as List?;
        if (sets != null) {
          totalSets += sets.length;
        }
      }
      return totalSets;
    } catch (e) {
      return 0;
    }
  }

  void _showEditDialog(Exercise exercise) {
    final controller = TextEditingController(text: exercise.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: Text(
            AppLocalizations.of(context)?.renameExercise ?? "Rename Exercise",
            style: const TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            cursorColor: const Color(0xFF39FF14),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)?.newName ?? "New Name",
              labelStyle: const TextStyle(color: Colors.grey),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF39FF14)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)?.cancelBtn ?? "Cancel", style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty && newName != exercise.name) {
                  // Update the exercise
                  final updatedExercise = Exercise(
                    id: exercise.id,
                    name: newName,
                    targetSets: exercise.targetSets,
                    setupNote: exercise.setupNote,
                    imagePath: exercise.imagePath,
                  );
                  await _db.saveExercise(updatedExercise);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Renamed to '$newName'"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF39FF14),
                foregroundColor: Colors.black,
              ),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)?.deleteExercise ?? "Delete Exercise?",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          content: Text(
            AppLocalizations.of(context)?.deleteExerciseMsg(exercise.name) ?? "What would you like to delete for '${exercise.name}'?",
            style: TextStyle(color: Colors.grey[400], height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)?.cancelBtn ?? "Cancel", style: const TextStyle(color: Colors.grey)),
            ),
            // Option 1: Delete Exercise Only (Keep History)
            OutlinedButton(
              onPressed: () async {
                await _deleteExerciseOnly(exercise);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "'${exercise.name}' removed (history kept)",
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
              ),
              child: Text(
                AppLocalizations.of(context)?.hideFromList ?? "Hide from List (Keep History)",
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
            ),
            // Option 2: Delete Everything
            ElevatedButton(
              onPressed: () async {
                await _deleteExerciseCompletely(exercise);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "'${exercise.name}' and all history deleted",
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: Text(
                AppLocalizations.of(context)?.permanentlyDelete ?? "Permanently Delete (Wipe History)",
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  // Delete exercise from library only (keep workout history)
  Future<void> _deleteExerciseOnly(Exercise exercise) async {
    // 1. Remove from all Routines
    final routines = _db.getRoutines();
    for (final routine in routines) {
      if (routine.exerciseIds.contains(exercise.id)) {
        routine.exerciseIds.remove(exercise.id);
        await routine.save();
      }
    }

    // 2. Delete the exercise object only (history preserved in sessions)
    final exerciseBox = Hive.box<Exercise>('exercises');
    await exerciseBox.delete(exercise.id);

    // UI will auto-refresh via ValueListenableBuilder
  }

  // Delete exercise AND all associated workout history (deep delete)
  Future<void> _deleteExerciseCompletely(Exercise exercise) async {
    // 1. Remove from all Routines
    final routines = _db.getRoutines();
    for (final routine in routines) {
      if (routine.exerciseIds.contains(exercise.id)) {
        routine.exerciseIds.remove(exercise.id);
        await routine.save();
      }
    }

    // 2. Delete all workout history for this exercise
    await _db.deleteExerciseHistory(exercise.name);

    // 3. Delete the exercise itself
    final exerciseBox = Hive.box<Exercise>('exercises');
    await exerciseBox.delete(exercise.id);

    // UI will auto-refresh via ValueListenableBuilder
  }
}
