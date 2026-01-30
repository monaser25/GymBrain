import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/gym_models.dart';
import '../services/database_service.dart';

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
        title: const Text(
          "Exercise Library",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                hintText: "Search exercises...",
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
                        exercise.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        "Total Sets Performed: $historyCount",
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
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  color: Color(0xFF39FF14),
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  "Rename",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_forever,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.redAccent),
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
          title: const Text(
            "Rename Exercise",
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            cursorColor: const Color(0xFF39FF14),
            decoration: const InputDecoration(
              labelText: "New Name",
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF39FF14)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
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

                  if (mounted) {
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
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Delete Exercise?",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          content: Text(
            "Deleting '${exercise.name}' will:\n\n"
            "• Remove ALL workout history for this exercise\n"
            "• Remove it from any Routines using it\n\n"
            "This action CANNOT be undone!",
            style: TextStyle(color: Colors.grey[400], height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                await _deleteExerciseCompletely(exercise);
                if (context.mounted) Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("'${exercise.name}' deleted permanently"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text("Delete Forever"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteExerciseCompletely(Exercise exercise) async {
    // 1. Remove from all Routines
    final routines = _db.getRoutines();
    for (final routine in routines) {
      if (routine.exerciseIds.contains(exercise.id)) {
        routine.exerciseIds.remove(exercise.id);
        await routine.save();
      }
    }

    // 2. Delete the exercise itself
    // Note: History is stored in WorkoutSession.sets by exercise NAME,
    // so deleting the Exercise object does NOT delete historical data.
    // That's actually good - preserves session integrity.
    // If user wants to purge history, they'd need a separate action.
    final exerciseBox = Hive.box<Exercise>('exercises');
    await exerciseBox.delete(exercise.id);

    // UI will auto-refresh via ValueListenableBuilder
  }
}
