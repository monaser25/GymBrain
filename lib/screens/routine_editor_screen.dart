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
          // Listen to Exercise Box to update UI when exercise name/details change
          body: ValueListenableBuilder<Box<Exercise>>(
            valueListenable: _db.exerciseListenable,
            builder: (context, exerciseBox, _) {
              return _buildExerciseList(routine);
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showExerciseDialog(
              context,
              routine,
            ).then((_) => setState(() {})),
            label: const Text("Add Exercise"),
            icon: const Icon(Icons.add),
            backgroundColor: const Color(0xFF39FF14),
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
          color: const Color(0xFF1C1C1E),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
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

  // --- ADD / EDIT DIALOG (With Library) ---
  Future<void> _showExerciseDialog(
    BuildContext context,
    Routine routine, {
    Exercise? existingExercise,
  }) async {
    final isEditing = existingExercise != null;
    final libraryNames = _db.getUniqueExerciseNames();

    // Controllers
    final nameController = TextEditingController(
      text: existingExercise?.name ?? "",
    );
    final setupController = TextEditingController(
      text: existingExercise?.setupNote ?? "",
    );
    final targetSetsController = TextEditingController(
      text: existingExercise?.targetSets.toString() ?? "3",
    );

    // Selected from Library
    String? selectedLibraryName;

    return showDialog(
      context: context,
      builder: (context) {
        // Use StatefulBuilder here so we can rebuild the Checkmarks in Library Tab
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return DefaultTabController(
              length: isEditing ? 1 : 2,
              child: AlertDialog(
                backgroundColor: const Color(0xFF1C1C1E),
                title: isEditing
                    ? const Text(
                        "Edit Exercise",
                        style: TextStyle(color: Colors.white),
                      )
                    : const TabBar(
                        indicatorColor: Color(0xFF39FF14),
                        labelColor: Color(0xFF39FF14),
                        unselectedLabelColor: Colors.grey,
                        tabs: [
                          Tab(text: "New"),
                          Tab(text: "Library"),
                        ],
                      ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: TabBarView(
                    physics: isEditing
                        ? const NeverScrollableScrollPhysics()
                        : null,
                    children: [
                      // TAB 1: NEW / EDIT FORM
                      SingleChildScrollView(
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
                                  borderSide: BorderSide(
                                    color: Color(0xFF39FF14),
                                  ),
                                ),
                              ),
                              autofocus: !isEditing,
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
                                  borderSide: BorderSide(
                                    color: Color(0xFF39FF14),
                                  ),
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
                                  borderSide: BorderSide(
                                    color: Color(0xFF39FF14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // TAB 2: LIBRARY
                      if (!isEditing)
                        libraryNames.isEmpty
                            ? const Center(
                                child: Text(
                                  "Library is empty.",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: libraryNames.length,
                                separatorBuilder: (_, __) => const Divider(
                                  height: 1,
                                  color: Colors.white10,
                                ),
                                itemBuilder: (context, index) {
                                  final name = libraryNames[index];
                                  final isSelected =
                                      selectedLibraryName == name;
                                  return ListTile(
                                    title: Text(
                                      name,
                                      style: TextStyle(
                                        color: isSelected
                                            ? const Color(0xFF39FF14)
                                            : Colors.white,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    trailing: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Color(0xFF39FF14),
                                          )
                                        : null,
                                    onTap: () {
                                      setDialogState(() {
                                        selectedLibraryName = name;
                                      });
                                    },
                                  );
                                },
                              )
                      else
                        const SizedBox(),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Determine Mode
                      final tabIndex = DefaultTabController.of(context).index;
                      final isLibraryTab = !isEditing && tabIndex == 1;

                      String finalName = "";
                      int finalTargetSets = 3;
                      String? finalSetup;

                      if (isLibraryTab) {
                        if (selectedLibraryName == null) return;
                        finalName = selectedLibraryName!;
                        finalTargetSets = 3;
                        finalSetup = null;
                      } else {
                        if (nameController.text.trim().isEmpty) return;
                        finalName = nameController.text.trim();
                        finalTargetSets =
                            int.tryParse(targetSetsController.text) ?? 3;
                        finalSetup = setupController.text.trim().isNotEmpty
                            ? setupController.text.trim()
                            : null;
                      }

                      if (isEditing && existingExercise != null) {
                        // EDIT MODE
                        final updatedExercise = Exercise(
                          id: existingExercise.id,
                          name: finalName,
                          targetSets: finalTargetSets,
                          setupNote: finalSetup,
                          imagePath: existingExercise.imagePath,
                        );
                        await _db.saveExercise(updatedExercise);
                      } else {
                        // ADD MODE - Check Duplicate
                        final existingId = _db.findExerciseIdByName(finalName);

                        if (existingId != null) {
                          // LINK EXISTING
                          if (!routine.exerciseIds.contains(existingId)) {
                            routine.exerciseIds.add(existingId);
                            await routine.save();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Linked existing '$finalName' to this routine!",
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "'$finalName' is already in this routine!",
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        } else {
                          // CREATE NEW
                          final newExercise = Exercise(
                            id: const Uuid().v4(),
                            name: finalName,
                            targetSets: finalTargetSets,
                            setupNote: finalSetup,
                          );
                          await _db.saveExercise(newExercise);
                          routine.exerciseIds.add(newExercise.id);
                          await routine.save();
                        }
                      }

                      // Force UI Refresh
                      setState(() {});

                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF39FF14),
                      foregroundColor: Colors.black,
                    ),
                    child: Text(isEditing ? "Save" : "Add"),
                  ),
                ],
              ),
            );
          },
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
